// if you checked "fancy-settings" in extensionizr.com, uncomment this lines

// var settings = new Store("settings", {
//     "sample_setting": "This is how you use Store.js to remember values"
// });

const CBI_URL = "https://portal2.community-boating.org/pls/apex/CBI_PROD.FLAG_JS";
const SUNSET_API = "https://api.sunrise-sunset.org/json?lat=42.3599&lng=-71.0730&date=today"

const ICON_PATH = "icons"
const ICON_SIZE = 20;

const STR_CLOSED = '"C"';
const STR_GREEN = '"G"';
const STR_YELLOW = '"Y"';
const STR_RED = '"R"';

const IMG_CLOSED = 'burgee';
const IMG_GREEN = 'green';
const IMG_YELLOW = 'yellow';
const IMG_RED = 'red';

const FETCH_INTERVAL = 1000 * 60 * 10; // (ms) * (sec/min) * (q10min)

const HTTP_OK = 200;

var CBI_IS_OPEN = true;

var SUNSET_TIME = "";
var SUNSET_DATE = null;
var SUNSET_UPDATE_INTERVAL = 1000 * 60 * 60; // QH


function set_flag(color) {
    var icon = ICON_PATH + "/" + color + "-" + String(ICON_SIZE) + ".png";
    chrome.browserAction.setIcon({
	path: icon
    });
}

function get_flag_color() {
    var request = new XMLHttpRequest();
    request.open('GET', CBI_URL, true);

    request.onreadystatechange = function() {
	if (request.readyState == XMLHttpRequest.DONE) {
	    if (request.status == HTTP_OK) {
		var text = request.responseText;
		var color = IMG_CLOSED;
		
		switch (true) {
		case (text.indexOf(STR_GREEN) > 0):
		    color = IMG_GREEN;
		    break;
		    
		case (text.indexOf(STR_YELLOW) > 0):
		    color = IMG_YELLOW;
		    break;
		    
		case (text.indexOf(STR_RED) > 0):
		    color = IMG_RED;
		    break;
		    
		case (text.indexOf(STR_CLOSED) > 0):
		default:
		    color = IMG_CLOSED;
		    break;		    
		}
		
		set_flag(color);

	    } else {
		console.warn("Got status code: " + String(request.status));
		console.warn(request.responseText);
	    }
	}
    };
    
    request.send();
    return null;
}

// Returns "HH:mm"
function get_sunset_time(callback) {
    var request = new XMLHttpRequest();
    request.open('GET', SUNSET_API, true);
    request.onreadystatechange = function() {
	if (request.readyState == XMLHttpRequest.DONE) {
	    if (request.status == HTTP_OK) {
		console.log(request.responseText);
		callback(request.responseCode, request.responseText);
	    }
	}
    };
    request.send();
}

function update_sunset_time() {
    // If sunset info is from today, don't bother updating
    var d = new Date();
    if (SUNSET_DATE != null && SUNSET_DATE.getDate() == d.getDate()) {
	return false;
    }
    // otherwise, refresh with today's sunset time
    get_sunset_time(function(code, text) {
	var now = new Date();
	var results = JSON.parse(text).results;
	var date_str = "" + [now.getMonth()+1, now.getDate(), now.getFullYear()].join('/');
	var sunset_str = "" + date_str + " " + results.sunset + " UTC";
	var sunset = new Date(sunset_str);

	sunset_time = [sunset.getHours(), sunset.getMinutes()].join(':');

	SUNSET_TIME = sunset_time;
	SUNSET_DATE = sunset;

	chrome.browserAction.setTitle({
	    'title': "Sunset @ " + SUNSET_TIME
	});
    });
}

function cbi_is_open() {
    var now = new Date();
    var time_now = "" + now.getHours() + ":" + now.getMinutes();
    var open_time = "13:00";
    var close_time = SUNSET_TIME;
    if (SUNSET_TIME == "" || SUNSET_DATE == null) {
	// After refreshing, the setTimeout(update_sunset_time) won't fire
	// so fetch sunset info (async), and return true, so it checks the
	// CBI page
	update_sunset_time();
	return true;
    }
    console.debug("Open: " + open_time + "    Close: " + close_time + "    Now: " + time_now);
    return (time_now > open_time && time_now < close_time);
}

function update() {
    if (cbi_is_open()) {
	return get_flag_color();
    }
    return set_flag(IMG_CLOSED);
}

// init
(function() {
    var updateInterval = setInterval(update, FETCH_INTERVAL);
    var sunsetInterval = setInterval(update_sunset_time, SUNSET_UPDATE_INTERVAL);

    update_sunset_time();
    update();
})();


