//
//  ViewControllertabMain.swift
//  RsyncGUIver30
//  The Main ViewController.
//
//  Created by Thomas Evensen on 19/08/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
//  swiftlint:disable file_length type_body_length line_length

import Foundation
import Cocoa

// Protocol for start,stop, complete progressviewindicator
protocol StartStopProgressIndicator: class {
    func start()
    func stop()
    func complete()
}

// Protocol for either completion of work or update progress when Process discovers a
// process termination and when filehandler discover data
protocol UpdateProgress: class {
    func processTermination()
    func fileHandler()
}

protocol ViewOutputDetails: class {
    func reloadtable()
    func appendnow() -> Bool
    func getalloutput() -> [String]
    func enableappend()
    func disableappend()
}

protocol SetProfileinfo: class {
    func setprofile(profile: String, color: NSColor)
}

// Protocol for getting the hiddenID for a configuration
protocol GetHiddenID: class {
    func gethiddenID() -> Int?
}

class ViewControllertabMain: NSViewController, ReloadTable, Deselect, VcMain, Delay, Fileerrormessage {

    // Configurations object
    var configurations: Configurations?
    var schedules: Schedules?
    // Reference to the single taskobject
    var singletask: SingleTask?
    // Reference to batch taskobject
    var batchtasks: BatchTask?
    var verifyrsyncpath: Verifyrsyncpath?
    var tcpconnections: TCPconnections?
    // Delegate function getting batchTaskObject
    weak var batchtasksDelegate: GetNewBatchTask?
    // Main tableview
    @IBOutlet weak var mainTableView: NSTableView!
    // Progressbar indicating work
    @IBOutlet weak var working: NSProgressIndicator!
    @IBOutlet weak var workinglabel: NSTextField!
    // Displays the rsyncCommand
    @IBOutlet weak var rsyncCommand: NSTextField!
    // If On result of Dryrun is presented before
    // executing the real run
    @IBOutlet weak var dryRunOrRealRun: NSTextField!
    // number of files to be transferred
    @IBOutlet weak var transferredNumber: NSTextField!
    // size of files to be transferred
    @IBOutlet weak var transferredNumberSizebytes: NSTextField!
    // total number of files in remote volume
    @IBOutlet weak var totalNumber: NSTextField!
    // total size of files in remote volume
    @IBOutlet weak var totalNumberSizebytes: NSTextField!
    // total number of directories remote volume
    @IBOutlet weak var totalDirs: NSTextField!
    // Showing info about profile
    @IBOutlet weak var profilInfo: NSTextField!
    // New files
    @IBOutlet weak var newfiles: NSTextField!
    // Delete files
    @IBOutlet weak var deletefiles: NSTextField!
    @IBOutlet weak var rsyncversionshort: NSTextField!
    @IBOutlet weak var backupdryrun: NSButton!
    @IBOutlet weak var restoredryrun: NSButton!
    @IBOutlet weak var verifydryrun: NSButton!

    // Reference to Process task
    var process: Process?
    // Index to selected row, index is set when row is selected
    var index: Int?
    // Getting output from rsync 
    var outputprocess: OutputProcess?
    // Dynamic view of output
    var dynamicappend: Bool = false
    // HiddenID task, set when row is selected
    var hiddenID: Int?
    // Reference to Schedules object
    var schedulesortedandexpanded: ScheduleSortedAndExpand?
    // Bool if one or more remote server is offline
    // Used in testing if remote server is on/off-line
    var serverOff: [Bool]?
    // Ready for execute again
    var readyforexecution: Bool = true
    // Can load profiles
    // Load profiles only when testing for connections are done.
    // Application crash if not
    var loadProfileMenu: Bool = false
    // Which kind of task
    var processtermination: ProcessTermination?
    // Keep track of all errors
    var outputerrors: OutputErrors?
    // Update view estimating
    weak var estimateupdateDelegate: Updateestimating?
    // used in updating tableview
    var setbatchyesno: Bool = false

    @IBOutlet weak var info: NSTextField!

    @IBAction func restore(_ sender: NSButton) {
        guard self.index != nil else {
            self.info(num: 1)
            return
        }
        guard ViewControllerReference.shared.norsync == false else {
            self.verifyrsyncpath!.noRsync()
            return
        }
        guard self.configurations!.getConfigurations()[self.index!].task == ViewControllerReference.shared.backup ||
            self.configurations!.getConfigurations()[self.index!].task == ViewControllerReference.shared.snapshot
            else {
                self.info(num: 7)
                return
        }
        self.processtermination = .restore
        self.presentAsSheet(self.restoreViewController!)
    }

