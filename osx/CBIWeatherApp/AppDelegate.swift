//
//  AppDelegate.swift
//  CBIWeatherApp
//
//  Created by Curtis Mattoon on 4/9/18.
//  Copyright © 2018 Curtis Mattoon. All rights reserved.
//

import Cocoa
import Foundation

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
    let TIMER_INTERVAL = 60.0 * 5
    
    let SUNSET_API = "https://api.sunrise-sunset.org/json?lat=42.3599&lng=-71.0730&date=today"
    
    let ENDPOINT = "https://portal2.community-boating.org/pls/apex/CBI_PROD.FLAG_JS"
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    var timer = Timer()
    
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
        constructMenu()
        updateWeather()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func constructMenu() {
        let menu = NSMenu()
        let sunset_time = "XX:XX"
        menu.addItem(NSMenuItem(title: "Sunset Time \(sunset_time)",
                                action: nil,
                                keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Check Weather",
                                action: #selector(AppDelegate.updateWeather),
                                keyEquivalent: "U"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About",
                                action: #selector(AppDelegate.about),
                                keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit",
                                action: #selector(NSApplication.terminate),
                                keyEquivalent: "Q"))
        statusItem.menu = menu
    }
    
    @objc func about() {
        
    }
    
    func withinNormalHours() -> Bool {
        let now = Date()
        let opening_time = now.dateAt(hours: 13, minutes: 0)
        let closing_time = now.dateAt(hours: 21, minutes: 0)
        return (now >= opening_time && now <= closing_time)
    }
    
    @objc func updateWeather() {
        if (withinNormalHours()) {
            fetchWeather()
        } else {
            setStatusClosed()
        }
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

