//  Created by Thomas Evensen on 19/08/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
//  swiftlint:disable type_body_length  line_length

import Cocoa
import Foundation

class ViewControllerMain: NSViewController, ReloadTable, Deselect, VcMain, Delay, ErrorMessage, Setcolor, Checkforrsync, Help, Connected {
    // Main tableview
    @IBOutlet var mainTableView: NSTableView!
    // Progressbar indicating work
    @IBOutlet var working: NSProgressIndicator!
    // Showing info about profile
    @IBOutlet var profilInfo: NSTextField!
    @IBOutlet var rsyncversionshort: NSTextField!
    @IBOutlet var profilepopupbutton: NSPopUpButton!

    // Configurations object
    var configurations: Configurations?
    var schedules: Schedules?
    // Reference to the taskobjects
    var singletask: SingleTask?
    var executetasknow: ExecuteTaskNow?
    // Index to selected row, index is set when row is selected
    var index: Int?
    var lastindex: Int?
    // Getting output from rsync
    // Indexes, multiple selection
    var indexes: IndexSet?
    var multipeselection: Bool = false
    var outputprocess: OutputProcess?
    // Send messages to the sidebar
    weak var sidebaractionsDelegate: Sidebaractions?

    // Toolbar - all profiles
    @IBAction func allprofiles(_: NSButton) {
        self.presentAsModalWindow(self.allprofiles!)
    }

    // Toolbar -  Find tasks and Execute backup
    @IBAction func automaticbackup(_: NSButton) {
        guard self.checkforrsync() == false else { return }
        guard ViewControllerReference.shared.process == nil else { return }
        self.presentAsSheet(self.viewControllerEstimating!)
    }

    // Toolbar - Abort button
    @IBAction func abort(_: NSButton) {
        globalMainQueue.async { () -> Void in
            self.abortOperations()
        }
    }

    // Toolbar - Userconfiguration button
    @IBAction func userconfiguration(_: NSButton) {
        guard ViewControllerReference.shared.process == nil else { return }
        self.presentAsModalWindow(self.viewControllerUserconfiguration!)
    }

    // Toolbar - Estimate and Quickbackup
    @IBAction func totinfo(_: NSButton) {
        guard self.checkforrsync() == false else { return }
        self.multipeselection = false
        globalMainQueue.async { () -> Void in
            self.presentAsSheet(self.viewControllerRemoteInfo!)
        }
    }

    // Toolbar - Multiple select and execute
    // Execute multipleselected tasks, only from main view
    @IBAction func executemultipleselectedindexes(_: NSButton) {
        guard self.checkforrsync() == false else { return }
        guard ViewControllerReference.shared.process == nil else { return }
        guard self.indexes != nil else {
            self.info.stringValue = Infoexecute().info(num: 6)
            return
        }
        self.multipeselection = true
        globalMainQueue.async { () -> Void in
            self.presentAsSheet(self.viewControllerRemoteInfo!)
        }
    }

    @IBOutlet var info: NSTextField!

    @IBAction func infoonetask(_: NSButton) {
        guard self.index != nil else {
            self.info.stringValue = Infoexecute().info(num: 1)
            return
        }
        guard self.checkforrsync() == false else { return }
        if let index = self.index {
            if let task = self.configurations?.getConfigurations()?[index].task {
                guard ViewControllerReference.shared.synctasks.contains(task) else {
                    self.info.stringValue = Infoexecute().info(num: 7)
                    return
                }
                self.presentAsSheet(self.viewControllerInformationLocalRemote!)
            }
        }
    }

    func delete() {
        guard ViewControllerReference.shared.process == nil else { return }
        guard self.index != nil else {
            self.info.stringValue = Infoexecute().info(num: 1)
            return
        }
        if let index = self.index {
            self.deleterow(index: index)
        }
    }

