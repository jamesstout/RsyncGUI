//
//  extensionsViewControllertabMain.swift
//  RsyncGUI
//
//  Created by Thomas Evensen on 31.05.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//
//  swiftlint:disable file_length line_length cyclomatic_complexity function_body_length

import Foundation
import Cocoa

extension ViewControllertabMain: NSTableViewDataSource {
    // Delegate for size of table
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.configurations?.configurationsDataSourcecount() ?? 0
    }
}

extension ViewControllertabMain: NSTableViewDelegate, Attributedestring {

    // TableView delegates
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard self.configurations != nil else { return nil}
        if row > self.configurations!.configurationsDataSourcecount() - 1 { return nil }
        let object: NSDictionary = self.configurations!.getConfigurationsDataSource()![row]
        let markdays: Bool = self.configurations!.getConfigurations()[row].markdays
        let celltext = object[tableColumn!.identifier] as? String
        if tableColumn!.identifier.rawValue == "daysID" {
            if markdays {
                return self.attributedstring(str: celltext!, color: NSColor.red, align: .right)
            } else {
                return object[tableColumn!.identifier] as? String
            }
        } else if tableColumn!.identifier.rawValue == "offsiteServerCellID",
           ((object[tableColumn!.identifier] as? String)?.isEmpty) == true {
            return "localhost"
        } else if tableColumn!.identifier.rawValue == "statCellID" {
            if row == self.index {
                if self.singletask == nil {
                    return #imageLiteral(resourceName: "yellow")
                } else {
                    return #imageLiteral(resourceName: "green")
                }
            }
        } else {
            if tableColumn!.identifier.rawValue == "batchCellID" {
                return object[tableColumn!.identifier] as? Int
            } else {
                if (self.tcpconnections?.gettestAllremoteserverConnections()?[row]) ?? false && celltext != nil {
                    return self.attributedstring(str: celltext!, color: NSColor.red, align: .left)
                } else {
                    return object[tableColumn!.identifier] as? String
                }
            }
        }
        return nil
    }

    // Toggling batch
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        if self.process != nil {
            self.abortOperations()
        }
        if self.configurations!.getConfigurations()[row].task == ViewControllerReference.shared.synchronize {
            self.configurations!.enabledisablebatch(row)
        }
        self.singletask = nil
        self.batchtasks = nil
    }
}

// Get output from rsync command
extension ViewControllertabMain: GetOutput {
    // Get information from rsync output.
    func getoutput() -> [String] {
        return (self.outputprocess?.trimoutput(trim: .two)) ?? []
    }
}

// Scheduled task are changed, read schedule again og redraw table
extension ViewControllertabMain: Reloadandrefresh {
    // Refresh tableView in main
    func reloadtabledata() {
        globalMainQueue.async(execute: { () -> Void in
            self.mainTableView.reloadData()
        })
    }
}

// Parameters to rsync is changed
extension ViewControllertabMain: RsyncUserParams {
    // Do a reread of all Configurations
    func rsyncuserparamsupdated() {
        self.showrsynccommandmainview()
    }
}

// Get index of selected row
extension ViewControllertabMain: GetSelecetedIndex {
    func getindex() -> Int? {
        return self.index
    }
}

// New profile is loaded.
extension ViewControllertabMain: NewProfile {
    // Function is called from profiles when new or default profiles is seleceted
    func newProfile(profile: String?) {
        self.process = nil
        self.outputprocess = nil
        self.singletask = nil
        self.tcpconnections = nil
        self.setNumbers(outputprocess: nil)
        self.showrsynccommandmainview()
        self.deselect()
        // Read configurations and Scheduledata
        self.configurations = self.createconfigurationsobject(profile: profile)
        self.schedules = self.createschedulesobject(profile: profile)
        // Make sure loading profile
        self.loadProfileMenu = true
        self.displayProfile()
        self.reloadtabledata()
        self.deselectrowtable()
    }

    func enableProfileMenu() {
        self.loadProfileMenu = true
        globalMainQueue.async(execute: { () -> Void in
            self.displayProfile()
        })
    }
}

