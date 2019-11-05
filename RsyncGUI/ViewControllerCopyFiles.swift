//
//  ViewControllerCopyFiles.swift
//  RsyncGUI
//
//  Created by Thomas Evensen on 12/09/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
//  swiftlint:disable line_length function_body_length file_length

import Foundation
import Cocoa

protocol GetSource: class {
    func getSourceindex(index: Int)
}

protocol Updateremotefilelist: class {
    func updateremotefilelist()
}

class ViewControllerCopyFiles: NSViewController, SetConfigurations, Delay, Connected, VcMain, Checkforrsync {

    var copyfiles: CopyFiles?
    var remotefilelist: Remotefilelist?
    var rsyncindex: Int?
    var estimated: Bool = false
    private var restoretabledata: [String]?
    var diddissappear: Bool = false
    var outputprocess: OutputProcess?
    private var maxcount: Int = 0

    @IBOutlet weak var numberofrows: NSTextField!
    @IBOutlet weak var server: NSTextField!
    @IBOutlet weak var rcatalog: NSTextField!
    @IBOutlet weak var info: NSTextField!
    @IBOutlet weak var restoretableView: NSTableView!
    @IBOutlet weak var rsynctableView: NSTableView!
    @IBOutlet weak var commandString: NSTextField!
    @IBOutlet weak var remoteCatalog: NSTextField!
    @IBOutlet weak var restorecatalog: NSTextField!
    @IBOutlet weak var working: NSProgressIndicator!
    @IBOutlet weak var search: NSSearchField!
    @IBOutlet weak var restorebutton: NSButton!

    @IBAction func totinfo(_ sender: NSButton) {
        guard self.checkforrsync() == false else { return }
        globalMainQueue.async(execute: { () -> Void in
            self.presentAsSheet(self.viewControllerRemoteInfo!)
        })
    }

    @IBAction func quickbackup(_ sender: NSButton) {
        guard self.checkforrsync() == false else { return }
        self.openquickbackup()
    }

    @IBAction func automaticbackup(_ sender: NSButton) {
        self.presentAsSheet(self.viewControllerEstimating!)
    }

    // Selecting profiles
    @IBAction func profiles(_ sender: NSButton) {
        globalMainQueue.async(execute: { () -> Void in
            self.presentAsSheet(self.viewControllerProfile!)
        })
    }

    // Userconfiguration button
    @IBAction func userconfiguration(_ sender: NSButton) {
        globalMainQueue.async(execute: { () -> Void in
            self.presentAsSheet(self.viewControllerUserconfiguration!)
        })
    }

    // Abort button
    @IBAction func abort(_ sender: NSButton) {
        self.working.stopAnimation(nil)
        guard self.copyfiles != nil else { return }
        self.restorebutton.isEnabled = true
        self.copyfiles!.abort()
    }

    private func info(num: Int) {
        switch num {
        case 1:
            self.info.stringValue = "No such local catalog for restore or set it in user config..."
        case 2:
            self.info.stringValue = "Not a remote task, use Finder to copy files..."
        case 3:
            self.info.stringValue = "Local or remote catalog cannot be empty..."
        case 4:
            self.info.stringValue = "Seems not to be connected..."
        default:
            self.info.stringValue = ""
        }
    }

    // Do the work
    @IBAction func restore(_ sender: NSButton) {
        guard self.remoteCatalog.stringValue.isEmpty == false && self.restorecatalog.stringValue.isEmpty == false else {
            self.info(num: 3)
            return
        }
        guard self.copyfiles != nil else { return }
        self.restorebutton.isEnabled = false
        if self.estimated == false {
            self.working.startAnimation(nil)
            self.copyfiles!.executecopyfiles(remotefile: self.remoteCatalog!.stringValue, localCatalog: self.restorecatalog!.stringValue, dryrun: true, updateprogress: self)
            self.estimated = true
            self.outputprocess = self.copyfiles?.outputprocess
        } else {
            self.presentAsSheet(self.viewControllerProgress!)
            self.copyfiles!.executecopyfiles(remotefile: self.remoteCatalog!.stringValue, localCatalog: self.restorecatalog!.stringValue, dryrun: false, updateprogress: self)
            self.estimated = false
        }
    }