    func info(num: Int) {
        switch num {
        case 1:
            self.info.stringValue = "Select a task...."
        case 2:
            self.info.stringValue = "Possible error logging..."
        case 3:
            self.info.stringValue = "No rsync in path..."
        case 4:
            self.info.stringValue = "⌘A to abort or wait..."
        case 5:
             self.info.stringValue = "Menu app is running..."
        case 6:
            self.info.stringValue = "This is a combined task, execute by ⌘R..."
        case 7:
            self.info.stringValue = "Only valid for backup, snapshot and combined tasks..."
        case 8:
            self.info.stringValue = "No rclone config found..."
        default:
            self.info.stringValue = ""
        }
    }

    @IBAction func infoonetask(_ sender: NSButton) {
        guard self.index != nil else {
            self.info(num: 1)
            return
        }
        guard ViewControllerReference.shared.norsync == false else {
            self.verifyrsyncpath!.noRsync()
            return
        }
        guard self.configurations!.getConfigurations()[self.index!].task == ViewControllerReference.shared.backup ||
            self.configurations!.getConfigurations()[self.index!].task == ViewControllerReference.shared.snapshot
            else {
                self.info(num: 7)
                return
        }
        self.processtermination = .infosingletask
        self.presentAsSheet(self.viewControllerInformationLocalRemote!)
    }

    @IBAction func totinfo(_ sender: NSButton) {
        guard ViewControllerReference.shared.norsync == false else {
            self.verifyrsyncpath!.noRsync()
            return
        }
        self.processtermination = .remoteinfotask
        globalMainQueue.async(execute: { () -> Void in
            self.presentAsSheet(self.viewControllerRemoteInfo!)
        })
    }

    @IBAction func quickbackup(_ sender: NSButton) {
        guard ViewControllerReference.shared.norsync == false else {
            self.verifyrsyncpath!.noRsync()
            return
        }
        self.openquickbackup()
    }

    @IBAction func edit(_ sender: NSButton) {
        self.reset()
        guard self.index != nil else {
            self.info(num: 1)
            return
        }
        globalMainQueue.async(execute: { () -> Void in
            self.presentAsSheet(self.editViewController!)
        })
    }

    @IBAction func rsyncparams(_ sender: NSButton) {
        self.reset()
        guard self.index != nil else {
            self.info(num: 1)
            return
        }
        globalMainQueue.async(execute: { () -> Void in
            self.presentAsSheet(self.viewControllerRsyncParams!)
        })
    }

    @IBAction func delete(_ sender: NSButton) {
        self.reset()
        guard self.hiddenID != nil else {
            self.info(num: 1)
            return
        }
        let answer = Alerts.dialogOKCancel("Delete selected task?", text: "Cancel or OK")
        if answer {
            if self.hiddenID != nil {
                // Delete Configurations and Schedules by hiddenID
                self.configurations!.deleteConfigurationsByhiddenID(hiddenID: self.hiddenID!)
                self.schedules!.deletescheduleonetask(hiddenID: self.hiddenID!)
                self.deselect()
                self.hiddenID = nil
                self.index = nil
                self.reloadtabledata()
                self.reloadtable(vcontroller: .vcsnapshot)
            }
        }
    }

    func reset() {
        self.outputprocess = nil
        self.setNumbers(outputprocess: nil)
        self.process = nil
        self.singletask = nil
    }

    @IBOutlet weak var TCPButton: NSButton!
    @IBAction func TCP(_ sender: NSButton) {
        self.TCPButton.isEnabled = false
        self.loadProfileMenu = false
        self.displayProfile()
        self.tcpconnections = TCPconnections()
        self.tcpconnections?.testAllremoteserverConnections()
    }

    // Presenting Information from Rsync
    @IBAction func information(_ sender: NSButton) {
        globalMainQueue.async(execute: { () -> Void in
            self.presentAsSheet(self.viewControllerInformation!)
        })
    }

    // Abort button
    @IBAction func abort(_ sender: NSButton) {
        globalMainQueue.async(execute: { () -> Void in
            self.abortOperations()
            self.process = nil
        })
    }

    // Userconfiguration button
    @IBAction func userconfiguration(_ sender: NSButton) {
        globalMainQueue.async(execute: { () -> Void in
            self.presentAsSheet(self.viewControllerUserconfiguration!)
        })
    }

