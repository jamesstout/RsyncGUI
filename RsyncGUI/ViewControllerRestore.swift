//
//  ViewControllerEdit.swift
//  RsyncGUIver30
//
//  Created by Thomas Evensen on 05/09/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation
import Cocoa

class ViewControllerRestore: NSViewController, SetConfigurations, SetDismisser, Index, Abort {

    @IBOutlet weak var localCatalog: NSTextField!
    @IBOutlet weak var offsiteCatalog: NSTextField!
    @IBOutlet weak var offsiteUsername: NSTextField!
    @IBOutlet weak var offsiteServer: NSTextField!
    @IBOutlet weak var backupID: NSTextField!
    @IBOutlet weak var sshport: NSTextField!
    @IBOutlet weak var working: NSProgressIndicator!
    @IBOutlet weak var gotit: NSTextField!

    @IBOutlet weak var transferredNumber: NSTextField!
    @IBOutlet weak var transferredNumberSizebytes: NSTextField!
    @IBOutlet weak var newfiles: NSTextField!
    @IBOutlet weak var deletefiles: NSTextField!
    @IBOutlet weak var totalNumber: NSTextField!
    @IBOutlet weak var totalDirs: NSTextField!
    @IBOutlet weak var totalNumberSizebytes: NSTextField!
    @IBOutlet weak var restoreprogress: NSProgressIndicator!
    @IBOutlet weak var restorebutton: NSButton!
    @IBOutlet weak var tmprestore: NSTextField!
    @IBOutlet weak var selecttmptorestore: NSButton!

    var outputprocess: OutputProcess?
    var estimationcompleted: Bool = false
    var restorecompleted: Bool = false
    weak var sendprocess: SendProcessreference?
    var diddissappear: Bool = false
    var abortandclose: Bool = true

    // Close and dismiss view
    @IBAction func close(_ sender: NSButton) {
        if self.abortandclose { self.abort() }
        self.dismissview(viewcontroller: self, vcontroller: .vctabmain)
    }

    @IBAction func dotmprestore(_ sender: NSButton) {
        guard self.tmprestore.stringValue.isEmpty == false else { return }
        self.restorebutton.isEnabled = false
        self.abortandclose = true
        if let index = self.index() {
            self.selecttmptorestore.isEnabled = false
            self.estimationcompleted = false
            self.gotit.textColor = .white
            self.gotit.stringValue = "Getting info, please wait..."
            self.working.startAnimation(nil)
            self.outputprocess = OutputProcess()
            self.sendprocess?.sendoutputprocessreference(outputprocess: self.outputprocess)
            switch self.selecttmptorestore.state {
            case .on:
                _ = RestoreTask(index: index, outputprocess: self.outputprocess, dryrun: true, tmprestore: true)
            case .off:
                _ = RestoreTask(index: index, outputprocess: self.outputprocess, dryrun: true, tmprestore: false)
            default:
                return
            }
        } else {
            self.gotit.stringValue = "Probably some rsync error..."
        }
    }

