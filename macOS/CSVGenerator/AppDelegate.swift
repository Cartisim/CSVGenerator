//
//  AppDelegate.swift
//  CSVCreator
//
//  Created by Cole M on 9/14/20.
//  Copyright © 2020 Cole M. All rights reserved.
//

import Cocoa
import NIO

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var store: SQLiteStore?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let masterWindowController = MasterWindowController()
        masterWindowController.showWindow(nil)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
}