    // Selecting profiles
    @IBAction func profiles(_ sender: NSButton) {
        if self.loadProfileMenu == true {
            globalMainQueue.async(execute: { () -> Void in
                self.presentAsSheet(self.viewControllerProfile!)
            })
        } else {
            self.displayProfile()
        }
    }

    // Logg records
    @IBAction func loggrecords(_ sender: NSButton) {
        self.configurations!.allowNotifyinMain = true
        globalMainQueue.async(execute: { () -> Void in
            self.presentAsSheet(self.viewControllerScheduleDetails!)
        })
    }

    // Selecting About
    @IBAction func about (_ sender: NSButton) {
        self.presentAsModalWindow(self.viewControllerAbout!)
    }

    // Selecting automatic backup
    @IBAction func automaticbackup (_ sender: NSButton) {
        self.automaticbackup()
    }

    @IBAction func executetasknow(_ sender: NSButton) {
        self.processtermination = .singlequicktask
        guard ViewControllerReference.shared.norsync == false else {
            self.verifyrsyncpath!.noRsync()
            return
        }
        guard self.hiddenID != nil else {
            self.info(num: 1)
            return
        }
        guard self.index != nil else {
            self.info(num: 1)
            return
        }
        guard self.configurations!.getConfigurations()[self.index!].task == ViewControllerReference.shared.backup ||
            self.configurations!.getConfigurations()[self.index!].task == ViewControllerReference.shared.snapshot
            else { return }
        self.executetasknow()
    }

    func executetasknow() {
        guard self.index != nil  else { return }
        self.processtermination = .singlequicktask
        self.working.startAnimation(nil)
        let arguments = self.configurations!.arguments4rsync(index: self.index!, argtype: .arg)
        self.outputprocess = OutputProcess()
        let process = Rsync(arguments: arguments)
        process.executeProcess(outputprocess: self.outputprocess)
        self.process = process.getProcess()
    }

