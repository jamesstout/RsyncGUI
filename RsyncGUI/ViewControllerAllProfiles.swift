//
//  ViewControllerAllProfiles.swift
//  RsyncGUI
//
//  Created by Thomas Evensen on 07.03.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation
import Cocoa

protocol ReloadTableAllProfiles: class {
    func reloadtable()
}

class ViewControllerAllProfiles: NSViewController, Delay, Abort {

    // Main tableview
    @IBOutlet weak var mainTableView: NSTableView!
    @IBOutlet weak var search: NSSearchField!
    @IBOutlet weak var sortdirection: NSButton!
    @IBOutlet weak var numberOfprofiles: NSTextField!
    @IBOutlet weak var working: NSProgressIndicator!

    private var allprofiles: AllConfigurations?
    private var allschedules: Allschedules?
    private var column: Int?
    private var filterby: Sortandfilter?
    private var sortascending: Bool = true
    private var index: Int?
    private var outputprocess: OutputProcess?
    private var process: Process?

    weak var allprofiledetailsdelegata: AllProfileDetails?

    @IBAction func abort(_ sender: NSButton) {
        self.process?.terminate()
        self.process = nil
    }

    @IBAction func sortdirection(_ sender: NSButton) {
        if self.sortascending == true {
            self.sortascending = false
            self.sortdirection.image = #imageLiteral(resourceName: "down")
        } else {
            self.sortascending = true
            self.sortdirection.image = #imageLiteral(resourceName: "up")
        }
        guard self.filterby != nil else { return }
        switch self.filterby! {
        case .executedate:
            self.allprofiles?.allconfigurationsasdictionary = self.allprofiles!.sortbydate(notsorted: self.allprofiles?.allconfigurationsasdictionary, sortdirection: self.sortascending)
        default:
            self.allprofiles?.allconfigurationsasdictionary = self.allprofiles!.sortbystring(notsortedlist: self.allprofiles?.allconfigurationsasdictionary, sortby: self.filterby!, sortdirection: self.sortascending)
        }
        globalMainQueue.async(execute: { () -> Void in
            self.mainTableView.reloadData()
        })
    }

    @IBAction func getremotesizes(_ sender: NSButton) {
        self.getremotesizes()
    }

    @IBAction func reload(_ sender: NSButton) {
        self.reloadallprofiles()
    }

    private func getremotesizes() {
        guard self.index != nil else { return }
        guard self.process == nil else { return }
        self.outputprocess = OutputProcess()
        let dict = self.allprofiles!.allconfigurationsasdictionary?[self.index!]
        let config = Configuration(dictionary: dict!)
        let duargs: DuArgumentsSsh = DuArgumentsSsh(config: config)
        guard duargs.getArguments() != nil || duargs.getCommand() != nil else { return }
        self.working.startAnimation(nil)
        let task: DuCommandSsh = DuCommandSsh(command: duargs.getCommand(), arguments: duargs.getArguments())
        task.setdelegate(object: self)
        task.executeProcess(outputprocess: self.outputprocess)
        self.process = task.getprocess()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.mainTableView.delegate = self
        self.mainTableView.dataSource = self
        self.search.delegate = self
        self.mainTableView.target = self
        self.mainTableView.doubleAction = #selector(ViewControllerProfile.tableViewDoubleClick(sender:))
        self.working.usesThreadedAnimation = true
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.reloadallprofiles()
        ViewControllerReference.shared.setvcref(viewcontroller: .vcallprofiles, nsviewcontroller: self)
        self.allprofiledetailsdelegata = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllerMain
        self.allprofiledetailsdelegata?.enablereloadallprofiles()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.allprofiledetailsdelegata?.disablereloadallprofiles()
        self.allprofiles = nil
        self.allschedules = nil
    }

