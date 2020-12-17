//
//  ViewControllerQuickBackup.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 22.12.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Cocoa
import Foundation

protocol OpenQuickBackup: AnyObject {
    func openquickbackup()
}

class ViewControllerRemoteInfo: NSViewController, SetDismisser, Abort, Setcolor {
    @IBOutlet var mainTableView: NSTableView!
    @IBOutlet var progress: NSProgressIndicator!
    @IBOutlet var executebutton: NSButton!
    @IBOutlet var abortbutton: NSButton!
    @IBOutlet var count: NSTextField!

    private var remoteestimatedlist: RemoteinfoEstimation?
    weak var remoteinfotaskDelegate: SetRemoteInfo?
    var loaded: Bool = false
    var diddissappear: Bool = false

    @IBAction func execute(_: NSButton) {
        if (self.remoteestimatedlist?.estimatedlistandconfigs?.estimatedlist?.count ?? 0) > 0 {
            weak var openDelegate: OpenQuickBackup?
            if (self.presentingViewController as? ViewControllerMain) != nil {
                openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllerMain
            } else if (self.presentingViewController as? ViewControllerNewConfigurations) != nil {
                openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcnewconfigurations) as? ViewControllerNewConfigurations
            } else if (self.presentingViewController as? ViewControllerRestore) != nil {
                openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcrestore) as? ViewControllerRestore
            } else if (self.presentingViewController as? ViewControllerLoggData) != nil {
                openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcloggdata) as? ViewControllerLoggData
            }
            openDelegate?.openquickbackup()
        }
        self.remoteestimatedlist?.abort()
        self.remoteestimatedlist?.stackoftasktobeestimated = nil
        self.remoteestimatedlist = nil
        self.remoteinfotaskDelegate?.setremoteinfo(remoteinfotask: nil)
        self.closeview()
    }

    // Either abort or close
    @IBAction func abort(_: NSButton) {
        self.remoteestimatedlist?.abort()
        self.remoteestimatedlist?.stackoftasktobeestimated = nil
        self.remoteestimatedlist = nil
        self.abort()
        self.remoteinfotaskDelegate?.setremoteinfo(remoteinfotask: nil)
        self.closeview()
    }

    private func closeview() {
        if (self.presentingViewController as? ViewControllerMain) != nil {
            self.dismissview(viewcontroller: self, vcontroller: .vctabmain)
        } else if (self.presentingViewController as? ViewControllerNewConfigurations) != nil {
            self.dismissview(viewcontroller: self, vcontroller: .vcnewconfigurations)
        } else if (self.presentingViewController as? ViewControllerRestore) != nil {
            self.dismissview(viewcontroller: self, vcontroller: .vcrestore)
        } else if (self.presentingViewController as? ViewControllerSsh) != nil {
            self.dismissview(viewcontroller: self, vcontroller: .vcssh)
        } else if (self.presentingViewController as? ViewControllerLoggData) != nil {
            self.dismissview(viewcontroller: self, vcontroller: .vcloggdata)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.mainTableView.delegate = self
        self.mainTableView.dataSource = self
        ViewControllerReference.shared.setvcref(viewcontroller: .vcremoteinfo, nsviewcontroller: self)
        if let remoteinfotask = self.remoteinfotaskDelegate?.getremoteinfo() {
            self.remoteestimatedlist = remoteinfotask
            self.loaded = true
            self.progress.isHidden = true
        } else {
            self.remoteestimatedlist = RemoteinfoEstimation(viewcontroller: self, processtermination: self.processtermination)
            self.remoteinfotaskDelegate?.setremoteinfo(remoteinfotask: self.remoteestimatedlist)
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        guard self.diddissappear == false else {
            globalMainQueue.async { () -> Void in
                self.mainTableView.reloadData()
            }
            return
        }
        globalMainQueue.async { () -> Void in
            self.mainTableView.reloadData()
        }
        self.count.stringValue = self.number()
        self.enableexecutebutton()
        if self.loaded == false {
            self.initiateProgressbar()
        }
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.diddissappear = true
        // Release the estimating object
        self.remoteestimatedlist?.abort()
        self.remoteestimatedlist = nil
    }

    private func number() -> String {
        if self.loaded {
            return NSLocalizedString("Loaded cached data...", comment: "Remote info")
        } else {
            let max = self.remoteestimatedlist?.maxCount() ?? 0
            return NSLocalizedString("Number of tasks to estimate:", comment: "Remote info") + " " + String(describing: max)
        }
    }

    private func dobackups() -> [NSMutableDictionary]? {
        let backup = self.remoteestimatedlist?.records?.filter { $0.value(forKey: DictionaryStrings.select.rawValue) as? Int == 1 }
        return backup
    }

    private func enableexecutebutton() {
        if let backup = self.dobackups() {
            if backup.count > 0 {
                self.executebutton.isEnabled = true
            } else {
                self.executebutton.isEnabled = false
            }
        } else {
            self.executebutton.isEnabled = false
        }
    }

    private func initiateProgressbar() {
        self.progress.maxValue = Double(self.remoteestimatedlist?.maxCount() ?? 0)
        self.progress.minValue = 0
        self.progress.doubleValue = 0
        self.progress.startAnimation(self)
    }

    private func updateProgressbar(_ value: Double) {
        self.progress.doubleValue = value
    }
}

extension ViewControllerRemoteInfo: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        return self.remoteestimatedlist?.records?.count ?? 0
    }
}

