//
//  ViewControllerProfile.swift
//  RsyncGUI
//
//  Created by Thomas Evensen on 17/10/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
//  swiftlint:disable line_length

import Foundation
import Cocoa

// Protocol for adding new profiles
protocol NewProfile: class {
    func newProfile(profile: String?)
    func enableProfileMenu()
}

class ViewControllerProfile: NSViewController, SetConfigurations, SetDismisser, Delay {

    var storageapi: PersistentStorageAPI?
    weak var newProfileDelegate: NewProfile?
    weak var snapshotnewProfileDelegate: NewProfile?
    weak var copyfilesnewProfileDelegate: NewProfile?
    private var profilesArray: [String]?
    private var profile: CatalogProfile?
    private var useprofile: String?

    @IBOutlet weak var loadbutton: NSButton!
    @IBOutlet weak var newprofile: NSTextField!
    @IBOutlet weak var profilesTable: NSTableView!

    @IBAction func defaultProfile(_ sender: NSButton) {
        self.useprofile = nil
        self.newProfileDelegate?.newProfile(profile: self.useprofile)
        self.snapshotnewProfileDelegate?.newProfile(profile: nil)
        self.copyfilesnewProfileDelegate?.newProfile(profile: nil)
        self.dismissView()
    }

    @IBAction func deleteProfile(_ sender: NSButton) {
        if let useprofile = self.useprofile {
            self.profile?.deleteProfile(profileName: useprofile)
            self.newProfileDelegate?.newProfile(profile: nil)
            self.snapshotnewProfileDelegate?.newProfile(profile: nil)
            self.copyfilesnewProfileDelegate?.newProfile(profile: nil)
        }
        self.dismissView()
    }

    // Use profile or close
    @IBAction func close(_ sender: NSButton) {
        let newprofile = self.newprofile.stringValue
        guard newprofile.isEmpty == false else {
            self.newProfileDelegate?.newProfile(profile: self.useprofile)
            self.snapshotnewProfileDelegate?.newProfile(profile: nil)
            self.copyfilesnewProfileDelegate?.newProfile(profile: nil)
            self.dismissView()
            return
        }
        let success = self.profile?.createProfile(profileName: newprofile)
        guard success == true else {
            self.dismissView()
            return
        }
        self.newProfileDelegate?.newProfile(profile: newprofile)
        self.snapshotnewProfileDelegate?.newProfile(profile: nil)
        self.copyfilesnewProfileDelegate?.newProfile(profile: nil)
        self.dismissView()
    }

    private func dismissView() {
        self.dismissview(viewcontroller: self, vcontroller: .vctabmain)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.profilesTable.delegate = self
        self.profilesTable.dataSource = self
        self.profilesTable.target = self
        self.newprofile.delegate = self
        self.profilesTable.doubleAction = #selector(ViewControllerProfile.tableViewDoubleClick(sender:))
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.profile = nil
        self.profile = CatalogProfile()
        self.profilesArray = self.profile!.getDirectorysStrings()
        self.newProfileDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllertabMain
        self.snapshotnewProfileDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcsnapshot) as? ViewControllerSnapshots
        self.copyfilesnewProfileDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vccopyfiles) as? ViewControllerCopyFiles
        globalMainQueue.async(execute: { () -> Void in
            self.profilesTable.reloadData()
        })
        self.newprofile.stringValue = ""
    }

    @objc(tableViewDoubleClick:) func tableViewDoubleClick(sender: AnyObject) {
        self.newProfileDelegate?.newProfile(profile: self.useprofile)
        self.snapshotnewProfileDelegate?.newProfile(profile: nil)
        self.copyfilesnewProfileDelegate?.newProfile(profile: nil)
        self.dismissView()
    }
}

extension ViewControllerProfile: NSTableViewDataSource {

    func numberOfRows(in tableViewMaster: NSTableView) -> Int {
        return self.profilesArray?.count ?? 0
    }
}

extension ViewControllerProfile: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var text: String?
        var cellIdentifier: String = ""
        let data = self.profilesArray![row]
        if tableColumn == tableView.tableColumns[0] {
            text = data
            cellIdentifier = "profilesID"
        }
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier),
                         owner: self) as? NSTableCellView {
            cell.textField?.stringValue = text!
            return cell
        }
        return nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let myTableViewFromNotification = (notification.object as? NSTableView)!
        let indexes = myTableViewFromNotification.selectedRowIndexes
        if let index = indexes.first {
            self.useprofile = self.profilesArray![index]
        }
    }
}

extension ViewControllerProfile: NSTextFieldDelegate {
    func controlTextDidBeginEditing(_ notification: Notification) {
        self.delayWithSeconds(0.5) {
            if self.newprofile.stringValue.count > 0 {
                self.loadbutton.title = "Save"
            } else {
                self.loadbutton.title = "Load"
            }
        }
    }
}