    func reloadallprofiles() {
        self.allprofiles = AllConfigurations()
        self.allschedules = Allschedules(nolog: true)
        self.sortdirection.image = #imageLiteral(resourceName: "up")
        self.sortascending = true
        self.allprofiles?.allconfigurationsasdictionary = self.allprofiles!.sortbydate(notsorted: self.allprofiles?.allconfigurationsasdictionary, sortdirection: self.sortascending)
        globalMainQueue.async(execute: { () -> Void in
            self.mainTableView.reloadData()
        })
    }

    @objc(tableViewDoubleClick:) func tableViewDoubleClick(sender: AnyObject) {
        self.getremotesizes()
    }
}

extension ViewControllerAllProfiles: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if self.allprofiles?.allconfigurationsasdictionary == nil {
            self.numberOfprofiles.stringValue = "Number of configurations:"
            return 0
        } else {
            self.numberOfprofiles.stringValue = "Number of configurations: " +
                String(self.allprofiles!.allconfigurationsasdictionary?.count ?? 0)
            return self.allprofiles!.allconfigurationsasdictionary?.count ?? 0
        }
    }
}

extension ViewControllerAllProfiles: NSTableViewDelegate, Attributedestring {

    // TableView delegates
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if row > self.allprofiles!.allconfigurationsasdictionary!.count - 1 { return nil }
        let object: NSDictionary = self.allprofiles!.allconfigurationsasdictionary![row]
        return object[tableColumn!.identifier] as? String
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
            self.filterby = .remotecatalog
        case 6:
            self.filterby = .remoteserver
        case 10, 11:
            sortbystring = false
            self.filterby = .executedate
        default:
            return
        }
        if sortbystring {
            self.allprofiles?.allconfigurationsasdictionary = self.allprofiles!.sortbystring(notsortedlist: self.allprofiles?.allconfigurationsasdictionary, sortby: self.filterby!, sortdirection: self.sortascending)
        } else {
            self.allprofiles?.allconfigurationsasdictionary = self.allprofiles!.sortbydate(notsorted: self.allprofiles?.allconfigurationsasdictionary, sortdirection: self.sortascending)
        }
        globalMainQueue.async(execute: { () -> Void in
            self.mainTableView.reloadData()
        })
    }
}

extension ViewControllerAllProfiles: NSSearchFieldDelegate {

    func controlTextDidBeginEditing(_ obj: Notification) {
        self.delayWithSeconds(0.25) {
            guard self.column != nil else { return }
            let filterstring = self.search.stringValue
            if filterstring.isEmpty {
                globalMainQueue.async(execute: { () -> Void in
                    self.allprofiles = AllConfigurations()
                    self.mainTableView.reloadData()
                })
            } else {
                globalMainQueue.async(execute: { () -> Void in
                    self.allprofiles?.filter(search: filterstring, column: self.column!, filterby: self.filterby)
                    self.mainTableView.reloadData()
                })
            }
        }
    }

    func searchFieldDidEndSearching(_ sender: NSSearchField) {
        globalMainQueue.async(execute: { () -> Void in
            self.allprofiles = AllConfigurations()
            self.mainTableView.reloadData()
        })
    }
}

extension ViewControllerAllProfiles: UpdateProgress {
    func processTermination() {
        self.working.stopAnimation(nil)
        guard self.process != nil else { return }
        self.process = nil
        let numbers = RemoteNumbers(outputprocess: self.outputprocess)
        self.allprofiles!.allconfigurationsasdictionary?[self.index!].setValue(numbers.getused(), forKey: "used")
        self.allprofiles!.allconfigurationsasdictionary?[self.index!].setValue(numbers.getavail(), forKey: "avail")
        self.allprofiles!.allconfigurationsasdictionary?[self.index!].setValue(numbers.getpercentavaliable(), forKey: "availpercent")
        globalMainQueue.async(execute: { () -> Void in
            self.mainTableView.reloadData()
        })
    }

    func fileHandler() {
        //
    }
}

extension ViewControllerAllProfiles: ReloadTableAllProfiles {
    func reloadtable() {
        self.reloadallprofiles()
    }
}
