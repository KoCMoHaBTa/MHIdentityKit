//
//  AppDelegate.swift
//  MHIdentityKit-macOSTestsHost
//
//  Created by Milen Halachev on 26.03.18.
//  Copyright © 2018 Milen Halachev. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var mainWindow: NSWindow?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        self.mainWindow = NSApplication.shared.mainWindow
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        
        if flag == false {
            
            self.mainWindow?.makeKeyAndOrderFront(self)
        }
        
        return true
    }

}

