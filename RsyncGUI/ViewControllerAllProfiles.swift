//
//  ViewControllerAllProfiles.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 07.03.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

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

    var allprofiles: AllConfigurations?
    var allschedules: Allschedules?
    var column: Int?
    var filterby: Sortandfilter?
    var sortascending: Bool = true
    var index: Int?
    var outputprocess: OutputProcess?

    var command: OtherProcessCmdClosure?

    @IBAction func abort(_: NSButton) {
        _ = InterruptProcess()
    }

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
        switch self.filterby ?? .localcatalog {
        case .executedate:
            self.allprofiles?.allconfigurationsasdictionary =
                self.allprofiles?.sortbydate(notsortedlist: self.allprofiles?.allconfigurationsasdictionary,
                                             sortdirection: self.sortascending)
        default:
            self.allprofiles?.allconfigurationsasdictionary =
                self.allprofiles?.sortbystring(notsortedlist: self.allprofiles?.allconfigurationsasdictionary,
                                               sortby: self.filterby ?? .localcatalog, sortdirection: self.sortascending)
        }
        globalMainQueue.async { () -> Void in
            self.mainTableView.reloadData()
        }
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
        self.reloadallprofiles()
        self.initpopupbutton()
        ViewControllerReference.shared.setvcref(viewcontroller: .vcallprofiles, nsviewcontroller: self)
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        ViewControllerReference.shared.setvcref(viewcontroller: .vcallprofiles, nsviewcontroller: nil)
    }

    func reloadallprofiles() {
        self.allprofiles = AllConfigurations()
        self.allschedules = Allschedules(includelog: false)
        self.sortdirection.image = #imageLiteral(resourceName: "up")
        self.sortascending = true
        self.allprofiles?.allconfigurationsasdictionary = self.allprofiles!.sortbydate(notsortedlist: self.allprofiles?.allconfigurationsasdictionary, sortdirection: self.sortascending)
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
}

extension ViewControllerAllProfiles: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        self.numberOfprofiles.stringValue = NSLocalizedString("Number of configurations:", comment: "AllProfiles") + " " +
            String(self.allprofiles?.allconfigurationsasdictionary?.count ?? 0)
        return self.allprofiles?.allconfigurationsasdictionary?.count ?? 0
    }
}

extension ViewControllerAllProfiles: NSTableViewDelegate, Attributedestring {
    // TableView delegates
    func tableView(_: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if let tableColumn = tableColumn {
            if row > (self.allprofiles?.allconfigurationsasdictionary?.count ?? 0) - 1 { return nil }
            if let object: NSDictionary = self.allprofiles?.allconfigurationsasdictionary?[row] {
                let hiddenID = object.value(forKey: DictionaryStrings.hiddenID.rawValue) as? Int ?? -1
                let profile = object.value(forKey: DictionaryStrings.profile.rawValue) as? String ?? NSLocalizedString("Default profile", comment: "default profile")
                if tableColumn.identifier.rawValue == "intime" {
                    let taskintime: String? = ""
                    return taskintime ?? ""
                } else if tableColumn.identifier.rawValue == DictionaryStrings.schedule.rawValue {
                    let schedule = ""
                    switch schedule {
                    case Scheduletype.once.rawValue:
                        return NSLocalizedString("once", comment: "main")
                    case Scheduletype.daily.rawValue:
                        return NSLocalizedString("daily", comment: "main")
                    case Scheduletype.weekly.rawValue:
                        return NSLocalizedString("weekly", comment: "main")
                    case Scheduletype.manuel.rawValue:
                        return NSLocalizedString("manuel", comment: "main")
                    default:
                        return ""
                    }
                } else {
                    return object[tableColumn.identifier] as? String
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
        var sortbystring = true
        self.column = column
        switch column {
        case 0:
            self.filterby = .profile
        case 3:
            self.filterby = .task
        case 4:
            self.filterby = .localcatalog
        case 5:
            self.filterby = .offsitecatalog
        case 6:
            self.filterby = .offsiteserver
        case 7, 8:
            sortbystring = false
            self.filterby = .executedate
        default:
            return
        }
        if sortbystring {
            self.allprofiles?.allconfigurationsasdictionary =
                self.allprofiles?.sortbystring(notsortedlist: self.allprofiles?.allconfigurationsasdictionary,
                                               sortby: self.filterby!, sortdirection: self.sortascending)
        } else {
            self.allprofiles?.allconfigurationsasdictionary =
                self.allprofiles?.sortbydate(notsortedlist: self.allprofiles?.allconfigurationsasdictionary,
                                             sortdirection: self.sortascending)
        }
        globalMainQueue.async { () -> Void in
            self.mainTableView.reloadData()
        }
    }
}

extension ViewControllerAllProfiles: NSSearchFieldDelegate {
    func controlTextDidChange(_: Notification) {
        self.delayWithSeconds(0.25) {
            guard self.column != nil else { return }
            let filterstring = self.search.stringValue
            if filterstring.isEmpty {
                globalMainQueue.async { () -> Void in
                    self.allprofiles = AllConfigurations()
                    self.mainTableView.reloadData()
                }
            } else {
                globalMainQueue.async { () -> Void in
                    self.allprofiles?.filter(search: filterstring, filterby: self.filterby)
                    self.mainTableView.reloadData()
                }
            }
        }
    }

    func searchFieldDidEndSearching(_: NSSearchField) {
        globalMainQueue.async { () -> Void in
            self.allprofiles = AllConfigurations()
            self.mainTableView.reloadData()
        }
    }
}

extension ViewControllerAllProfiles: ReloadTableAllProfiles {
    func reloadtable() {
        self.reloadallprofiles()
    }
}