// Rsync path is changed, update displayed rsync command
extension ViewControllertabMain: RsyncIsChanged {
    // If row is selected an update rsync command in view
    func rsyncischanged() {
        // Update rsync command in display
        self.showrsynccommandmainview()
        self.setinfoaboutrsync()
        // Setting shortstring
        self.rsyncversionshort.stringValue = ViewControllerReference.shared.rsyncversionshort ?? ""
    }
}

// Check for remote connections, reload table when completed.
extension ViewControllertabMain: Connections {
    // Remote servers offline are marked with red line in mainTableView
    func displayConnections() {
        // Only do a reload if we are in the main view
        guard Activetab(viewcontroller: .vctabmain).isactive == true else { return }
        self.loadProfileMenu = true
        globalMainQueue.async(execute: { () -> Void in
            self.mainTableView.reloadData()
        })
    }
}

// Dismisser for sheets
extension ViewControllertabMain: DismissViewController {
    // Function for dismissing a presented view
    func dismiss_view(viewcontroller: NSViewController) {
        self.dismiss(viewcontroller)
        // Reset radiobuttons
        self.loadProfileMenu = true
        globalMainQueue.async(execute: { () -> Void in
            self.mainTableView.reloadData()
            self.displayProfile()
        })
        self.setinfoaboutrsync()
    }
}

extension ViewControllertabMain: DismissViewEstimating {
    func dismissestimating(viewcontroller: NSViewController) {
        self.dismiss(viewcontroller)
    }
}

// Called when either a terminatopn of Process is
// discovered or data is availiable in the filehandler
// See file rsyncProcess.swift.
extension ViewControllertabMain: UpdateProgress {