extension ViewControllerRemoteInfo: NSTableViewDelegate, Attributedestring {
    func tableView(_: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard self.remoteestimatedlist?.records != nil else { return nil }
        guard row < (self.remoteestimatedlist!.records?.count)! else { return nil }
        let object: NSDictionary = (self.remoteestimatedlist?.records?[row])!
        switch tableColumn!.identifier.rawValue {
        case DictionaryStrings.transferredNumber.rawValue:
            let celltext = object[tableColumn!.identifier] as? String
            return self.attributedstring(str: celltext!, color: NSColor.red, align: .right)
        case DictionaryStrings.transferredNumberSizebytes.rawValue:
            let celltext = object[tableColumn!.identifier] as? String
            return self.attributedstring(str: celltext!, color: NSColor.red, align: .right)
        case DictionaryStrings.newfiles.rawValue:
            let celltext = object[tableColumn!.identifier] as? String
            return self.attributedstring(str: celltext!, color: NSColor.red, align: .right)
        case DictionaryStrings.deletefiles.rawValue:
            let celltext = object[tableColumn!.identifier] as? String
            return self.attributedstring(str: celltext!, color: NSColor.red, align: .right)
        case DictionaryStrings.select.rawValue:
            return object[tableColumn!.identifier] as? Int
        default:
            return object[tableColumn!.identifier] as? String
        }
    }

    // Toggling selection
    func tableView(_: NSTableView, setObjectValue _: Any?, for tableColumn: NSTableColumn?, row: Int) {
        guard self.remoteestimatedlist?.records != nil else { return }
        if tableColumn!.identifier.rawValue == DictionaryStrings.select.rawValue {
            var select: Int = self.remoteestimatedlist?.records![row].value(forKey: DictionaryStrings.select.rawValue) as? Int ?? 0
            if select == 0 { select = 1 } else if select == 1 { select = 0 }
            self.remoteestimatedlist?.records![row].setValue(select, forKey: DictionaryStrings.select.rawValue)
        }
        self.enableexecutebutton()
    }
}

extension ViewControllerRemoteInfo {
    func processtermination() {
        globalMainQueue.async { () -> Void in
            self.mainTableView.reloadData()
        }
        let progress = Double(self.remoteestimatedlist?.maxCount() ?? 0) - Double(self.remoteestimatedlist?.inprogressCount() ?? 0)
        self.updateProgressbar(progress)
    }
}

extension ViewControllerRemoteInfo: StartStopProgressIndicator {
    func start() {
        //
    }

    func stop() {
        globalMainQueue.async { () -> Void in
            self.mainTableView.reloadData()
        }
        self.progress.stopAnimation(nil)
        self.progress.isHidden = true
        self.count.stringValue = NSLocalizedString("Estimation completed", comment: "Remote info") + "..."
        self.count.textColor = setcolor(nsviewcontroller: self, color: .green)
        self.enableexecutebutton()
    }
}
