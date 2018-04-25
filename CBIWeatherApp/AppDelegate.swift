//
//  AppDelegate.swift
//  CBIWeatherApp
//
//  Created by Curtis Mattoon on 4/9/18.
//  Copyright © 2018 Curtis Mattoon. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let TIMER_INTERVAL = 60.0 * 5
    
    let ENDPOINT = "https://portal2.community-boating.org/pls/apex/CBI_PROD.FLAG_JS"
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    var timer = Timer()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("BlackFlag"))
            button.action = #selector(getWeather(_:))
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
    
    func withinNormalHours() -> Bool {
            return true
    }
    
    @objc func getWeather(_ sender: Any?) {
        if (withinNormalHours()) {
            updateWeather()
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
    @objc func updateWeather() {
        guard let the_url = URL(string: ENDPOINT) else {
            print("ERROR: \(ENDPOINT) is not a valid URL")
            return
        }
        
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
        let weatherText = "Weather!"
        print("\(weatherText)")
    }
    
    func constructMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Check Weather", action: #selector(AppDelegate.updateWeather), keyEquivalent: "U"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate), keyEquivalent: "Q"))
        statusItem.menu = menu
    }
}

