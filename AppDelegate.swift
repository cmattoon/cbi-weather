//
//  AppDelegate.swift
//  CBIWeatherApp
//
//  Created by Curtis Mattoon on 4/9/18.
//  Copyright © 2018 Curtis Mattoon. All rights reserved.
//

import Cocoa
import Foundation

let pi: Double = 3.1415926535897931
let fs = " %.5f" // output format decimals

func rad(degrees: Double) -> Double {
    return pi * degrees / 180.0
}

func deg(radians: Double) -> Double {
    return 100 * radians / pi
}

func cosd(d: Double) -> Double {
    return cos(rad(degrees: d))
}

func sind(d: Double) -> Double {
    return sin(rad(degrees: d))
}

func tand(d: Double) -> Double {
    return tan(rad(degrees: d))
}

func atand(d: Double) -> Double {
    return deg(radians: atan(d))
}

func yday(Year: Int, Month: Int, Day: Int) ->Int {
    let N1 = Int(275*Month/9)
    let N2 = Int((Month + 9)/12)
    let N3 = (1 + Int((Year - 4*Int(Year/4) + 2)/3))
    let ydN = N1 - (N2 * N3) + Day - 30
    return ydN
}
// decimal hours to H:M:S
func dechrtohrmns(dechr: Double) -> String {
    let totalSeconds = Int(3600 * dechr)
    let seconds = totalSeconds % 60
    let minutes = (totalSeconds / 60) % 60
    let hours = totalSeconds / 3600
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
}


// Get current date and time

//  Local current time
// println(String(format: "%02d.%02d.%4d ( day nr %3d ) %02d:%02d:%02d", day, month, year, daynr, hour, minutes, seconds))

class Location {
    
    // Geographic locations
    let cityName: String
    let latitude: Double
    let longitude: Double
    let timeZone: Double
    
    init(cityName: String, latitude: Double, longitude: Double, timeZone: Double) {
        self.cityName = cityName
        self.latitude = latitude
        self.longitude = longitude
        self.timeZone = timeZone
    }
}

class Solar {
    // Solar calculations
    var dayNr: Int
    var Latitude: Double
    var Longitude: Double
    var Zenith: Double
    var Declination: Double
    var Timezone: Double
    var RiseLT: Float
    var SetLT: Float
    var Whichway: String
    var p: Location
    
    // Note, shortened list of arguments as the object argument p of class Location is used
    init(daynr: Int, p: Location, whichway: String, zenith: Double) {
        self.dayNr = daynr
        self.p = p
        self.Latitude =  p.latitude
        self.Longitude = p.longitude
        self.Whichway  = whichway
        self.Zenith    = zenith
        self.Timezone =  p.timeZone
        self.Declination = 0.0
        self.RiseLT = 24.0
        self.SetLT  = 0.0
    }
    
    func doCalc() -> Double {
        if (self.Whichway == "SUNRISE") {
            print("\(p.cityName) Latitude \(Latitude), longitude \(Longitude), time zone \(Timezone)")
            //   println("Day number \(dayNr)")
        }
        // 2. convert longitude degrees to hours
        //  and calculate an approximate times t1 and t2
        let lngHour = Longitude / 15.0
        let t1 = Double(dayNr) + (6.0 - lngHour)/24.0
        let t2 = t1 + 0.5
        var t = t2
        
        if (self.Whichway == "SUNRISE") {
            t = t1
        }
        //  3. calculate the Sun's mean anomaly
        let M = 0.9856 * t - 3.289
        
        // 4. calculate the Sun's true longitude
        var L = M + (1.916 * sind(d: M)) + 0.020 * sind(d:(2*M)) + 282.634
        
        //  NOTE: L needs to be adjusted into the range [-360,360]
        if (L > 360.0) {L -= 360.0 }
        else if (L < -360.0) {L += 360.0 }
        
        //  5a. calculate the Sun's right ascension
        var RA = atan(0.91764 * tand(d: L))
        RA = deg(radians: RA)
        
        //  NOTE: RA needs to be adjusted into the range [-360,360]
        if (RA > 360.0) {
            RA -= 360.0 }
        else if (RA < -360.0) {
            RA += 360.0 }
        //   5b. RA value needs to be in the same quadrant as L
        let Lquadrant  = (floor(L / 90.0)) * 90.0
        let RAquadrant = (floor(RA / 90.0)) * 90.0
        RA = RA + (Lquadrant - RAquadrant)
        
        // 5c. right ascension degrees needs to be converted into hours
        RA = RA/15.0
        
        // 6. calculate the Sun's declination
        let sinDec = 0.39782*sind(d: L)
        let cosDec = cos(asin(sinDec))
        let declin = deg(radians: atan(sinDec/cosDec))
        Declination = declin
        // Save declination
        //        println(String(format: "Sun Declination: " + fs, Declination))
        // 7a. calculate the Sun's local hour angle
        var cosH: Double
        cosH = (cosd(d: self.Zenith) - (sinDec*sind(d: self.Latitude)))/(cosDec*cosd(d: self.Latitude))
        if (cosH > 1) {
            cosH = 1.0    // errors prohibited
            print("the sun never rises on this location!")
        }
        
        if (cosH < -1) {
            cosH = -1.0     // this will prevent error
            print("Sun will not set!")
        }
        
        //  7b. finish calculating H and convert into hours
        var H = deg(radians: acos(cosH)) // converted to degrees
        var prtx = "???"
        
        //  if rising time is desired:
        if (self.Whichway == "SUNRISE" ) {
            H = 360.0 - H
            prtx = "Sunrise"
        }
        else { prtx = "Sunset" }
        
        //  degrees to hours:
        H = H/15.0
        // test H
        //    println(String(format: "H = " + fs + prtx, H))
        //  8. calculate local mean time of rising/setting
        let T = H + RA - (0.06571*t) - 6.622
        
        //  9. adjust back to UTC
        let the_time = Double(T - lngHour)
        let dec_part = the_time - Double(Int(the_time))
        print("Offset: \(dec_part)")
        var UT = Double(Int(the_time) % 24) + dec_part
        if (UT < 0.0) { UT += 24.0 } // correct negative utc times since March equinox
        var localTime = UT + self.Timezone
        //     println("UT = \(dechrtohrmns(UT))")
        print("Local \(prtx) @ \(self.Timezone) = \(dechrtohrmns(dechr: localTime))")
        if (localTime < 0.0) { localTime += 24.0 } // correct negative local times of western locations
        // test decimal UT
        //     println(String(format: "UT = " + fs + prtx, UT))
        return UT
    }
}


