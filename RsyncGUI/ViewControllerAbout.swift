//
//  ViewControllerAbout.swift
//  RsyncGUI
//
//  Created by Thomas Evensen on 18/11/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//

import Cocoa
import Foundation

class ViewControllerAbout: NSViewController, SetDismisser, Delay {
    @IBOutlet var version: NSTextField!
    @IBOutlet var rsyncversionstring: NSTextField!
    @IBOutlet var copyright: NSTextField!
    @IBOutlet var iconby: NSTextField!
    @IBOutlet var configpath: NSTextField!

    var copyrigthstring: String = "Copyright ©2019 Thomas Evensen"
    var iconbystring: String = "Icon by: Zsolt Sándor"

    private var resource: Resources?
    var outputprocess: OutputProcess?

    @IBAction func changelog(_: NSButton) {
        if let resource = self.resource {
            NSWorkspace.shared.open(URL(string: resource.getResource(resource: .changelog))!)
        }
        self.dismissview(viewcontroller: self, vcontroller: .vctabmain)
    }

    @IBAction func documentation(_: NSButton) {
        if let resource = self.resource {
            NSWorkspace.shared.open(URL(string: resource.getResource(resource: .documents))!)
        }
        self.dismissview(viewcontroller: self, vcontroller: .vctabmain)
    }

    @IBAction func introduction(_: NSButton) {
        if let resource = self.resource {
            NSWorkspace.shared.open(URL(string: resource.getResource(resource: .introduction))!)
        }
        self.dismissview(viewcontroller: self, vcontroller: .vctabmain)
    }

    @IBAction func download(_: NSButton) {
        guard ViewControllerReference.shared.URLnewVersion != nil else {
            self.dismissview(viewcontroller: self, vcontroller: .vctabmain)
            return
        }
        NSWorkspace.shared.open(URL(string: ViewControllerReference.shared.URLnewVersion!)!)
        self.dismissview(viewcontroller: self, vcontroller: .vctabmain)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ViewControllerReference.shared.setvcref(viewcontroller: .vcabout, nsviewcontroller: self)
        self.copyright.stringValue = self.copyrigthstring
        self.iconby.stringValue = self.iconbystring
        self.resource = Resources()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        self.version.stringValue = "RsyncGUI ver: " + version
        self.rsyncversionstring.stringValue = ViewControllerReference.shared.rsyncversionstring ?? ""
        self.configpath.stringValue = NamesandPaths(profileorsshrootpath: .profileroot).fullroot ?? ""
    }
}