    // Delegate functions called from the Process object
    // Protocol UpdateProgress two functions, ProcessTermination() and FileHandler()
    func processTermination() {
        self.readyforexecution = true
        if self.configurations!.processtermination == nil {
            self.configurations!.processtermination = .singlequicktask
        }
        switch self.configurations!.processtermination! {
        case .singletask:
            guard self.singletask != nil else { return }
            self.outputprocess = self.singletask!.outputprocess
            self.process = self.singletask!.process
            self.singletask!.processTermination()
        case .batchtask:
            self.batchtasksDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcbatch) as? ViewControllerBatch
            self.batchtasks = self.batchtasksDelegate?.getbatchtaskObject()
            self.outputprocess = self.batchtasks?.outputprocess
            self.process = self.batchtasks?.process
            self.batchtasks?.processTermination()
        case .quicktask:
            guard ViewControllerReference.shared.completeoperation != nil else { return }
            ViewControllerReference.shared.completeoperation!.finalizeScheduledJob(outputprocess: self.outputprocess)
            // After logging is done set reference to object = nil
            ViewControllerReference.shared.completeoperation = nil
            weak var processterminationDelegate: UpdateProgress?
            processterminationDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcquickbackup) as? ViewControllerQuickBackup
            processterminationDelegate?.processTermination()
        case .singlequicktask:
            guard self.index != nil else { return }
            self.seterrorinfo(info: "")
            self.working.stopAnimation(nil)
            self.configurations!.setCurrentDateonConfiguration(index: self.index!, outputprocess: self.outputprocess)
        case .remoteinfotask:
            guard self.configurations!.remoteinfotaskworkqueue != nil else { return }
            self.configurations!.remoteinfotaskworkqueue?.processTermination()
        case .infosingletask:
            weak var processterminationDelegate: UpdateProgress?
            processterminationDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcinfolocalremote) as? ViewControllerInformationLocalRemote
            processterminationDelegate?.processTermination()
        case .automaticbackup:
            guard self.configurations!.remoteinfotaskworkqueue != nil else { return }
            weak var estimateupdateDelegate: Updateestimating?
            estimateupdateDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcestimatingtasks) as? ViewControllerEstimatingTasks
            // compute alle estimates
            if self.configurations!.remoteinfotaskworkqueue!.stackoftasktobeestimated != nil {
                self.configurations!.remoteinfotaskworkqueue?.processTermination()
                estimateupdateDelegate?.updateProgressbar()
            } else {
                estimateupdateDelegate?.dismissview()
                self.configurations!.remoteinfotaskworkqueue?.processTermination()
                self.configurations!.remoteinfotaskworkqueue?.selectalltaskswithnumbers(deselect: false)
                self.configurations!.remoteinfotaskworkqueue?.setbackuplist()
                weak var openDelegate: OpenQuickBackup?
                switch ViewControllerReference.shared.activetab ?? .vctabmain {
                case .vcnewconfigurations:
                    openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcnewconfigurations) as? ViewControllerNewConfigurations
                case .vctabmain:
                    openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllertabMain
                case .vccopyfiles:
                    openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vccopyfiles) as? ViewControllerCopyFiles
                case .vcverify:
                    openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcverify) as? ViewControllerVerify
                case .vcssh:
                    openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcssh) as? ViewControllerSsh
                case .vcloggdata:
                    openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcloggdata) as? ViewControllerLoggData
                default:
                    openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllertabMain
                }
                openDelegate?.openquickbackup()
            }
        case .restore:
            weak var processterminationDelegate: UpdateProgress?
            processterminationDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcrestore) as? ViewControllerRestore
            processterminationDelegate?.processTermination()
        case .estimatebatchtask:
            guard self.configurations!.remoteinfotaskworkqueue != nil else { return }
            weak var estimateupdateDelegate: Updateestimating?
            estimateupdateDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcestimatingtasks) as? ViewControllerEstimatingTasks
            // compute alle estimates
            if self.configurations!.remoteinfotaskworkqueue!.stackoftasktobeestimated != nil {
                self.configurations!.remoteinfotaskworkqueue?.processTermination()
                estimateupdateDelegate?.updateProgressbar()
            } else {
                self.configurations!.remoteinfotaskworkqueue?.processTermination()
                self.configurations!.processtermination = .batchtask
            }
        }
    }

    // Function is triggered when Process outputs data in filehandler
    // Process is either in singleRun or batchRun
    func fileHandler() {
        weak var outputeverythingDelegate: ViewOutputDetails?
        if self.configurations!.processtermination == nil {
            self.configurations!.processtermination = .singlequicktask
        }
        switch self.configurations!.processtermination! {
        case .singletask:
            guard self.singletask != nil else { return }
            weak var localprocessupdateDelegate: UpdateProgress?
            localprocessupdateDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcprogressview) as? ViewControllerProgressProcess
            self.outputprocess = self.singletask!.outputprocess
            self.process = self.singletask!.process
            localprocessupdateDelegate?.fileHandler()
            outputeverythingDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllertabMain
            if outputeverythingDelegate?.appendnow() ?? false {
                outputeverythingDelegate?.reloadtable()
            }
        case .batchtask:
            weak var localprocessupdateDelegate: UpdateProgress?
            localprocessupdateDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcbatch) as? ViewControllerBatch
            localprocessupdateDelegate?.fileHandler()
        case .quicktask:
            weak var localprocessupdateDelegate: UpdateProgress?
            localprocessupdateDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcquickbackup) as? ViewControllerQuickBackup
            localprocessupdateDelegate?.fileHandler()
        case .singlequicktask:
            outputeverythingDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllertabMain
            if outputeverythingDelegate?.appendnow() ?? false {
                outputeverythingDelegate?.reloadtable()
            }
        case .remoteinfotask:
            outputeverythingDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllertabMain
            if outputeverythingDelegate?.appendnow() ?? false {
                outputeverythingDelegate?.reloadtable()
            }
        case .infosingletask:
            return
        case .automaticbackup:
            return
        case .restore:
            weak var localprocessupdateDelegate: UpdateProgress?
            localprocessupdateDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcrestore) as? ViewControllerRestore
            localprocessupdateDelegate?.fileHandler()
            outputeverythingDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllertabMain
            if outputeverythingDelegate?.appendnow() ?? false {
                outputeverythingDelegate?.reloadtable()
            }
        case .estimatebatchtask:
            return
        }
    }
}

