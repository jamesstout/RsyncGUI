//
//  ViewControllerLoggData.swift
//  RsyncOSX
//  The ViewController is the logview
//
//  Created by Thomas Evensen on 23/09/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Cocoa
import Foundation

class ViewControllerLoggData: NSViewController, SetConfigurations, SetSchedules, Delay, Index, Connected, VcMain, Checkforrsync, Setcolor, Help {
    private var scheduleloggdata: ScheduleLoggData?
    private var filterby: Sortandfilter?
    private var index: Int?
    private var sortedascending: Bool = true

    @IBOutlet var scheduletable: NSTableView!
    @IBOutlet var search: NSSearchField!
    @IBOutlet var numberOflogfiles: NSTextField!
    @IBOutlet var sortdirection: NSButton!
    @IBOutlet var selectedrows: NSTextField!
    @IBOutlet var info: NSTextField!
    @IBOutlet var working: NSProgressIndicator!
    @IBOutlet var selectbutton: NSButton!

    // Selecting profiles
    @IBAction func profiles(_: NSButton) {
        self.presentAsModalWindow(self.viewControllerProfile!)
    }

    @IBAction func showHelp(_: AnyObject?) {
        self.help()
    }

    @IBAction func sortdirection(_: NSButton) {
        if self.sortedascending == true {
            self.sortedascending = false
            self.sortdirection.image = #imageLiteral(resourceName: "down")
        } else {
            self.sortedascending = true
            self.sortdirection.image = #imageLiteral(resourceName: "up")
        }
        switch self.filterby ?? .localcatalog {
        case .executedate:
            self.scheduleloggdata?.loggdata = self.scheduleloggdata?.sortbydate(notsortedlist: self.scheduleloggdata?.loggdata, sortdirection: self.sortedascending)
        default:
            self.scheduleloggdata?.loggdata = self.scheduleloggdata?.sortbystring(notsortedlist: self.scheduleloggdata?.loggdata, sortby: self.filterby ?? .localcatalog, sortdirection: self.sortedascending)
        }
        globalMainQueue.async { () -> Void in
            self.scheduletable.reloadData()
        }
    }

    @IBAction func selectlogs(_: NSButton) {
        guard self.scheduleloggdata?.loggdata != nil else { return }
        for i in 0 ..< (self.scheduleloggdata?.loggdata?.count ?? 0) {
            if self.scheduleloggdata?.loggdata?[i].value(forKey: DictionaryStrings.deleteCellID.rawValue) as? Int == 1 {
                self.scheduleloggdata?.loggdata?[i].setValue(0, forKey: DictionaryStrings.deleteCellID.rawValue)
            } else {
                self.scheduleloggdata?.loggdata?[i].setValue(1, forKey: DictionaryStrings.deleteCellID.rawValue)
            }
        }
        globalMainQueue.async { () -> Void in
            self.selectedrows.stringValue = NSLocalizedString("Selected logs:", comment: "Logg") + " " + self.selectednumber()
            self.scheduletable.reloadData()
        }
    }

    @IBAction func deletealllogs(_: NSButton) {
        guard self.selectednumber() != "0" else { return }
        let question: String = NSLocalizedString("Delete", comment: "Logg")
        let text: String = NSLocalizedString("Cancel or Delete", comment: "Logg")
        let dialog: String = NSLocalizedString("Delete", comment: "Logg")
        let answer = Alerts.dialogOrCancel(question: question + " " + self.selectednumber() + " logrecords?", text: text, dialog: dialog)
        if answer {
            self.deselectrow()
            self.schedules?.deleteselectedrows(scheduleloggdata: self.scheduleloggdata)
        }
    }

    private func selectednumber() -> String {
        if let number = self.scheduleloggdata?.loggdata?.filter({ ($0.value(forKey: DictionaryStrings.deleteCellID.rawValue) as? Int) == 1 }).count {
            return String(number)
        } else {
            return "0"
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.scheduletable.delegate = self
        self.scheduletable.dataSource = self
        self.search.delegate = self
        ViewControllerReference.shared.setvcref(viewcontroller: .vcloggdata, nsviewcontroller: self)
        self.sortdirection.image = #imageLiteral(resourceName: "up")
        self.sortedascending = true
        self.working.usesThreadedAnimation = true
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.info.textColor = setcolor(nsviewcontroller: self, color: .green)
        self.index = self.index()
        if let index = self.index {
            let hiddenID = self.configurations?.gethiddenID(index: index) ?? -1
            guard hiddenID > -1 else { return }
            self.scheduleloggdata = ScheduleLoggData(hiddenID: hiddenID, sortascending: self.sortedascending)
            self.info.stringValue = Infologgdata().info(num: 1)
        } else {
            self.info.stringValue = Infologgdata().info(num: 0)
            self.scheduleloggdata = ScheduleLoggData(sortascending: self.sortedascending)
        }
        globalMainQueue.async { () -> Void in
            self.scheduletable.reloadData()
        }
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.scheduleloggdata = nil
        self.working.stopAnimation(nil)
        self.selectbutton.state = .off
    }

    private func deselectrow() {
        guard self.index != nil else { return }
        self.scheduletable.deselectRow(self.index!)
        self.index = self.index()
    }
}

extension ViewControllerLoggData: NSSearchFieldDelegate {
    func controlTextDidChange(_: Notification) {
        self.delayWithSeconds(0.25) {
            let filterstring = self.search.stringValue
            self.selectbutton.state = .off
            if filterstring.isEmpty {
                self.reloadtabledata()
            } else {
                self.scheduleloggdata?.filter(search: filterstring, filterby: self.filterby)
                globalMainQueue.async { () -> Void in
                    self.scheduletable.reloadData()
                }
            }
        }
    }

