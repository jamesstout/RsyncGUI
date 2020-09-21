//
//  ViewControllerRestore.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 12/09/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
//  swiftlint:disable line_length type_body_length file_length

import Cocoa
import Foundation

protocol GetSource: AnyObject {
    func getSourceindex(index: Int)
}

protocol Updateremotefilelist: AnyObject {
    func updateremotefilelist()
}

struct RestoreActions {
    // Restore to tmp restorepath selected and verified
    var tmprestorepathverified: Bool = false
    var tmprestorepathselected: Bool = true
    // Index for restore selected
    var index: Bool = false
    // Estimated
    var estimated: Bool = false
    // Type of restore
    var fullrestore: Bool = false
    var restorefiles: Bool = false
    // Remote file if restore files
    var remotefileverified: Bool = false
    // Do the real thing
    var executerealrestore: Bool = false

    init(closure: () -> Bool) {
        self.tmprestorepathverified = closure()
    }

    func goforfullrestoretotemporarypath() -> Bool {
        guard self.tmprestorepathverified, self.tmprestorepathselected, self.index, self.estimated, self.fullrestore else { return false }
        return true
    }

    func goforfullrestore() -> Bool {
        guard self.tmprestorepathselected == false, self.index, self.estimated, self.fullrestore else { return false }
        return true
    }

    func goforrestorefilestotemporarypath() -> Bool {
        guard self.tmprestorepathverified, self.tmprestorepathselected, self.index, self.estimated, self.restorefiles, self.remotefileverified else { return false }
        return true
    }

    func goforfullrestoreestimate() -> Bool {
        guard self.tmprestorepathselected == false, self.index, self.estimated == false, self.fullrestore else { return false }
        return true
    }

    func goforfullrestoreestimatetemporarypath() -> Bool {
        guard self.tmprestorepathverified, self.tmprestorepathselected, self.index, self.estimated == false, self.fullrestore else { return false }
        return true
    }

    func getfilelistrestorefiles() -> Bool {
        guard self.index, self.estimated == false, self.restorefiles else { return false }
        return true
    }

    func reset() -> Bool {
        var reset = false
        if self.goforfullrestore() == true {
            reset = true
        }
        if self.goforfullrestoretotemporarypath() == true {
            reset = true
        }
        if self.goforrestorefilestotemporarypath() == true {
            reset = true
        }
        return reset
    }
}

class ViewControllerRestore: NSViewController, SetConfigurations, Delay, Connected, VcMain, Checkforrsync, Setcolor, Help {
    var restorefilestask: RestorefilesTask?
    var fullrestoretask: FullrestoreTask?
    var remotefilelist: Remotefilelist?
    var index: Int?
    var restoretabledata: [String]?
    var diddissappear: Bool = false
    var outputprocess: OutputProcess?
    var maxcount: Int = 0
    weak var outputeverythingDelegate: ViewOutputDetails?

    var restoreactions: RestoreActions?

    @IBOutlet var restoretableView: NSTableView!
    @IBOutlet var rsynctableView: NSTableView!
    @IBOutlet var remotefiles: NSTextField!
    @IBOutlet var working: NSProgressIndicator!
    @IBOutlet var search: NSSearchField!
    @IBOutlet var fullrestoreradiobutton: NSButton!
    @IBOutlet var filesrestoreradiobutton: NSButton!
    @IBOutlet var tmprestorepath: NSTextField!
    @IBOutlet var selecttmptorestore: NSButton!
    @IBOutlet var profilepopupbutton: NSPopUpButton!
    @IBOutlet var restoreisverified: NSButton!
    @IBOutlet var dotherealthing: NSButton!
    @IBOutlet var infolabel: NSTextField!

    @IBAction func totinfo(_: NSButton) {
        guard self.checkforrsync() == false else { return }
        globalMainQueue.async { () -> Void in
            self.presentAsSheet(self.viewControllerRemoteInfo!)
        }
    }

    @IBAction func quickbackup(_: NSButton) {
        guard self.checkforrsync() == false else { return }
        self.openquickbackup()
    }

    @IBAction func automaticbackup(_: NSButton) {
        self.presentAsSheet(self.viewControllerEstimating!)
    }

    // Selecting profiles
    @IBAction func profiles(_: NSButton) {
        globalMainQueue.async { () -> Void in
            self.presentAsSheet(self.viewControllerProfile!)
        }
    }

    // Userconfiguration button
    @IBAction func userconfiguration(_: NSButton) {
        self.presentAsModalWindow(self.viewControllerUserconfiguration!)
    }

