//
//  ViewControllerAllOutput.swift
//  RsyncGUI
//
//  Created by Thomas Evensen on 10.08.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//
//  swiftlint:disable line_length

import Cocoa
import Foundation

class ViewControllerAllOutput: NSViewController, Delay {
    @IBOutlet var outputtable: NSTableView!
    weak var getoutputDelegate: ViewOutputDetails?
    var logging: Logging?
    @IBOutlet var rsyncorlog: NSSwitch!
    @IBOutlet var outputrsyncorlofile: NSTextField!

    @IBAction func rsyncorlogfile(_: NSButton) {
        if self.rsyncorlog.state == .on {
            self.outputrsyncorlofile.stringValue = "Rsync output..."
            self.getoutputDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllerMain
        } else {
            self.outputrsyncorlofile.stringValue = "Logfile..."
            self.logging = Logging()
            self.getoutputDelegate = self.logging
        }
        globalMainQueue.async { () -> Void in
            self.outputtable.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ViewControllerReference.shared.setvcref(viewcontroller: .vcalloutput, nsviewcontroller: self)
        self.getoutputDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllerMain
        self.outputtable.delegate = self
        self.outputtable.dataSource = self
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        globalMainQueue.async { () -> Void in
            self.outputtable.reloadData()
        }
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        ViewControllerReference.shared.setvcref(viewcontroller: .vcalloutput, nsviewcontroller: nil)
    }

    @IBAction func pastetabeltomacospasteboard(_: NSButton) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        for i in 0 ..< (self.getoutputDelegate?.getalloutput().count ?? 0) {
            pasteboard.writeObjects([(self.getoutputDelegate?.getalloutput()[i])! as NSPasteboardWriting])
        }
    }

    @IBAction func newcleanlogfile(_: NSButton) {
        self.outputrsyncorlofile.stringValue = "Logfile..."
        self.rsyncorlog.state = .off
        self.logging = Logging(nil, false)
        self.getoutputDelegate = self.logging
        globalMainQueue.async { () -> Void in
            self.outputtable.reloadData()
        }
    }
}

extension ViewControllerAllOutput: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        return self.getoutputDelegate?.getalloutput().count ?? 0
    }
}

extension ViewControllerAllOutput: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "outputID"), owner: nil) as? NSTableCellView {
            guard row < self.getoutputDelegate?.getalloutput().count ?? 0 else { return nil }
            cell.textField?.stringValue = self.getoutputDelegate?.getalloutput()[row] ?? ""
            return cell
        } else {
            return nil
        }
    }
}

extension ViewControllerAllOutput: Reloadandrefresh {
    func reloadtabledata() {
        globalMainQueue.async { () -> Void in
            self.outputtable.reloadData()
        }
    }
}