    private func displayRemoteserver(index: Int?) {
        guard index != nil else {
            self.server.stringValue = ""
            self.rcatalog.stringValue = ""
            return
        }
        let hiddenID = self.configurations!.gethiddenID(index: index!)
        globalMainQueue.async(execute: { () -> Void in
            self.server.stringValue = self.configurations!.getResourceConfiguration(hiddenID: hiddenID, resource: .offsiteServer)
            self.rcatalog.stringValue = self.configurations!.getResourceConfiguration(hiddenID: hiddenID, resource: .offsiteCatalog)
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ViewControllerReference.shared.setvcref(viewcontroller: .vccopyfiles, nsviewcontroller: self)
        self.restoretableView.delegate = self
        self.restoretableView.dataSource = self
        self.rsynctableView.delegate = self
        self.rsynctableView.dataSource = self
        self.working.usesThreadedAnimation = true
        self.search.delegate = self
        self.restorecatalog.delegate = self
        self.remoteCatalog.delegate = self
        self.restoretableView.doubleAction = #selector(self.tableViewDoubleClick(sender:))
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        guard self.diddissappear == false else {
            globalMainQueue.async(execute: { () -> Void in
                self.rsynctableView.reloadData()
            })
            return
        }
        if let restorePath = ViewControllerReference.shared.restorePath {
            self.restorecatalog.stringValue = restorePath
        } else {
            self.restorecatalog.stringValue = ""
        }
        self.verifylocalCatalog()
        globalMainQueue.async(execute: { () -> Void in
            self.rsynctableView.reloadData()
        })
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.diddissappear = true
    }

    @objc(tableViewDoubleClick:) func tableViewDoubleClick(sender: AnyObject) {
        guard self.remoteCatalog.stringValue.isEmpty == false else { return }
        guard self.restorecatalog.stringValue.isEmpty == false else { return }
        let question: String = NSLocalizedString("Copy single files or directory?", comment: "Restore")
        let text: String = NSLocalizedString("Start restore?", comment: "Restore")
        let dialog: String = NSLocalizedString("Restore", comment: "Restore")
        let answer = Alerts.dialogOrCancel(question: question, text: text, dialog: dialog)
        if answer {
            self.restorebutton.isEnabled = false
            self.working.startAnimation(nil)
            self.copyfiles!.executecopyfiles(remotefile: remoteCatalog!.stringValue, localCatalog: restorecatalog!.stringValue, dryrun: false, updateprogress: self)
        }
    }

    private func verifylocalCatalog() {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: self.restorecatalog.stringValue) == false {
            self.info(num: 1)
        } else {
            self.info(num: 0)
        }
    }

    private func inprogress() -> Bool {
        guard self.copyfiles != nil else { return false }
        if self.copyfiles?.process != nil {
            return true
        } else {
            return false
        }
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let myTableViewFromNotification = (notification.object as? NSTableView)!
        if myTableViewFromNotification == self.restoretableView {
            self.info(num: 0)
            let indexes = myTableViewFromNotification.selectedRowIndexes
            if let index = indexes.first {
                guard self.restoretabledata != nil else { return }
                self.remoteCatalog.stringValue = self.restoretabledata![index]
                guard self.remoteCatalog.stringValue.isEmpty == false && self.restorecatalog.stringValue.isEmpty == false else {
                    self.info(num: 3)
                    return
                }
                self.commandString.stringValue = self.copyfiles!.getCommandDisplayinView(remotefile: self.remoteCatalog.stringValue, localCatalog: self.restorecatalog.stringValue)
                self.estimated = false
                self.restorebutton.title = "Estimate"
                self.restorebutton.isEnabled = true
            }
        } else {
            let indexes = myTableViewFromNotification.selectedRowIndexes
            self.commandString.stringValue = ""
            if let index = indexes.first {
                guard self.inprogress() == false else {
                    self.working.stopAnimation(nil)
                    guard self.copyfiles != nil else { return }
                    self.restorebutton.isEnabled = true
                    self.copyfiles!.abort()
                    return
                }
                let config = self.configurations!.getConfigurations()[index]
                guard self.connected(config: config) == true else {
                    self.restorebutton.isEnabled = false
                    self.info(num: 4)
                    return
                }
                self.info(num: 0)
                self.restorebutton.title = "Estimate"
                self.restorebutton.isEnabled = false
                self.remoteCatalog.stringValue = ""
                self.rsyncindex = index
                let hiddenID = self.configurations!.getConfigurationsDataSourceSynchronize()![index].value(forKey: "hiddenID") as? Int ?? -1
                self.copyfiles = CopyFiles(hiddenID: hiddenID)
                self.remotefilelist = Remotefilelist(hiddenID: hiddenID)
                self.working.startAnimation(nil)
                self.displayRemoteserver(index: index)
            } else {
                self.rsyncindex = nil
                self.restoretabledata = nil
                globalMainQueue.async(execute: { () -> Void in
                    self.restoretableView.reloadData()
                })
            }
        }
    }
}

extension ViewControllerCopyFiles: NSSearchFieldDelegate {