// Deselect a row
extension ViewControllertabMain: DeselectRowTable {
    // deselect a row after row is deleted
    func deselect() {
        guard self.index != nil else { return }
        self.mainTableView.deselectRow(self.index!)
    }
}

// If rsync throws any error
extension ViewControllertabMain: RsyncError {
    func rsyncerror() {
        // Set on or off in user configuration
        globalMainQueue.async(execute: { () -> Void in
            self.seterrorinfo(info: "Error")
            self.showrsynccommandmainview()
            self.deselect()
            // Abort any operations
            if let process = self.process {
                process.terminate()
                self.process = nil
            }
            // Either error in single task or batch task
            if self.singletask != nil {
                self.singletask!.error()
            }
            if self.batchtasks != nil {
                self.batchtasks!.error()
            }
        })
    }
}

// If, for any reason, handling files or directory throws an error
extension ViewControllertabMain: Fileerror {
    func errormessage(errorstr: String, errortype: Fileerrortype ) {
        globalMainQueue.async(execute: { () -> Void in
            if errortype == .openlogfile {
                self.rsyncCommand.stringValue = self.errordescription(errortype: errortype)
            } else if errortype == .filesize {
                self.rsyncCommand.stringValue = self.errordescription(errortype: errortype) + ": filesize = " + errorstr
            } else {
                self.seterrorinfo(info: "Error")
                self.rsyncCommand.stringValue = self.errordescription(errortype: errortype) + "\n" + errorstr
            }
        })
    }
}

// Abort task from progressview
extension ViewControllertabMain: Abort {
    // Abort any task
    func abortOperations() {
        // Terminates the running process
        if let process = self.process {
            process.terminate()
            self.index = nil
            self.working.stopAnimation(nil)
            self.workinglabel.isHidden = true
            self.process = nil
            // Create workqueu and add abort
            self.seterrorinfo(info: "Abort")
            self.rsyncCommand.stringValue = ""
            if self.configurations!.remoteinfotaskworkqueue != nil && self.configurations?.estimatedlist != nil {
                weak var localestimateupdateDelegate: Updateestimating?
                localestimateupdateDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcestimatingtasks) as? ViewControllerEstimatingTasks
                localestimateupdateDelegate?.dismissview()
                self.configurations!.remoteinfotaskworkqueue = nil
            }
        } else {
            self.working.stopAnimation(nil)
            self.workinglabel.isHidden = true
            self.rsyncCommand.stringValue = "Selection out of range - aborting"
            self.process = nil
            self.index = nil
        }
    }
}

// Extensions from here are used in either newSingleTask or newBatchTask

extension ViewControllertabMain: StartStopProgressIndicatorSingleTask {
    func startIndicator() {
        self.working.startAnimation(nil)
        self.workinglabel.isHidden = false
    }

    func stopIndicator() {
        self.working.stopAnimation(nil)
        self.workinglabel.isHidden = true
    }
}

extension ViewControllertabMain: SingleTaskProgress {
    func getProcessReference(process: Process) {
        self.process = process
    }

    func presentViewProgress() {
        globalMainQueue.async(execute: { () -> Void in
            self.presentAsSheet(self.viewControllerProgress!)
        })
    }

    func presentViewInformation(outputprocess: OutputProcess) {
        self.outputprocess = outputprocess
        if self.dynamicappend {
            globalMainQueue.async(execute: { () -> Void in
                self.mainTableView.reloadData()
            })
        } else {
            globalMainQueue.async(execute: { () -> Void in
                self.presentAsSheet(self.viewControllerInformation!)
            })
        }
    }