    func deleterow(index: Int?) {
        if let index = index {
            if let hiddenID = self.configurations?.gethiddenID(index: index) {
                let question: String = NSLocalizedString("Delete selected task?", comment: "Execute")
                let text: String = NSLocalizedString("Cancel or Delete", comment: "Execute")
                let dialog: String = NSLocalizedString("Delete", comment: "Execute")
                let answer = Alerts.dialogOrCancel(question: question, text: text, dialog: dialog)
                if answer {
                    // Delete Configurations and Schedules by hiddenID
                    self.configurations?.deleteConfigurationsByhiddenID(hiddenID: hiddenID)
                    self.schedules?.deletescheduleonetask(hiddenID: hiddenID)
                    self.deselect()
                    self.reloadtabledata()
                }
            }
            self.reset()
            self.singletask = nil
        }
    }

    func reset() {
        // Close edit and parameters view if open
        if let view = ViewControllerReference.shared.getvcref(viewcontroller: .vcrsyncparameters) as? ViewControllerRsyncParameters {
            weak var closeview: ViewControllerRsyncParameters?
            closeview = view
            closeview?.closeview()
        }
        if let view = ViewControllerReference.shared.getvcref(viewcontroller: .vcedit) as? ViewControllerEdit {
            weak var closeview: ViewControllerEdit?
            closeview = view
            closeview?.closeview()
        }
    }

    @IBAction func TCP(_: NSButton) {
        self.configurations?.tcpconnections = TCPconnections()
        self.configurations?.tcpconnections?.testAllremoteserverConnections()
        self.displayProfile()
    }

    // Presenting Information from Rsync
    @IBAction func information(_: NSButton) {
        globalMainQueue.async { () -> Void in
            self.presentAsSheet(self.viewControllerInformation!)
        }
    }

    // Selecting profiles
    @IBAction func profiles(_: NSButton) {
        guard ViewControllerReference.shared.process == nil else { return }
        if self.configurations?.tcpconnections?.connectionscheckcompleted ?? true {
            self.presentAsModalWindow(self.viewControllerProfile!)
        } else {
            self.displayProfile()
        }
    }

    // Selecting About
    @IBAction func about(_: NSButton) {
        guard ViewControllerReference.shared.process == nil else { return }
        self.presentAsModalWindow(self.viewControllerAbout!)
    }

    // All ouput
    @IBAction func alloutput(_: NSButton) {
        guard ViewControllerReference.shared.process == nil else { return }
        self.presentAsModalWindow(self.viewControllerAllOutput!)
    }

    @IBAction func executetasknow(_: NSButton) {
        guard self.checkforrsync() == false else { return }
        guard self.index != nil else {
            self.info.stringValue = Infoexecute().info(num: 1)
            return
        }
        if let index = self.index {
            self.executetask(index: index)
        }
    }

    func executetask(index: Int?) {
        if let index = index {
            if let task = self.configurations?.getConfigurations()?[index].task {
                guard ViewControllerReference.shared.synctasks.contains(task) else { return }
                self.executetasknow = ExecuteTaskNow(index: index)
            }
        }
    }