    func searchFieldDidEndSearching(_: NSSearchField) {
        self.index = nil
        self.reloadtabledata()
        self.selectbutton.state = .off
    }
}

extension ViewControllerLoggData: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        if self.scheduleloggdata == nil {
            self.numberOflogfiles.stringValue = NSLocalizedString("Number of logs:", comment: "Logg")
            self.selectedrows.stringValue = NSLocalizedString("Selected logs:", comment: "Logg") + " 0"
            return 0
        } else {
            self.numberOflogfiles.stringValue = NSLocalizedString("Number of logs:", comment: "Logg")
                + " " + String(self.scheduleloggdata?.loggdata?.count ?? 0)
            self.selectedrows.stringValue = NSLocalizedString("Selected logs:", comment: "Logg")
                + " " + self.selectednumber()
            return self.scheduleloggdata?.loggdata?.count ?? 0
        }
    }
}

extension ViewControllerLoggData: NSTableViewDelegate {
    func tableView(_: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if let tableColumn = tableColumn {
            guard row < self.scheduleloggdata?.loggdata?.count ?? -1 else { return nil }
            if let object: NSDictionary = self.scheduleloggdata?.loggdata?[row] {
                if tableColumn.identifier.rawValue == DictionaryStrings.deleteCellID.rawValue ||
                    tableColumn.identifier.rawValue == "snapCellID"
                {
                    return object[tableColumn.identifier] as? Int
                } else {
                    return object[tableColumn.identifier] as? String
                }
            }
            return nil
        }
        return nil
    }

    // setting which table row is selected
    func tableViewSelectionDidChange(_ notification: Notification) {
        let myTableViewFromNotification = (notification.object as? NSTableView)!
        let indexes = myTableViewFromNotification.selectedRowIndexes
        if let index = indexes.first {
            self.index = index
        }
        let column = myTableViewFromNotification.selectedColumn
        var sortbystring = true
        switch column {
        case 0:
            self.filterby = .task
        case 2:
            self.filterby = .backupid
        case 3:
            self.filterby = .localcatalog
        case 4:
            self.filterby = .offsitecatalog
        case 5:
            self.filterby = .offsiteserver
        case 6:
            sortbystring = false
            self.filterby = .executedate
        default:
            return
        }
        if sortbystring {
            self.scheduleloggdata?.loggdata = self.scheduleloggdata?.sortbystring(notsortedlist: self.scheduleloggdata?.loggdata, sortby: self.filterby, sortdirection: self.sortedascending)
        } else {
            self.scheduleloggdata?.loggdata = self.scheduleloggdata?.sortbydate(notsortedlist: self.scheduleloggdata?.loggdata, sortdirection: self.sortedascending)
        }
        globalMainQueue.async { () -> Void in
            self.scheduletable.reloadData()
        }
    }

    func tableView(_: NSTableView, setObjectValue _: Any?, for tableColumn: NSTableColumn?, row: Int) {
        if let tableColumn = tableColumn {
            if tableColumn.identifier.rawValue == DictionaryStrings.deleteCellID.rawValue {
                var delete: Int = (self.scheduleloggdata?.loggdata![row].value(forKey: DictionaryStrings.deleteCellID.rawValue) as? Int)!
                if delete == 0 { delete = 1 } else if delete == 1 { delete = 0 }
                switch tableColumn.identifier.rawValue {
                case DictionaryStrings.deleteCellID.rawValue:
                    self.scheduleloggdata?.loggdata?[row].setValue(delete, forKey: DictionaryStrings.deleteCellID.rawValue)
                default:
                    break
                }
                globalMainQueue.async { () -> Void in
                    self.selectedrows.stringValue = NSLocalizedString("Selected logs:", comment: "Logg") + " " + self.selectednumber()
                }
            }
        }
    }
}

extension ViewControllerLoggData: Reloadandrefresh {
    func reloadtabledata() {
        if let index = self.index {
            let hiddenID = self.configurations?.gethiddenID(index: index) ?? -1
            guard hiddenID > -1 else { return }
            self.scheduleloggdata = ScheduleLoggData(hiddenID: hiddenID, sortascending: self.sortedascending)
        } else {
            self.scheduleloggdata = ScheduleLoggData(sortascending: self.sortedascending)
        }
        globalMainQueue.async { () -> Void in
            self.scheduletable.reloadData()
        }
    }
}

extension ViewControllerLoggData {
    func processtermination() {
        self.working.stopAnimation(nil)
        globalMainQueue.async { () -> Void in
            self.scheduletable.reloadData()
        }
    }

    func filehandler() {
        //
    }
}

extension ViewControllerLoggData: OpenQuickBackup {
    func openquickbackup() {
        globalMainQueue.async { () -> Void in
            self.presentAsSheet(self.viewControllerQuickBackup!)
        }
    }
}

extension ViewControllerLoggData: DismissViewController {
    func dismiss_view(viewcontroller: NSViewController) {
        self.dismiss(viewcontroller)
    }
}

extension ViewControllerLoggData: NewProfile {
    func newprofile(profile _: String?, selectedindex _: Int?) {
        self.reloadtabledata()
    }

    func reloadprofilepopupbutton() {
        //
    }
}
