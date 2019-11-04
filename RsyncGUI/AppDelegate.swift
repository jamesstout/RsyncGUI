//
//  AppDelegate.swift
//  RsyncGUIver30
//
//  Created by Thomas Evensen on 18/08/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Read user configuration
        if let userconfiguration =  PersistentStorageUserconfiguration().readuserconfiguration() {
            _ = Userconfiguration(userconfigRsyncGUI: userconfiguration)
        } else {
            _ = RsyncVersionString()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

}