    @IBAction func showHelp(_: AnyObject?) {
        self.help()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Decide if:
        // 1: First time start, use new profilepath
        // 2: Old profilepath is copied to new, use new profilepath
        // 3: Use old profilepath
        // ViewControllerReference.shared.usenewconfigpath = true or false (default true)
        _ = Neworoldprofilepath()
        // Create base profile catalog
        CatalogProfile().createrootprofilecatalog()
        // Must read userconfig when loading main view, view only load once
        if let userconfiguration = PersistentStorageUserconfiguration().readuserconfiguration() {
            _ = Userconfiguration(userconfigRsyncGUI: userconfiguration)
        } else {
            _ = RsyncVersionString()
        }
        self.mainTableView.delegate = self
        self.mainTableView.dataSource = self
        self.mainTableView.allowsMultipleSelection = true
        self.working.usesThreadedAnimation = true
        ViewControllerReference.shared.setvcref(viewcontroller: .vctabmain, nsviewcontroller: self)
        _ = RsyncVersionString()
        self.mainTableView.target = self
        self.mainTableView.doubleAction = #selector(ViewControllerMain.tableViewDoubleClick(sender:))
        self.createandreloadconfigurations()
        self.createandreloadschedules()
        self.initpopupbutton()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        // For sending messages to the sidebar
        self.sidebaractionsDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcsidebar) as? ViewControllerSideBar
        self.sidebaractionsDelegate?.sidebaractions(action: .mainviewbuttons)
        if ViewControllerReference.shared.initialstart == 0 {
            self.view.window?.center()
            ViewControllerReference.shared.initialstart = 1
        }
        if (self.configurations?.configurations?.count ?? 0) > 0 {
            globalMainQueue.async { () -> Void in
                self.mainTableView.reloadData()
            }
        }
        self.rsyncischanged()
        self.displayProfile()
        self.info.stringValue = Infoexecute().info(num: 0)
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.multipeselection = false
    }

    // Execute tasks by double click in table
    @objc(tableViewDoubleClick:) func tableViewDoubleClick(sender _: AnyObject) {
        self.executeSingleTask()
    }

    // Single task can be activated by double click from table
    func executeSingleTask() {
        guard self.checkforrsync() == false else { return }
        if let index = self.index {
            let task = self.configurations?.getConfigurations()?[index].task ?? ""
            guard ViewControllerReference.shared.synctasks.contains(task) else {
                self.info.stringValue = Infoexecute().info(num: 6)
                return
            }
            guard self.singletask != nil else {
                // Dry run
                self.singletask = SingleTask(index: self.index!)
                self.singletask?.executesingletask()
                return
            }
            // Real run
            self.singletask?.executesingletask()
        }
    }

    // Function for setting profile
    func displayProfile() {
        weak var localprofileinfomain: SetProfileinfo?
        weak var localprofileinfoadd: SetProfileinfo?
        guard self.configurations?.tcpconnections?.connectionscheckcompleted ?? true else {
            self.profilInfo.stringValue = "Profile: please wait..."
            self.profilInfo.textColor = .white
            return
        }
        if let profile = self.configurations?.getProfile() {
            self.profilInfo.stringValue = "Profile: " + profile
            self.profilInfo.textColor = setcolor(nsviewcontroller: self, color: .white)
        } else {
            self.profilInfo.stringValue = "Profile: default"
            self.profilInfo.textColor = setcolor(nsviewcontroller: self, color: .green)
        }
        localprofileinfoadd = ViewControllerReference.shared.getvcref(viewcontroller: .vcnewconfigurations) as? ViewControllerNewConfigurations
        localprofileinfomain?.setprofile(profile: self.profilInfo.stringValue, color: self.profilInfo.textColor!)
        localprofileinfoadd?.setprofile(profile: self.profilInfo.stringValue, color: self.profilInfo.textColor!)
    }

    func createandreloadschedules() {
        guard self.configurations != nil else {
            self.schedules = Schedules(profile: nil)
            return
        }
        if let profile = self.configurations?.getProfile() {
            self.schedules = nil
            self.schedules = Schedules(profile: profile)
        } else {
            self.schedules = nil
            self.schedules = Schedules(profile: nil)
        }
    }

    func createandreloadconfigurations() {
        guard self.configurations != nil else {
            self.configurations = Configurations(profile: nil)
            return
        }
        if let profile = self.configurations?.getProfile() {
            self.configurations = nil
            self.configurations = Configurations(profile: profile)
        } else {
            self.configurations = nil
            self.configurations = Configurations(profile: nil)
        }
        globalMainQueue.async { () -> Void in
            self.mainTableView.reloadData()
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
    }

    @IBAction func checksynchronizedfiles(_: NSButton) {
        if let index = self.index {
            if let config = self.configurations?.getConfigurations()?[index] {
                guard config.task != ViewControllerReference.shared.syncremote else {
                    self.info.stringValue = NSLocalizedString("Cannot verify a syncremote task...", comment: "Verify")
                    return
                }
                guard self.connected(config: config) == true else {
                    self.info.stringValue = NSLocalizedString("Seems not to be connected...", comment: "Verify")
                    return
                }
                let check = Checksynchronizedfiles(index: index)
                check.checksynchronizedfiles()
            }
        }
    }
}
