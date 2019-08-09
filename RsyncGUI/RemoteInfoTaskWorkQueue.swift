//
//  RemoteInfoTaskWorkQueue.swift
//  RsyncGUI
//
//  Created by Thomas Evensen on 31.12.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation

protocol SetRemoteInfo: class {
    func setremoteinfo(remoteinfotask: RemoteInfoTaskWorkQueue?)
    func getremoteinfo() -> RemoteInfoTaskWorkQueue?
}

class RemoteInfoTaskWorkQueue: SetConfigurations {
    // (hiddenID, index)
    typealias Row = (Int, Int)
    var stackoftasktobeestimated: [Row]?
    var outputprocess: OutputProcess?
    var records: [NSMutableDictionary]?
    weak var updateprogressDelegate: UpdateProgress?
    weak var reloadtableDelegate: Reloadandrefresh?
    weak var enablebackupbuttonDelegate: EnableQuicbackupButton?
    weak var startstopProgressIndicatorDelegate: StartStopProgressIndicator?
    var index: Int?
    var maxnumber: Int?
    var count: Int?
    var inbatch: Bool?

    private func prepareandstartexecutetasks() {
        self.stackoftasktobeestimated = nil
        self.stackoftasktobeestimated = [Row]()
        for i in 0 ..< self.configurations!.getConfigurations().count {
            if self.configurations!.getConfigurations()[i].task == ViewControllerReference.shared.synchronize {
                if self.inbatch! {
                    if self.configurations!.getConfigurations()[i].batch == 1 {
                        self.stackoftasktobeestimated?.append((self.configurations!.getConfigurations()[i].hiddenID, i))
                    }
                } else {
                    self.stackoftasktobeestimated?.append((self.configurations!.getConfigurations()[i].hiddenID, i))
                }
            }
        }
        self.maxnumber = self.stackoftasktobeestimated?.count
    }

    private func startestimation() {
        guard self.stackoftasktobeestimated!.count > 0 else { return }
        self.outputprocess = OutputProcess()
        self.index = self.stackoftasktobeestimated?.remove(at: 0).1
        if self.stackoftasktobeestimated?.count == 0 {
            self.stackoftasktobeestimated = nil
        }
        self.startstopProgressIndicatorDelegate?.start()
        _ = EstimateRemoteInformationTask(index: self.index!, outputprocess: self.outputprocess, local: false)
    }

    func processTermination() {
        self.count = self.stackoftasktobeestimated?.count
        let record = RemoteInfoTask(outputprocess: self.outputprocess).record()
        record.setValue(self.configurations?.getConfigurations()[self.index!].localCatalog, forKey: "localCatalog")
        record.setValue(self.configurations?.getConfigurations()[self.index!].offsiteCatalog, forKey: "offsiteCatalog")
        record.setValue(self.configurations?.getConfigurations()[self.index!].hiddenID, forKey: "hiddenID")
        if self.configurations?.getConfigurations()[self.index!].offsiteServer.isEmpty == true {
            record.setValue("localhost", forKey: "offsiteServer")
        } else {
            record.setValue(self.configurations?.getConfigurations()[self.index!].offsiteServer, forKey: "offsiteServer")
        }
        self.records?.append(record)
        self.configurations?.estimatedlist?.append(record)
        self.updateprogressDelegate?.processTermination()
        guard self.stackoftasktobeestimated != nil else {
            self.startstopProgressIndicatorDelegate?.stop()
            return
        }
        self.outputprocess = nil
        self.outputprocess = OutputProcess()
        self.index = self.stackoftasktobeestimated?.remove(at: 0).1
        if self.stackoftasktobeestimated?.count == 0 {
            self.stackoftasktobeestimated = nil
        }
        _ = EstimateRemoteInformationTask(index: self.index!, outputprocess: self.outputprocess, local: false)
    }

    func setbackuplist(list: [NSMutableDictionary]) {
        self.configurations?.quickbackuplist = [Int]()
        for i in 0 ..< list.count {
            self.configurations?.quickbackuplist!.append((list[i].value(forKey: "hiddenID") as? Int)!)
        }
    }

    func sortbystrings(sort: Sort) {
        var sortby: String?
        guard self.records != nil else { return }
        switch sort {
        case .localCatalog:
            sortby = "localCatalog"
        case .backupId:
            sortby = "backupIDCellID"
        case .offsiteCatalog:
            sortby = "offsiteCatalog"
        case .offsiteServer:
            sortby = "offsiteServer"
        }
        let sorted = self.records!.sorted {return ($0.value(forKey: sortby!) as? String)!.localizedStandardCompare(($1.value(forKey: sortby!) as? String)!) == .orderedAscending}
        self.records = sorted
    }

    func selectalltaskswithnumbers(deselect: Bool) {
        guard self.records != nil else { return }
        for i in 0 ..< self.records!.count {
            let number = (self.records![i].value(forKey: "transferredNumber") as? String) ?? "0"
            let delete = (self.records![i].value(forKey: "deletefiles") as? String) ?? "0"
            if Int(number)! > 0 || Int(delete)! > 0 {
                if deselect {
                    self.records![i].setValue(0, forKey: "select")
                } else {
                    self.records![i].setValue(1, forKey: "select")
                }
            }
        }
    }

    func setbackuplist() {
        guard self.records != nil else { return }
        self.configurations?.quickbackuplist = [Int]()
        for i in 0 ..< self.records!.count {
            if self.records![i].value( forKey: "select") as? Int == 1 {
                self.configurations?.quickbackuplist!.append((self.records![i].value(forKey: "hiddenID") as? Int)!)
            }
        }
    }

    func selectalltaskswithfilestobackup(deselect: Bool) {
        self.selectalltaskswithnumbers(deselect: deselect)
        self.reloadtableDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcremoteinfo) as? ViewControllerRemoteInfo
        self.enablebackupbuttonDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcremoteinfo) as? ViewControllerRemoteInfo
        self.reloadtableDelegate?.reloadtabledata()
        self.enablebackupbuttonDelegate?.enablequickbackupbutton()
    }

    init(inbatch: Bool) {
        self.inbatch = inbatch
        if inbatch {
            self.updateprogressDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcbatch) as? ViewControllerBatch
             self.startstopProgressIndicatorDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcbatch) as? ViewControllerBatch
        } else {
            self.updateprogressDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcremoteinfo) as? ViewControllerRemoteInfo
            self.startstopProgressIndicatorDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcremoteinfo) as? ViewControllerRemoteInfo
        }
        self.prepareandstartexecutetasks()
        self.records = [NSMutableDictionary]()
        self.configurations!.estimatedlist = nil
        self.configurations!.estimatedlist = [NSMutableDictionary]()
        self.startestimation()
    }
}

extension RemoteInfoTaskWorkQueue: CountEstimating {
    func maxCount() -> Int {
        return self.maxnumber ?? 0
    }

    func inprogressCount() -> Int {
        return self.stackoftasktobeestimated?.count ?? 0
    }
}