    // Abort button
    @IBAction func abort(_: NSButton) {
        self.working.stopAnimation(nil)
        _ = InterruptProcess()
        self.reset()
    }

    @IBAction func showHelp(_: AnyObject?) {
        self.help()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ViewControllerReference.shared.setvcref(viewcontroller: .vcrestore, nsviewcontroller: self)
        self.outputeverythingDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllerMain
        self.restoretableView.delegate = self
        self.restoretableView.dataSource = self
        self.rsynctableView.delegate = self
        self.rsynctableView.dataSource = self
        self.working.usesThreadedAnimation = true
        self.search.delegate = self
        self.tmprestorepath.delegate = self
        self.remotefiles.delegate = self
        self.restoretableView.doubleAction = #selector(self.tableViewDoubleClick(sender:))
        self.initpopupbutton()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        guard self.diddissappear == false else {
            globalMainQueue.async { () -> Void in
                self.rsynctableView.reloadData()
            }
            return
        }
        globalMainQueue.async { () -> Void in
            self.rsynctableView.reloadData()
        }
        self.reset()
        self.settmprestorepathfromuserconfig()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.diddissappear = true
    }

    func reset() {
        self.restoretabledata = nil
        self.restorefilestask = nil
        self.fullrestoretask = nil
        self.filesrestoreradiobutton.state = .off
        self.fullrestoreradiobutton.state = .off
        self.dotherealthing.state = .off
        // Restore state
        self.restoreactions = RestoreActions(closure: self.verifytmprestorepath)
        if self.index != nil {
            self.restoreactions?.index = true
        }
        self.restoreisverified.image = #imageLiteral(resourceName: "red")
        self.restoretabledata = nil
        globalMainQueue.async { () -> Void in
            self.restoretableView.reloadData()
        }
    }

    // Restore files
    func executerestorefiles() {
        guard self.restoreactions?.goforrestorefilestotemporarypath() ?? false else { return }
        guard (self.restoreactions?.executerealrestore ?? false) == true else {
            self.infolabel.isHidden = false
            self.infolabel.stringValue = NSLocalizedString("Simulated: execute restore of files to temporary restore path", comment: "Restore")
            return
        }
        globalMainQueue.async { () -> Void in
            self.presentAsSheet(self.viewControllerProgress!)
        }
        self.restorefilestask?.executecopyfiles(remotefile: self.remotefiles.stringValue, localCatalog: self.tmprestorepath.stringValue, dryrun: false)
        self.outputprocess = self.restorefilestask?.outputprocess
    }

    func prepareforfilesrestoreandandgetremotefilelist() {
        guard self.checkforgetremotefiles() else { return }
        if let index = self.index {
            self.infolabel.isHidden = true
            self.remotefiles.stringValue = ""
            let hiddenID = self.configurations?.getConfigurationsDataSourceSynchronize()?[index].value(forKey: "hiddenID") as? Int ?? -1
            self.restorefilestask = RestorefilesTask(hiddenID: hiddenID)
            self.remotefilelist = Remotefilelist(hiddenID: hiddenID)
            self.working.startAnimation(nil)
            self.restoreisverified.image = #imageLiteral(resourceName: "yellow")
        }
    }

    func checkforgetremotefiles() -> Bool {
        guard self.checkforrsync() == false else { return false }
        if let index = self.index {
            guard self.connected(config: self.configurations?.getConfigurations()[index]) == true else {
                self.infolabel.stringValue = Inforestore().info(num: 4)
                self.infolabel.isHidden = false
                return false
            }
            guard self.configurations!.getConfigurations()[index].task != ViewControllerReference.shared.syncremote else {
                self.infolabel.stringValue = Inforestore().info(num: 5)
                self.infolabel.isHidden = false
                self.restoretabledata = nil
                globalMainQueue.async { () -> Void in
                    self.restoretableView.reloadData()
                }
                return false
            }
            return true
        } else {
            return false
        }
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let myTableViewFromNotification = (notification.object as? NSTableView)!
        if myTableViewFromNotification == self.restoretableView {
            self.infolabel.isHidden = true
            let indexes = myTableViewFromNotification.selectedRowIndexes
            if let index = indexes.first {
                guard self.restoretabledata != nil else { return }
                self.remotefiles.stringValue = self.restoretabledata![index]
                guard self.remotefiles.stringValue.isEmpty == false else {
                    self.infolabel.stringValue = Inforestore().info(num: 3)
                    self.reset()
                    return
                }
                self.restoreactions?.index = true
                self.restoreactions?.remotefileverified = true
            }
        } else {
            let indexes = myTableViewFromNotification.selectedRowIndexes
            self.filesrestoreradiobutton.state = .off
            self.fullrestoreradiobutton.state = .off
            if let index = indexes.first {
                self.index = index
                self.restoretabledata = nil
                self.restoreactions?.index = true
                guard self.restoreactions?.reset() == false else {
                    self.reset()
                    return
                }
            } else {
                self.index = nil
                self.reset()
            }
            globalMainQueue.async { () -> Void in
                self.restoretableView.reloadData()
            }
        }
    }