    @IBAction func restore(_ sender: NSButton) {
        let answer = Alerts.dialogOrCancel(question: "Do you REALLY want to start a RESTORE ?", text: "Cancel or Restore", dialog: "Restore")
        if answer {
            if let index = self.index() {
                self.gotit.textColor = .white
                self.gotit.stringValue = "Executing restore..."
                self.restorebutton.isEnabled = false
                self.abortandclose = true
                self.initiateProgressbar()
                self.outputprocess = OutputProcess()
                self.sendprocess?.sendoutputprocessreference(outputprocess: self.outputprocess)
                switch self.selecttmptorestore.state {
                case .on:
                    _ = RestoreTask(index: index, outputprocess: self.outputprocess, dryrun: false, tmprestore: true)
                case .off:
                    _ = RestoreTask(index: index, outputprocess: self.outputprocess, dryrun: false, tmprestore: false)
                default:
                    return
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ViewControllerReference.shared.setvcref(viewcontroller: .vcrestore, nsviewcontroller: self)
        self.sendprocess = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllertabMain
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        guard self.diddissappear == false else { return }
        self.restorebutton.isEnabled = false
        self.localCatalog.stringValue = ""
        self.offsiteCatalog.stringValue = ""
        self.offsiteUsername.stringValue = ""
        self.offsiteServer.stringValue = ""
        self.backupID.stringValue = ""
        self.sshport.stringValue = ""
        self.restoreprogress.isHidden = true
        if let index = self.index() {
            let config: Configuration = self.configurations!.getConfigurations()[index]
            self.localCatalog.stringValue = config.localCatalog
            self.offsiteCatalog.stringValue = config.offsiteCatalog
            self.offsiteUsername.stringValue = config.offsiteUsername
            self.offsiteServer.stringValue = config.offsiteServer
            self.backupID.stringValue = config.backupID
            if let port = config.sshport {
                self.sshport.stringValue = String(port)
            }
            self.tmprestore.stringValue = ViewControllerReference.shared.restorePath ?? " ... set in User configuration ..."
            if ViewControllerReference.shared.restorePath == nil {
                self.selecttmptorestore.isEnabled = false
            }
            self.working.startAnimation(nil)
            self.outputprocess = OutputProcess()
            self.sendprocess?.sendoutputprocessreference(outputprocess: self.outputprocess)
            if ViewControllerReference.shared.restorePath != nil {
                self.selecttmptorestore.state = .on
                _ = RestoreTask(index: index, outputprocess: self.outputprocess, dryrun: true, tmprestore: true)
            } else {
                self.selecttmptorestore.state = .off
                _ = RestoreTask(index: index, outputprocess: self.outputprocess, dryrun: true, tmprestore: false)
            }
        }
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.diddissappear = true
    }

    private func setNumbers(outputprocess: OutputProcess?) {
        globalMainQueue.async(execute: { () -> Void in
            let infotask = RemoteInfoTask(outputprocess: outputprocess)
            self.transferredNumber.stringValue = infotask.transferredNumber!
            self.transferredNumberSizebytes.stringValue = infotask.transferredNumberSizebytes!
            self.totalNumber.stringValue = infotask.totalNumber!
            self.totalNumberSizebytes.stringValue = infotask.totalNumberSizebytes!
            self.totalDirs.stringValue = infotask.totalDirs!
            self.newfiles.stringValue = infotask.newfiles!
            self.deletefiles.stringValue = infotask.deletefiles!
            self.working.stopAnimation(nil)
            self.restorebutton.isEnabled = true
            self.gotit.textColor = .green
            self.gotit.stringValue = "Got it..."
        })
    }

    // Progressbar restore
    private func initiateProgressbar() {
        self.restoreprogress.isHidden = false
        if let calculatedNumberOfFiles = self.outputprocess?.getMaxcount() {
            self.restoreprogress.maxValue = Double(calculatedNumberOfFiles)
        }
        self.restoreprogress.minValue = 0
        self.restoreprogress.doubleValue = 0
        self.restoreprogress.startAnimation(self)
    }

    private func updateProgressbar(_ value: Double) {
        self.restoreprogress.doubleValue = value
    }

}

extension ViewControllerRestore: UpdateProgress {
    func processTermination() {
        self.abortandclose = false
        if self.estimationcompleted == false {
            self.estimationcompleted = true
            self.setNumbers(outputprocess: self.outputprocess)
            guard ViewControllerReference.shared.restorePath != nil else { return }
            self.selecttmptorestore.isEnabled = true
        } else {
            self.gotit.textColor = .green
            self.gotit.stringValue = "Restore is completed..."
            self.restoreprogress.isHidden = true
            self.restorecompleted = true
        }
    }

    func fileHandler() {
        if self.estimationcompleted == true {
             self.updateProgressbar(Double(self.outputprocess!.count()))
        }
    }
}
