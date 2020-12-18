//
//  ViewControllerAllProfiles.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 07.03.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length cyclomatic_complexity

import Cocoa
import Foundation

protocol ReloadTableAllProfiles: AnyObject {
    func reloadtable()
}

class ViewControllerAllProfiles: NSViewController, Delay, Abort, Connected {
    // Main tableview
    @IBOutlet var mainTableView: NSTableView!
    @IBOutlet var search: NSSearchField!
    @IBOutlet var sortdirection: NSButton!
    @IBOutlet var numberOfprofiles: NSTextField!
    @IBOutlet var profilepopupbutton: NSPopUpButton!

    var allconfigurations: AllConfigurations?
    var allschedules: Allschedules?
    var column: Int?
    var filterby: Sortandfilter?
    var sortascending: Bool = true
    var index: Int?
    var outputprocess: OutputProcess?

    var command: OtherProcessCmdClosure?

    @IBAction func closeview(_: NSButton) {
        self.view.window?.close()
    }

    @IBAction func sortdirection(_: NSButton) {
        if self.sortascending == true {
            self.sortascending = false
            self.sortdirection.image = #imageLiteral(resourceName: "down")
        } else {
            self.sortascending = true
            self.sortdirection.image = #imageLiteral(resourceName: "up")
        }
        self.sortbycolumn()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.mainTableView.delegate = self
        self.mainTableView.dataSource = self
        self.search.delegate = self
        self.mainTableView.target = self
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.sortdirection.image = #imageLiteral(resourceName: "up")
        self.sortascending = true
        self.initpopupbutton()
        ViewControllerReference.shared.setvcref(viewcontroller: .vcallprofiles, nsviewcontroller: self)
        self.allconfigurations = AllConfigurations()
        self.allschedules = Allschedules(includelog: false)
        globalMainQueue.async { () -> Void in
            self.mainTableView.reloadData()
        }
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        ViewControllerReference.shared.setvcref(viewcontroller: .vcallprofiles, nsviewcontroller: nil)
        self.allschedules = nil
        self.allconfigurations = nil
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
        self.view.window?.close()
    }

    func sortbycolumn() {
        var comp: (String, String) -> Bool
        if self.sortascending == true {
            comp = (<)
        } else {
            comp = (>)
        }
        switch self.column {
        case 0:
            self.allconfigurations?.allconfigurations = allconfigurations?.allconfigurations?.sorted(by: \.profile!, using: comp)
        case 1:
            self.allconfigurations?.allconfigurations = allconfigurations?.allconfigurations?.sorted(by: \.task, using: comp)
        case 2:
            self.allconfigurations?.allconfigurations = allconfigurations?.allconfigurations?.sorted(by: \.localCatalog, using: comp)
        case 3:
            self.allconfigurations?.allconfigurations = allconfigurations?.allconfigurations?.sorted(by: \.offsiteCatalog, using: comp)
        case 4:
            self.allconfigurations?.allconfigurations = allconfigurations?.allconfigurations?.sorted(by: \.offsiteServer, using: comp)
        default:
            return
        }
        globalMainQueue.async { () -> Void in
            self.mainTableView.reloadData()
        }
    }
}

extension ViewControllerAllProfiles: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        self.numberOfprofiles.stringValue = NSLocalizedString("Number of configurations:", comment: "AllProfiles") + " " +
            String(self.allconfigurations?.allconfigurations?.count ?? 0)
        return self.allconfigurations?.allconfigurations?.count ?? 0
    }
}

extension ViewControllerAllProfiles: NSTableViewDelegate, Attributedestring {
    // TableView delegates
    func tableView(_: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if let tableColumn = tableColumn {
            if row > (self.allconfigurations?.allconfigurations?.count ?? 0) - 1 { return nil }
            if let object = self.allconfigurations?.allconfigurations?[row] {
                switch tableColumn.identifier.rawValue {
                case "profile":
                    return object.profile ?? ""
                case "localCatalog":
                    return object.localCatalog
                case "offsiteCatalog":
                    return object.offsiteCatalog
                case "offsiteServer":
                    return object.offsiteServer
                case "daysID":
                    return object.dayssincelastbackup
                case "task":
                    return object.task
                case "dateExecuted":
                    return object.dateRun ?? ""
                default:
                    return nil
                }
            }
        }
        return nil
    }

    // setting which table row is selected
    func tableViewSelectionDidChange(_ notification: Notification) {
        let myTableViewFromNotification = (notification.object as? NSTableView)!
        let column = myTableViewFromNotification.selectedColumn
        let indexes = myTableViewFromNotification.selectedRowIndexes
        if let index = indexes.first {
            self.index = index
        } else {
            self.index = nil
        }
        self.column = column
        self.sortbycolumn()
    }
}

extension ViewControllerAllProfiles: NSSearchFieldDelegate {
    func controlTextDidChange(_: Notification) {
        self.delayWithSeconds(0.25) {
            if self.search.stringValue.isEmpty {
                globalMainQueue.async { () -> Void in
                    self.allconfigurations?.allconfigurations = AllConfigurations().allconfigurations
                    self.mainTableView.reloadData()
                }
            } else {
                globalMainQueue.async { () -> Void in
                    self.allconfigurations?.filter(search: self.search.stringValue)
                    self.mainTableView.reloadData()
                }
            }
        }
    }

    func searchFieldDidEndSearching(_: NSSearchField) {
        globalMainQueue.async { () -> Void in
            self.allconfigurations?.allconfigurations = AllConfigurations().allconfigurations
            self.mainTableView.reloadData()
        }
    }
}