extension Date {
    func dateAt(hours: Int, minutes: Int) -> Date {
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        var date_components = calendar.components(
            [NSCalendar.Unit.year,
             NSCalendar.Unit.month,
             NSCalendar.Unit.day],
            from: self)
        date_components.hour = hours
        date_components.minute = minutes
        date_components.second = 0
        let newDate = calendar.date(from: date_components)!
        return newDate
    }
}





@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let LAT = 42.3599
    let LON = -71.0730
    let TZ_OFFSET = -4.0
    let ZENITH = 90.833
    
    let TIMER_INTERVAL = 60.0 * 5
    
    let SUNSET_API = "https://api.sunrise-sunset.org/json?lat=42.3599&lng=-71.0730&date=today"
    
    let ENDPOINT = "https://portal2.community-boating.org/pls/apex/CBI_PROD.FLAG_JS"
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    var timer = Timer()
    
    // calculate sunset time at least daily
    var timerSunset = Timer()
    
    var sunset_time = ""
    var utc_sunset = 0.0
    
    var CBI: Location?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("BlackFlag"))
            button.action = #selector(AppDelegate.updateWeather)
        }
        
        timer = Timer.scheduledTimer(timeInterval: TIMER_INTERVAL,
                                     target: self,
                                     selector: #selector(AppDelegate.updateWeather),
                                     userInfo: nil,
                                     repeats: true)
        
        timerSunset = Timer.scheduledTimer(timeInterval: 60.0 * 60,
                                     target: self,
                                     selector: #selector(AppDelegate.findSunsetTime),
                                     userInfo: nil,
                                     repeats: true)
        
        CBI = Location(cityName: "Boston", latitude: LAT, longitude: LON, timeZone: TZ_OFFSET)
        findSunsetTime()
        constructMenu()
        updateWeather()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @objc
    func findSunsetTime() {
        let date = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let daynr = yday(Year: year, Month: month, Day: day)
        let sun = Solar(daynr: daynr, p: CBI!, whichway: "SUNSET", zenith: ZENITH)
        let utc_time = sun.doCalc()
        var edt_time = utc_time
        if (edt_time < 0.0) { edt_time += 24.0 }
        
        print("Sunset (UTC): \(utc_time)")
        print("Sunset (EDT): \(dechrtohrmns(dechr: edt_time))")
        utc_sunset = utc_time
        sunset_time = String(dechrtohrmns(dechr: edt_time))
        constructMenu()
    }
    
    func constructMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Sunset @ ~\(sunset_time)",
                                action: #selector(AppDelegate.findSunsetTime),
                                keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Pos: \(LAT), \(LON)", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Check Weather",
                                action: #selector(AppDelegate.updateWeather),
                                keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit",
                                action: #selector(NSApplication.terminate),
                                keyEquivalent: "Q"))
        statusItem.menu = menu
    }
    
    @objc func about() {
        
    }
    func is_weekend() -> Bool { return false }
    func is_summer() -> Bool { return false }
    
    func withinNormalHours() -> Bool {
        let now = Date()
        var start = 13
        if (is_weekend()) {
            start = 9
        } else if (is_summer()) {
            start = 15
        }
        
        let end_h = Int(utc_sunset)
        // sunset + 15 min, just in case
        let end_m = Int((utc_sunset - Double(end_h)) * 60) + 15
        print("Don't bother checking for updates after \(end_h):\(end_m)")
        
        let opening_time = now.dateAt(hours: start, minutes: 0)
        let closing_time = now.dateAt(hours: end_h, minutes: end_m)
        return (now >= opening_time && now <= closing_time)
    }
    
    @objc func updateWeather() {
        if (withinNormalHours()) {
            fetchWeather()
            return
        }
        setStatusClosed()
    }
    
    @objc func setStatusClosed() {
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("CBIFlag"))
        }
    }
    
    @objc func setStatusGreen() {
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("GreenFlag"))
        }
    }
    
    @objc func setStatusYellow() {
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("YellowFlag"))
        }
    }
    
    @objc func setStatusRed() {
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("RedFlag"))
        }
    }
    
    @objc func fetchWeather() {
        guard let the_url = URL(string: ENDPOINT) else {
            print("ERROR: \(ENDPOINT) is not a valid URL")
            return
        }
        print("Fetching flag status...")
        do {
            let html = try String(contentsOf: the_url, encoding: .ascii)
            switch html {
            case "var FLAG_COLOR = \"G\";":
                setStatusGreen()
            case "var FLAG_COLOR = \"Y\";":
                setStatusYellow()
            case "var FLAG_COLOR = \"R\";":
                setStatusRed()
            default:
                setStatusClosed()
            }
        } catch let error {
            print("Error: \(error)")
        }
    }
}