    func controlTextDidChange(_ notification: Notification) {
        if (notification.object as? NSTextField)! == self.search {
            self.delayWithSeconds(0.25) {
                if self.search.stringValue.isEmpty {
                    globalMainQueue.async(execute: { () -> Void in
                        if let index = self.rsyncindex {
                            if let hiddenID = self.configurations!.getConfigurationsDataSourceSynchronize()![index].value(forKey: "hiddenID") as? Int {
                                self.remotefilelist = Remotefilelist(hiddenID: hiddenID)
                            }
                        }
                    })
                } else {
                    globalMainQueue.async(execute: { () -> Void in
                        self.restoretabledata = self.restoretabledata!.filter({$0.contains(self.search.stringValue)})
                        self.restoretableView.reloadData()
                    })
                }
            }
            self.verifylocalCatalog()
        } else {
            self.delayWithSeconds(0.25) {
                self.verifylocalCatalog()
                self.restorebutton.title = "Estimate"
                self.restorebutton.isEnabled = true
                self.estimated = false
                guard self.remoteCatalog.stringValue.count > 0 else { return }
                self.commandString.stringValue = self.copyfiles?.getCommandDisplayinView(remotefile: self.remoteCatalog.stringValue, localCatalog: self.restorecatalog.stringValue) ?? ""
            }
        }
    }

    func searchFieldDidEndSearching(_ sender: NSSearchField) {
        if let index = self.rsyncindex {
            if self.configurations!.getConfigurationsDataSourceSynchronize()![index].value(forKey: "hiddenID") as? Int != nil {
                self.working.startAnimation(nil)
            }
        }
    }
}

extension ViewControllerCopyFiles: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == self.restoretableView {
            let numberofrows: String = NSLocalizedString("Number remote files:", comment: "Copy files")
            guard self.restoretabledata != nil else {
                self.numberofrows.stringValue = numberofrows
                return 0
            }
            self.numberofrows.stringValue = numberofrows + String(self.restoretabledata!.count)
            return self.restoretabledata!.count
        } else {
            return self.configurations?.getConfigurationsDataSourceSynchronize()?.count ?? 0
        }
    }
}

extension ViewControllerCopyFiles: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView == self.restoretableView {
            guard self.restoretabledata != nil else { return nil }
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "files"), owner: self) as? NSTableCellView {
                cell.textField?.stringValue = self.restoretabledata?[row] ?? ""
                return cell
            }
        } else {
            guard row < self.configurations!.getConfigurationsDataSourceSynchronize()!.count else { return nil }
            let object: NSDictionary = self.configurations!.getConfigurationsDataSourceSynchronize()![row]
            let cellIdentifier: String = tableColumn!.identifier.rawValue
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: self) as? NSTableCellView {
                cell.textField?.stringValue = object.value(forKey: cellIdentifier) as? String ?? ""
                return cell
            }
        }
        return nil
    }
}

extension ViewControllerCopyFiles: UpdateProgress {
    func processTermination() {
        self.maxcount = self.outputprocess?.getMaxcount() ?? 0
        if let vc = ViewControllerReference.shared.getvcref(viewcontroller: .vcprogressview) as? ViewControllerProgressProcess {
            vc.processTermination()
            self.restorebutton.isEnabled = false
            self.restorebutton.title = "Estimate"
        } else {
            self.restorebutton.title = "Restore"
            self.restorebutton.isEnabled = true
        }
        self.working.stopAnimation(nil)
    }

    func fileHandler() {
        if let vc = ViewControllerReference.shared.getvcref(viewcontroller: .vcprogressview) as? ViewControllerProgressProcess {
            vc.fileHandler()
        }
    }
}

extension ViewControllerCopyFiles: Count {
    func maxCount() -> Int {
        return self.maxcount
    }

    func inprogressCount() -> Int {
        guard self.copyfiles?.outputprocess != nil else { return 0 }
        return self.copyfiles!.outputprocess!.count()
    }
}

extension ViewControllerCopyFiles: DismissViewController {
    func dismiss_view(viewcontroller: NSViewController) {
        self.dismiss(viewcontroller)
    }
}

extension ViewControllerCopyFiles: TemporaryRestorePath {
    func temporaryrestorepath() {
        if let restorePath = ViewControllerReference.shared.restorePath {
            self.restorecatalog.stringValue = restorePath
        } else {
            self.restorecatalog.stringValue = ""
        }
        self.verifylocalCatalog()
    }
}

extension ViewControllerCopyFiles: NewProfile {
    func newProfile(profile: String?) {
        self.restoretabledata  = nil
        globalMainQueue.async(execute: { () -> Void in
            self.restoretableView.reloadData()
        })
    }

    func enableselectprofile() {
        //
    }
}

extension ViewControllerCopyFiles: OpenQuickBackup {
    func openquickbackup() {
        globalMainQueue.async(execute: { () -> Void in
            self.presentAsSheet(self.viewControllerQuickBackup!)
        })
    }
}

extension ViewControllerCopyFiles: Updateremotefilelist {
    func updateremotefilelist() {
        self.restoretabledata = self.remotefilelist?.remotefilelist
        globalMainQueue.async(execute: { () -> Void in
            self.restoretableView.reloadData()
        })
        self.working.stopAnimation(nil)
        self.remotefilelist = nil
    }
}
