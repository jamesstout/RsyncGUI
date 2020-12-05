//
//  QuickBackup.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 22.12.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length trailing_comma

import Foundation

final class QuickBackup: SetConfigurations {
    var sortedlist: [NSMutableDictionary]?
    var estimatedlist: [NSDictionary]?
    typealias Row = (Int, Int)
    var stackoftasktobeexecuted: [Row]?
    var index: Int?
    var hiddenID: Int?
    var maxcount: Int?
    weak var reloadtableDelegate: Reloadandrefresh?
    var outputprocess: OutputProcess?
    var command: QuickbackupDispatch?

    func sortbydays() {
        guard self.sortedlist != nil else { return }
        let sorted = self.sortedlist!.sorted { (di1, di2) -> Bool in
            let di1 = (di1.value(forKey: DictionaryStrings.daysID.rawValue) as? NSString)!.doubleValue
            let di2 = (di2.value(forKey: DictionaryStrings.daysID.rawValue) as? NSString)!.doubleValue
            if di1 > di2 {
                return false
            } else {
                return true
            }
        }
        self.sortedlist = sorted
        self.reloadtableDelegate?.reloadtabledata()
    }

    private func executequickbackuptask(hiddenID: Int) {
        let now = Date()
        let dateformatter = Dateandtime().setDateformat()
        ViewControllerReference.shared.quickbackuptask = [
            DictionaryStrings.start.rawValue: now,
            DictionaryStrings.hiddenID.rawValue: hiddenID,
            DictionaryStrings.dateStart.rawValue: dateformatter.date(from: "01 Jan 1900 00:00") ?? "",
            DictionaryStrings.schedule.rawValue: Scheduletype.manuel.rawValue,
        ]
        self.outputprocess = nil
        self.outputprocess = OutputProcessRsync()
        self.command = QuickbackupDispatch(processtermination: self.processtermination,
                                           filehandler: self.filehandler,
                                           outputprocess: self.outputprocess)
    }

    func prepareandstartexecutetasks() {
        if let list = self.sortedlist {
            self.stackoftasktobeexecuted = [Row]()
            for i in 0 ..< list.count {
                self.sortedlist![i].setObject(false, forKey: DictionaryStrings.completeCellID.rawValue as NSCopying)
                self.sortedlist![i].setObject(false, forKey: DictionaryStrings.inprogressCellID.rawValue as NSCopying)
                if list[i].value(forKey: DictionaryStrings.selectCellID.rawValue) as? Int == 1 {
                    self.stackoftasktobeexecuted?.append(((list[i].value(forKey: DictionaryStrings.hiddenID.rawValue) as? Int)!, i))
                }
                let hiddenID = list[i].value(forKey: DictionaryStrings.hiddenID.rawValue) as? Int
                if self.estimatedlist != nil {
                    let estimated = self.estimatedlist!.filter { ($0.value(forKey: DictionaryStrings.hiddenID.rawValue) as? Int) == hiddenID! }
                    if estimated.count > 0 {
                        let transferredNumber = estimated[0].value(forKey: DictionaryStrings.transferredNumber.rawValue) as? String ?? ""
                        self.sortedlist![i].setObject(transferredNumber, forKey: DictionaryStrings.transferredNumber.rawValue as NSCopying)
                    }
                }
            }
            guard self.stackoftasktobeexecuted!.count > 0 else { return }
            // Kick off first task
            self.hiddenID = self.stackoftasktobeexecuted![0].0
            self.index = self.stackoftasktobeexecuted![0].1
            self.sortedlist![self.index!].setValue(true, forKey: DictionaryStrings.inprogressCellID.rawValue)
            self.maxcount = Int(self.sortedlist![self.index!].value(forKey: DictionaryStrings.transferredNumber.rawValue) as? String ?? "0")
            self.stackoftasktobeexecuted?.remove(at: 0)
            self.executequickbackuptask(hiddenID: self.hiddenID!)
        }
    }

    func setcompleted() {
        let dict = self.sortedlist!.filter { ($0.value(forKey: DictionaryStrings.hiddenID.rawValue) as? Int) == self.hiddenID! }
        guard dict.count == 1 else { return }
        self.index = self.sortedlist!.firstIndex(of: dict[0])
        self.sortedlist![self.index!].setValue(true, forKey: DictionaryStrings.completeCellID.rawValue)
        self.sortedlist![self.index!].setValue(false, forKey: DictionaryStrings.inprogressCellID.rawValue)
    }

    init() {
        self.estimatedlist = self.configurations?.estimatedlist
        if self.estimatedlist != nil {
            self.sortedlist = self.configurations?.getConfigurationsDataSourceSynchronize()?.filter { ($0.value(forKey: DictionaryStrings.selectCellID.rawValue) as? Int) == 1 }
            guard self.sortedlist!.count > 0 else { return }
        } else {
            self.sortedlist = self.configurations?.getConfigurationsDataSourceSynchronize()
        }
        self.sortbydays()
        self.hiddenID = nil
        self.reloadtableDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcquickbackup) as? ViewControllerQuickBackup
    }

    deinit {
        self.stackoftasktobeexecuted = nil
    }

    func abort() {
        self.stackoftasktobeexecuted = nil
    }
}

extension QuickBackup {
    func processtermination() {
        self.setcompleted()
        ViewControllerReference.shared.completeoperation?.finalizeScheduledJob(outputprocess: self.outputprocess)
        ViewControllerReference.shared.completeoperation = nil
        guard (self.stackoftasktobeexecuted?.count ?? 0) > 0 else {
            self.stackoftasktobeexecuted = nil
            self.hiddenID = nil
            self.reloadtableDelegate?.reloadtabledata()
            weak var quickbackupcompletedDelegate: QuickBackupCompleted?
            quickbackupcompletedDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcquickbackup) as? ViewControllerQuickBackup
            quickbackupcompletedDelegate?.quickbackupcompleted()
            return
        }
        self.hiddenID = self.stackoftasktobeexecuted![0].0
        self.index = self.stackoftasktobeexecuted![0].1
        self.stackoftasktobeexecuted?.remove(at: 0)
        self.sortedlist![self.index!].setValue(true, forKey: DictionaryStrings.inprogressCellID.rawValue)
        self.maxcount = Int(self.sortedlist![self.index!].value(forKey: DictionaryStrings.transferredNumber.rawValue) as? String ?? "0")
        self.executequickbackuptask(hiddenID: self.hiddenID!)
        self.reloadtableDelegate?.reloadtabledata()
        self.command = nil
    }

    func filehandler() {
        weak var localprocessupdateDelegate: Reloadandrefresh?
        weak var outputeverythingDelegate: ViewOutputDetails?
        localprocessupdateDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcquickbackup) as? ViewControllerQuickBackup
        localprocessupdateDelegate?.reloadtabledata()
        outputeverythingDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllerMain
        if outputeverythingDelegate?.appendnow() ?? false {
            outputeverythingDelegate?.reloadtable()
        }
    }
}