    @IBAction func getremotefilelist(_: NSButton) {
        guard self.restoreactions?.getfilelistrestorefiles() ?? false else { return }
        self.prepareforfilesrestoreandandgetremotefilelist()
    }

    @IBAction func reset(_: NSButton) {
        self.reset()
    }

    @objc(tableViewDoubleClick:) func tableViewDoubleClick(sender _: AnyObject) {
        guard self.remotefiles.stringValue.isEmpty == false else { return }
        guard self.verifytmprestorepath() == true else { return }
        let question: String = NSLocalizedString("Copy single files or directory?", comment: "Restore")
        let text: String = NSLocalizedString("Start restore?", comment: "Restore")
        let dialog: String = NSLocalizedString("Restore", comment: "Restore")
        let answer = Alerts.dialogOrCancel(question: question, text: text, dialog: dialog)
        if answer {
            self.working.startAnimation(nil)
            self.restorefilestask?.executecopyfiles(remotefile: remotefiles?.stringValue ?? "", localCatalog: tmprestorepath?.stringValue ?? "", dryrun: false, updateprogress: self)
        }
    }

    private func checkforfullrestore() -> Bool {
        if let index = self.index {
            guard self.connected(config: self.configurations!.getConfigurations()[index]) == true else {
                self.infolabel.stringValue = Inforestore().info(num: 4)
                self.infolabel.isHidden = false
                return false
            }
            guard self.configurations?.getConfigurations()[index].task != ViewControllerReference.shared.syncremote else {
                self.infolabel.stringValue = Inforestore().info(num: 5)
                self.infolabel.isHidden = false
                return false
            }
        }
        return true
    }

    func executefullrestore() {
        var tmprestore: Bool = true
        switch self.selecttmptorestore.state {
        case .on:
            guard self.restoreactions?.goforfullrestoretotemporarypath() ?? false else { return }
            guard (self.restoreactions?.executerealrestore ?? false) == true else {
                self.infolabel.stringValue = NSLocalizedString("Simulated: execute full restore to temporary restore path", comment: "Restore")
                return
            }
        case .off:
            tmprestore = false
            guard self.restoreactions?.goforfullrestore() ?? false else { return }
            guard (self.restoreactions?.executerealrestore ?? false) == true else {
                self.infolabel.stringValue = NSLocalizedString("Simulated: execute full restore to SOURCE", comment: "Restore")
                return
            }
        default:
            return
        }
        let question: String = NSLocalizedString("Do you REALLY want to start a restore?", comment: "Restore")
        let text: String = NSLocalizedString("Cancel or Restore", comment: "Restore")
        let dialog: String = NSLocalizedString("Restore", comment: "Restore")
        let answer = Alerts.dialogOrCancel(question: question, text: text, dialog: dialog)
        if answer {
            if let index = self.index {
                let gotit: String = NSLocalizedString("Executing restore...", comment: "Restore")
                self.infolabel.stringValue = gotit
                self.infolabel.isHidden = false
                globalMainQueue.async { () -> Void in
                    self.presentAsSheet(self.viewControllerProgress!)
                }
                if tmprestore {
                    self.fullrestoretask = FullrestoreTask(index: index, dryrun: false, tmprestore: true, updateprogress: self)
                    self.outputprocess = self.fullrestoretask?.outputprocess
                } else {
                    self.fullrestoretask = FullrestoreTask(index: index, dryrun: false, tmprestore: false, updateprogress: self)
                    self.outputprocess = self.fullrestoretask?.outputprocess
                }
            }
        }
    }

    func settmprestorepathfromuserconfig() {
        let setuserconfig: String = NSLocalizedString(" ... set in User configuration ...", comment: "Restore")
        self.tmprestorepath.stringValue = ViewControllerReference.shared.temporarypathforrestore ?? setuserconfig
        if (ViewControllerReference.shared.temporarypathforrestore ?? "").isEmpty == true {
            self.selecttmptorestore.state = .off
            self.restoreactions?.tmprestorepathselected = false
        } else {
            self.selecttmptorestore.state = .on
            self.restoreactions?.tmprestorepathselected = true
        }
        self.restoreactions?.tmprestorepathverified = self.verifytmprestorepath()
    }

