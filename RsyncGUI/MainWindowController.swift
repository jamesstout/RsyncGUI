//
//  MainWindowsController.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 01/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Cocoa
import Foundation

class MainWindowsController: NSWindowController {
    /*
     private var viewcontrollersidebar: ViewControllerSideBar?
     private var tabviewcontroller: TabViewController?
     private var splitviewcontroller: NSSplitViewController? {
         guard let viewController = contentViewController else {
             return nil
         }
         return viewController.children.first as? NSSplitViewController
     }
     */
    func addtoolbar() {
        globalMainQueue.async { () -> Void in
            let toolbar = NSToolbar(identifier: "Toolbar")
            toolbar.allowsUserCustomization = false
            toolbar.autosavesConfiguration = false
            toolbar.displayMode = .iconOnly
            toolbar.delegate = self
            self.window?.toolbar = toolbar
        }
        window?.toolbar?.validateVisibleItems()
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        self.addtoolbar()
    }
}
