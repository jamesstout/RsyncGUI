//
//  ViewControllerSource.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 31/08/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//

import Cocoa
import Foundation

class ViewControllerSource: NSViewController, SetConfigurations {
    @IBOutlet var mainTableView: NSTableView!

    weak var getSourceDelegateSsh: ViewControllerSsh?
    private var index: Int?

    @IBAction func closeview(_: NSButton) {
        self.view.window?.close()
    }

    private func select() {
        if let pvc = ViewControllerReference.shared.getvcref(viewcontroller: .vcssh) as? ViewControllerSsh {
            self.getSourceDelegateSsh = pvc
            if let index = self.index {
                self.getSourceDelegateSsh?.getSourceindex(index: index)
            }
        }
    }

    @IBAction func select(_: NSButton) {
        self.select()
        self.view.window?.close()
    }

    // Initial functions viewDidLoad and viewDidAppear
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mainTableView.delegate = self
        self.mainTableView.dataSource = self
        self.mainTableView.doubleAction = #selector(ViewControllerSource.tableViewDoubleClick(sender:))
    }

    override func viewDidAppear() {
        globalMainQueue.async { () -> Void in
            self.mainTableView.reloadData()
        }
    }

    @objc(tableViewDoubleClick:) func tableViewDoubleClick(sender _: AnyObject) {
        self.select()
        self.view.window?.close()
    }

    // when row is selected, setting which table row is selected
    func tableViewSelectionDidChange(_ notification: Notification) {
        let myTableViewFromNotification = (notification.object as? NSTableView)!
        let indexes = myTableViewFromNotification.selectedRowIndexes
        if let index = indexes.first {
            if let object = ConfigurationsAsDictionarys().uniqueserversandlogins()?[index] {
                if let hiddenID = object.value(forKey: DictionaryStrings.hiddenID.rawValue) as? Int {
                    self.index = hiddenID
                }
            }
        }
    }
}

extension ViewControllerSource: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        return ConfigurationsAsDictionarys().uniqueserversandlogins()?.count ?? 0
    }
}

extension ViewControllerSource: NSTableViewDelegate {
    func tableView(_: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if let object: NSDictionary = ConfigurationsAsDictionarys().uniqueserversandlogins()?[row],
           let tableColumn = tableColumn
        {
            return object[tableColumn.identifier] as? String
        }
        return nil
    }
}