    func terminateProgressProcess() {
        weak var localprocessupdateDelegate: UpdateProgress?
        localprocessupdateDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcprogressview) as? ViewControllerProgressProcess
        localprocessupdateDelegate?.processTermination()
    }

    func seterrorinfo(info: String) {
        guard info != "" else {
            self.dryRunOrRealRun.isHidden = true
            return
        }
        self.dryRunOrRealRun.textColor = .red
        self.dryRunOrRealRun.isHidden = false
        self.dryRunOrRealRun.stringValue = info
    }

    // Function for getting numbers out of output object updated when
    // Process object executes the job.
    func setNumbers(outputprocess: OutputProcess?) {
        globalMainQueue.async(execute: { () -> Void in
            guard outputprocess != nil else {
                self.transferredNumber.stringValue = ""
                self.transferredNumberSizebytes.stringValue = ""
                self.totalNumber.stringValue = ""
                self.totalNumberSizebytes.stringValue = ""
                self.totalDirs.stringValue = ""
                self.newfiles.stringValue = ""
                self.deletefiles.stringValue = ""
                return
            }
            let remoteinfotask = RemoteInfoTask(outputprocess: outputprocess)
            self.transferredNumber.stringValue = remoteinfotask.transferredNumber!
            self.transferredNumberSizebytes.stringValue = remoteinfotask.transferredNumberSizebytes!
            self.totalNumber.stringValue = remoteinfotask.totalNumber!
            self.totalNumberSizebytes.stringValue = remoteinfotask.totalNumberSizebytes!
            self.totalDirs.stringValue = remoteinfotask.totalDirs!
            self.newfiles.stringValue = remoteinfotask.newfiles!
            self.deletefiles.stringValue = remoteinfotask.deletefiles!
        })
    }

    // Returns number set from dryrun to use in logging run
    // after a real run. Logging is in newSingleTask object.
    func gettransferredNumber() -> String {
        return self.transferredNumber.stringValue
    }

    func gettransferredNumberSizebytes() -> String {
        return self.transferredNumberSizebytes.stringValue
    }
}

extension ViewControllertabMain: GetConfigurationsObject {
    func getconfigurationsobject() -> Configurations? {
        guard self.configurations != nil else { return nil }
        return self.configurations
    }

    func createconfigurationsobject(profile: String?) -> Configurations? {
        self.configurations = nil
        self.configurations = Configurations(profile: profile)
        return self.configurations
    }

    // After a write, a reload is forced.
    func reloadconfigurationsobject() {
        // If batchtask keep configuration object
        self.batchtasks = self.batchtasksDelegate?.getbatchtaskObject()
        guard self.batchtasks == nil else {
            // Batchtask, check if task is completed
            guard self.configurations!.getbatchQueue()?.batchruniscompleted() == false else {
                self.createandreloadconfigurations()
                return
            }
            return
        }
        self.createandreloadconfigurations()
    }
}

extension ViewControllertabMain: GetSchedulesObject {
    func reloadschedulesobject() {
        // If batchtask scedules object
        guard self.batchtasks == nil else {
            // Batchtask, check if task is completed
            guard self.configurations!.getbatchQueue()?.batchruniscompleted() == false else {
                self.createandreloadschedules()
                return
            }
            return
        }
        self.createandreloadschedules()
    }

    func getschedulesobject() -> Schedules? {
        return self.schedules
    }

    func createschedulesobject(profile: String?) -> Schedules? {
        self.schedules = nil
        self.schedules = Schedules(profile: profile)
        return self.schedules
    }
}

extension  ViewControllertabMain: GetHiddenID {
    func gethiddenID() -> Int? {
        return self.hiddenID
    }
}

extension ViewControllertabMain: Setinfoaboutrsync {
    internal func setinfoaboutrsync() {
        if ViewControllerReference.shared.norsync == true {
            self.info(num: 3)
        } else {
            self.info(num: 0)
        }
    }
}

extension ViewControllertabMain: ErrorOutput {
    func erroroutput() {
        self.info(num: 2)
    }
}

extension ViewControllertabMain: Createandreloadconfigurations {
    // func reateandreloadconfigurations()
}

extension ViewControllertabMain: SendProcessreference {
    func sendoutputprocessreference(outputprocess: OutputProcess?) {
        self.outputprocess = outputprocess
    }

    func sendprocessreference(process: Process?) {
        self.process = process
    }
}

extension ViewControllertabMain: SetRemoteInfo {
    func getremoteinfo() -> RemoteInfoTaskWorkQueue? {
        return self.configurations!.remoteinfotaskworkqueue
    }