    func verifytmprestorepath() -> Bool {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: self.tmprestorepath.stringValue) == false {
            self.infolabel.stringValue = Inforestore().info(num: 1)
            return false
        } else {
            self.infolabel.isHidden = true
            return true
        }
    }

    @IBAction func toggletmprestore(_: NSButton) {
        if self.selecttmptorestore.state == .on {
            self.restoreactions?.tmprestorepathselected = true
        } else {
            self.restoreactions?.tmprestorepathselected = false
        }
        self.reset()
        if self.restoreactions?.tmprestorepathverified == false {
            self.selecttmptorestore.state = .off
            Alerts.showInfo(info: NSLocalizedString("No such temporay catalog for restore, set it in user config.", comment: "Restore"))
        }
    }

    @IBAction func togglewhichtypeofrestore(_: NSButton) {
        guard self.restoreactions?.reset() == false else {
            self.reset()
            return
        }
        if self.filesrestoreradiobutton.state == .on, self.selecttmptorestore.state == .on {
            self.restoreactions?.restorefiles = true
        } else if self.fullrestoreradiobutton.state == .on, self.selecttmptorestore.state == .on {
            self.restoretabledata = nil
            self.restoreactions?.fullrestore = true
            self.restoreactions?.restorefiles = false
            self.restoreactions?.tmprestorepathselected = true
        } else if self.fullrestoreradiobutton.state == .on, self.selecttmptorestore.state == .off {
            self.restoretabledata = nil
            self.restoreactions?.fullrestore = true
            self.restoreactions?.restorefiles = false
            self.restoreactions?.tmprestorepathselected = false
        }
        globalMainQueue.async { () -> Void in
            self.restoretableView.reloadData()
        }
    }

    @IBAction func restore(_: NSButton) {
        if self.fullrestoreradiobutton.state == .on {
            self.executefullrestore()
        } else {
            self.executerestorefiles()
        }
    }

    @IBAction func estimate(_: NSButton) {
        guard self.checkforrsync() == false else { return }
        if (self.restoreactions?.goforfullrestoreestimatetemporarypath() ?? false) || (self.restoreactions?.goforfullrestoreestimate() ?? false) {
            guard self.checkforfullrestore() == true else { return }
            if let index = self.index {
                let gotit: String = NSLocalizedString("Getting info, please wait...", comment: "Restore")
                self.infolabel.stringValue = gotit
                self.infolabel.isHidden = false
                self.working.startAnimation(nil)
                if self.restoreactions?.goforfullrestoreestimatetemporarypath() ?? false {
                    self.fullrestoretask = FullrestoreTask(index: index, dryrun: true, tmprestore: true, updateprogress: self)
                    self.outputprocess = self.fullrestoretask?.outputprocess
                } else if self.restoreactions?.goforfullrestoreestimate() ?? false {
                    self.selecttmptorestore.state = .off
                    self.fullrestoretask = FullrestoreTask(index: index, dryrun: true, tmprestore: false, updateprogress: self)
                    self.outputprocess = self.fullrestoretask?.outputprocess
                }
            }
        } else {
            guard self.restoreactions?.remotefileverified ?? false else { return }
            self.working.startAnimation(nil)
            self.restorefilestask?.executecopyfiles(remotefile: self.remotefiles!.stringValue, localCatalog: self.tmprestorepath!.stringValue, dryrun: true, updateprogress: self)
            self.outputprocess = self.restorefilestask?.outputprocess
        }
    }

    func initpopupbutton() {
        var profilestrings: [String]?
        profilestrings = CatalogProfile().getcatalogsasstringnames()
        profilestrings?.insert(NSLocalizedString("Default profile", comment: "default profile"), at: 0)
        self.profilepopupbutton.removeAllItems()
        self.profilepopupbutton.addItems(withTitles: profilestrings ?? [])
        self.profilepopupbutton.selectItem(at: 0)
    }

    @IBAction func selectprofile(_: NSButton) {
        var profile = self.profilepopupbutton.titleOfSelectedItem
        let selectedindex = self.profilepopupbutton.indexOfSelectedItem
        if profile == NSLocalizedString("Default profile", comment: "default profile") {
            profile = nil
        }
        self.profilepopupbutton.selectItem(at: selectedindex)
        _ = Selectprofile(profile: profile, selectedindex: selectedindex)
        self.reset()
    }

    @IBAction func toggledotherealthing(_: NSButton) {
        if self.dotherealthing.state == .on {
            self.restoreactions?.executerealrestore = true
        } else {
            self.restoreactions?.executerealrestore = false
        }
    }
}