    func automaticbackup() {
        self.processtermination = .automaticbackup
        self.configurations?.remoteinfotaskworkqueue = RemoteInfoTaskWorkQueue(inbatch: false)
        self.presentAsSheet(self.viewControllerEstimating!)
        self.estimateupdateDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcestimatingtasks) as? ViewControllerEstimatingTasks
    }

    // Function for display rsync command
    @IBAction func showrsynccommand(_ sender: NSButton) {
        self.showrsynccommandmainview()
    }

    // Display correct rsync command in view
    func showrsynccommandmainview() {
        if let index = self.index {
            guard index <= self.configurations!.getConfigurations().count else { return }
            if self.backupdryrun.state == .on {
                self.rsyncCommand.stringValue = self.verifyrsyncpath!.displayrsynccommand(index: index, display: .synchronize)
            } else if self.restoredryrun.state == .on {
                self.rsyncCommand.stringValue = self.verifyrsyncpath!.displayrsynccommand(index: index, display: .restore)
            } else {
                self.rsyncCommand.stringValue = self.verifyrsyncpath!.displayrsynccommand(index: index, display: .verify)
            }
        } else {
            self.rsyncCommand.stringValue = ""
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.mainTableView.delegate = self
        self.mainTableView.dataSource = self
        self.working.usesThreadedAnimation = true
        ViewControllerReference.shared.setvcref(viewcontroller: .vctabmain, nsviewcontroller: self)
        _ = RsyncVersionString()
        self.mainTableView.target = self
        self.mainTableView.doubleAction = #selector(ViewControllertabMain.tableViewDoubleClick(sender:))
        self.backupdryrun.state = .on
        self.loadProfileMenu = true
        // configurations and schedules
        self.createandreloadconfigurations()
        self.createandreloadschedules()
        // 
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.configurations!.allowNotifyinMain = true
        if self.configurations!.configurationsDataSourcecount() > 0 {
            globalMainQueue.async(execute: { () -> Void in
                self.mainTableView.reloadData()
            })
        }
        self.rsyncischanged()
        self.displayProfile()
        self.readyforexecution = true
        if self.verifyrsyncpath == nil { self.verifyrsyncpath = Verifyrsyncpath()}
        if self.tcpconnections == nil { self.tcpconnections = TCPconnections()}
        self.info(num: 0)
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        // Do not allow notify in Main
        self.configurations!.allowNotifyinMain = false
        self.dynamicappend = false
    }

    // Execute tasks by double click in table
    @objc(tableViewDoubleClick:) func tableViewDoubleClick(sender: AnyObject) {
        if self.readyforexecution {
            self.executeSingleTask()
        }
        self.readyforexecution = false
    }

    // Single task can be activated by double click from table
    func executeSingleTask() {
        self.processtermination = .singletask
        guard ViewControllerReference.shared.norsync == false else {
            self.verifyrsyncpath!.noRsync()
            return
        }
        guard self.index != nil else { return }
        guard self.configurations!.getConfigurations()[self.index!].task == ViewControllerReference.shared.backup ||
            self.configurations!.getConfigurations()[self.index!].task == ViewControllerReference.shared.snapshot
            else {
                self.info(num: 6)
                return
        }
        self.batchtasks = nil
        guard self.singletask != nil else {
            // Dry run
            self.singletask = SingleTask(index: self.index!)
            self.singletask?.executeSingleTask()
            // Set reference to singleTask object
            self.configurations!.singleTask = self.singletask
            return
        }
        // Real run
        self.singletask?.executeSingleTask()
    }

    // Execute BATCH TASKS only
    @IBAction func executeBatch(_ sender: NSButton) {
        self.processtermination = .estimatebatchtask
        guard ViewControllerReference.shared.norsync == false else {
            self.verifyrsyncpath!.noRsync()
            return
        }
        self.singletask = nil
        self.setNumbers(outputprocess: nil)
        self.deselect()
        globalMainQueue.async(execute: { () -> Void in
            self.presentAsSheet(self.viewControllerBatch!)
        })
    }

    // Function for setting profile
    func displayProfile() {
        weak var localprofileinfomain: SetProfileinfo?
        weak var localprofileinfoadd: SetProfileinfo?
        guard self.loadProfileMenu == true else {
            self.profilInfo.stringValue = "Profile: please wait..."
            self.profilInfo.textColor = .white
            return
        }
        if let profile = self.configurations!.getProfile() {
            self.profilInfo.stringValue = "Profile: " + profile
            self.profilInfo.textColor = .white
        } else {
            self.profilInfo.stringValue = "Profile: default"
            self.profilInfo.textColor = .black
        }
        localprofileinfoadd = ViewControllerReference.shared.getvcref(viewcontroller: .vcnewconfigurations ) as? ViewControllerNewConfigurations
        localprofileinfomain?.setprofile(profile: self.profilInfo.stringValue, color: self.profilInfo.textColor!)
        localprofileinfoadd?.setprofile(profile: self.profilInfo.stringValue, color: self.profilInfo.textColor!)
        self.TCPButton.isEnabled = true
        self.showrsynccommandmainview()
    }

    // when row is selected
    // setting which table row is selected, force new estimation
    func tableViewSelectionDidChange(_ notification: Notification) {
        self.seterrorinfo(info: "")
        // If change row during estimation
        if self.process != nil { self.abortOperations() }
        // If change row after estimation, force new estimation
        if self.readyforexecution == false { self.abortOperations() }
        self.readyforexecution = true
        self.backupdryrun.state = .on
        self.info(num: 0)
        let myTableViewFromNotification = (notification.object as? NSTableView)!
        let indexes = myTableViewFromNotification.selectedRowIndexes
        if let index = indexes.first {
            self.index = index
            self.hiddenID = self.configurations!.gethiddenID(index: index)
            self.outputprocess = nil
            self.setNumbers(outputprocess: nil)
        } else {
            self.index = nil
        }
        self.process = nil
        self.singletask = nil
        self.showrsynccommandmainview()
        self.reloadtabledata()
        self.configurations!.allowNotifyinMain = true
    }

    func createandreloadschedules() {
        self.process = nil
        guard self.configurations != nil else {
            self.schedules = Schedules(profile: nil)
            return
        }
        if let profile = self.configurations!.getProfile() {
            self.schedules = nil
            self.schedules = Schedules(profile: profile)
        } else {
            self.schedules = nil
            self.schedules = Schedules(profile: nil)
        }
        self.schedulesortedandexpanded = ScheduleSortedAndExpand()
        ViewControllerReference.shared.quickbackuptask = self.schedulesortedandexpanded?.firstscheduledtask()
    }

    func createandreloadconfigurations() {
        guard self.configurations != nil else {
            self.configurations = Configurations(profile: nil, viewcontroller: self)
            return
        }
        if let profile = self.configurations!.getProfile() {
            self.configurations = nil
            self.configurations = Configurations(profile: profile, viewcontroller: self)
        } else {
            self.configurations = nil
            self.configurations = Configurations(profile: nil, viewcontroller: self)
        }
        globalMainQueue.async(execute: { () -> Void in
            self.mainTableView.reloadData()
        })
    }
}