    func setremoteinfo(remoteinfotask: RemoteInfoTaskWorkQueue?) {
        self.configurations!.remoteinfotaskworkqueue = remoteinfotask
    }
}

extension ViewControllertabMain: OpenQuickBackup {
    func openquickbackup() {
        self.configurations!.processtermination = .quicktask
        globalMainQueue.async(execute: { () -> Void in
            self.presentAsSheet(self.viewControllerQuickBackup!)
        })
    }
}

extension ViewControllertabMain: Count {
    func maxCount() -> Int {
        guard self.outputprocess != nil else { return 0 }
        return self.outputprocess!.getMaxcount()
    }

    func inprogressCount() -> Int {
        guard self.outputprocess != nil else { return 0 }
        return self.outputprocess!.count()
    }
}

extension ViewControllertabMain: Reloadsortedandrefresh {
    func reloadsortedandrefreshtabledata() {
        globalMainQueue.async(execute: { () -> Void in
            self.mainTableView.reloadData()
        })
    }
}

extension ViewControllertabMain: SetLocalRemoteInfo {
    func getlocalremoteinfo(index: Int) -> NSMutableDictionary? {
        guard self.configurations?.localremote != nil else { return nil }
        if let info = self.configurations?.localremote?.filter({($0.value(forKey: "index") as? Int)! == index}) {
            guard info.count > 0 else { return nil }
            return info[0]
        } else {
            return nil
        }
    }

    func setlocalremoteinfo(info: NSMutableDictionary?) {
        guard info != nil else { return }
        if self.configurations?.localremote == nil {
            self.configurations?.localremote = [NSMutableDictionary]()
            self.configurations?.localremote!.append(info!)
        } else {
            self.configurations?.localremote!.append(info!)
        }
    }
}

extension ViewControllertabMain: Allerrors {
    func allerrors(outputprocess: OutputProcess?) {
        globalMainQueue.async(execute: { () -> Void in
            self.seterrorinfo(info: "Error")
        })
        self.outputprocess = nil
        if self.outputerrors == nil {
            self.outputerrors = OutputErrors()
        }
        guard outputprocess?.getOutput() != nil else { return }
        for i in 0 ..< outputprocess!.getOutput()!.count {
            self.outputerrors!.addLine(str: outputprocess!.getOutput()![i])
        }
    }

    func getoutputerrors() -> OutputErrors? {
        return self.outputerrors
    }
}

extension ViewControllertabMain: ViewOutputDetails {

    func disableappend() {
        self.dynamicappend = false
    }

    func enableappend() {
        self.dynamicappend = true
    }

    func getalloutput() -> [String] {
        return self.outputprocess?.getrawOutput() ?? []
    }

    func reloadtable() {
        weak var localreloadDelegate: Reloadandrefresh?
        localreloadDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcalloutput) as? ViewControllerAllOutput
        localreloadDelegate?.reloadtabledata()
    }

    func appendnow() -> Bool {
        return self.dynamicappend
    }
}

extension ViewControllertabMain: ResetSequrityScopedURL {
    func resetsequrityscopedurl() {
        let permissionManager: PermissionManager = PermissionManager(bookmarksManager: BookmarksManager.defaultManager)
        permissionManager.bookmarksManager.clearSecurityScopedBookmarks()
    }
}

extension ViewControllertabMain: SaveSequrityScopedURL {
    func savesequrityscopedurl(urlpath: URL) {
        let permissionManager: PermissionManager = PermissionManager(bookmarksManager: BookmarksManager.defaultManager)
        permissionManager.bookmarksManager.saveSecurityScopedBookmarkForFileAtURL(securityScopedFileURL: urlpath)
    }
}

extension ViewControllertabMain: AllProfileDetails {
    func disablereloadallprofiles() {
        self.allprofilesview = false
    }

    func enablereloadallprofiles() {
        self.allprofilesview = true
        self.allprofiledetailsDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcallprofiles) as? ViewControllerAllProfiles
    }
}
