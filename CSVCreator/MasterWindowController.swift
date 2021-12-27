//
//  MasterWindowController.swift
//  CSVCreator
//
//  Created by Cole M on 12/25/21.
//  Copyright © 2021 Cole M. All rights reserved.
//

import Cocoa


class MasterWindowController: NSWindowController, NSWindowDelegate {

    
    convenience init() {
        self.init(windowNibName: "MasterWindowController")
    }
    
    deinit {
        debugPrint("Reclaiming memory from MasterWindowController")
        NotificationCenter.default.removeObserver(self)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.minSize = CGSize(width: 1152, height: 648)
        self.window?.center()
        setUpWindow()
    }

    func window(_ window: NSWindow, willUseFullScreenPresentationOptions proposedOptions: NSApplication.PresentationOptions = []) -> NSApplication.PresentationOptions {
        return [.autoHideToolbar, .autoHideMenuBar, .fullScreen]
    }
    
    fileprivate func setUpWindow() {
        window?.styleMask.insert(.fullSizeContentView)
        window?.titlebarAppearsTransparent = true
        window?.titleVisibility = .hidden
        window?.delegate = self
        window?.contentViewController = ViewController()
    }

    func windowWillMiniaturize(_ notification: Notification) {
        debugPrint("Reclaiming memory from MasterWindowController")
        NotificationCenter.default.removeObserver(self)
    }
    func windowWillClose(_ notification: Notification) {
        debugPrint("Reclaiming memory from MasterWindowController")
    }
}
