//
//  RemoteInfoTaskWorkQueue.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 31.12.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Cocoa
import Foundation

protocol SetRemoteInfo: AnyObject {
    func setremoteinfo(remoteinfotask: RemoteinfoEstimation?)
    func getremoteinfo() -> RemoteinfoEstimation?
}

final class RemoteinfoEstimation: SetConfigurations {
    // (hiddenID, index)
    typealias Row = (Int, Int)
    var stackoftasktobeestimated: [Row]?
    var outputprocess: OutputProcess?
    var records: [NSMutableDictionary]?
    // weak var updateprogressDelegate: UpdateProgress?
    var updateviewprocesstermination: () -> Void
    weak var reloadtableDelegate: Reloadandrefresh?
    weak var startstopProgressIndicatorDelegate: StartStopProgressIndicator?
    weak var getmultipleselectedindexesDelegate: GetMultipleSelectedIndexes?
    var index: Int?
    private var maxnumber: Int?

    private func prepareandstartexecutetasks() {
        self.stackoftasktobeestimated = [Row]()
        if self.getmultipleselectedindexesDelegate?.multipleselection() == false {
            for i in 0 ..< (self.configurations?.getConfigurations().count ?? 0) {
                let task = self.configurations?.getConfigurations()[i].task
                if ViewControllerReference.shared.synctasks.contains(task ?? "") {
                    self.stackoftasktobeestimated?.append((self.configurations!.getConfigurations()[i].hiddenID, i))
                }
            }
        } else {
            let indexes = self.getmultipleselectedindexesDelegate?.getindexes()
            for i in 0 ..< (indexes?.count ?? 0) {
                if let index = indexes?[i] {
                    let task = self.configurations?.getConfigurations()[index].task
                    if ViewControllerReference.shared.synctasks.contains(task ?? "") {
                        self.stackoftasktobeestimated?.append((self.configurations!.getConfigurations()[index].hiddenID, index))
                    }
                }
            }
        }
        self.maxnumber = self.stackoftasktobeestimated?.count
    }

    func selectalltaskswithnumbers(deselect: Bool) {
        guard self.records != nil else { return }
        for i in 0 ..< (self.records?.count ?? 0) {
            let number = (self.records![i].value(forKey: "transferredNumber") as? String) ?? "0"
            let delete = (self.records![i].value(forKey: "deletefiles") as? String) ?? "0"
            if Int(number) ?? 0 > 0 || Int(delete) ?? 0 > 0 {
                if deselect {
                    self.records![i].setValue(0, forKey: "select")
                } else {
                    self.records![i].setValue(1, forKey: "select")
                }
            }
        }
    }

    func setbackuplist(list: [NSMutableDictionary]) {
        self.configurations?.quickbackuplist = [Int]()
        for i in 0 ..< list.count {
            self.configurations?.quickbackuplist!.append((list[i].value(forKey: "hiddenID") as? Int)!)
        }
    }

    func setbackuplist() {
        guard self.records != nil else { return }
        self.configurations?.quickbackuplist = [Int]()
        for i in 0 ..< (self.records?.count ?? 0) {
            if self.records![i].value(forKey: "select") as? Int == 1 {
                self.configurations?.quickbackuplist?.append((self.records![i].value(forKey: "hiddenID") as? Int)!)
            }
        }
    }

    private func startestimation() {
        guard (self.stackoftasktobeestimated?.count ?? 0) > 0 else { return }
        if let index = self.stackoftasktobeestimated?.remove(at: 0).1 {
            self.index = index
            self.outputprocess = OutputProcess()
            self.startstopProgressIndicatorDelegate?.start()
            _ = EstimateremoteInformationOnetask(index: index, outputprocess: self.outputprocess, local: false, processtermination: self.processtermination, filehandler: self.filehandler)
        }
    }

    init(viewcontroller: NSViewController, processtermination: @escaping () -> Void) {
        self.updateviewprocesstermination = processtermination
        self.startstopProgressIndicatorDelegate = viewcontroller as? StartStopProgressIndicator
        self.getmultipleselectedindexesDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllerMain
        self.prepareandstartexecutetasks()
        self.records = [NSMutableDictionary]()
        self.configurations?.estimatedlist = [NSMutableDictionary]()
        self.startestimation()
    }
}

extension RemoteinfoEstimation: CountRemoteEstimatingNumberoftasks {
    func maxCount() -> Int {
        return self.maxnumber ?? 0
    }

    func inprogressCount() -> Int {
        return self.stackoftasktobeestimated?.count ?? 0
    }
}

extension RemoteinfoEstimation {
    func processtermination() {
        let record = RemoteinfonumbersOnetask(outputprocess: self.outputprocess).record()
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
        guard self.stackoftasktobeestimated?.count ?? 0 > 0 else {
            self.selectalltaskswithnumbers(deselect: false)
            self.setbackuplist()
            self.startstopProgressIndicatorDelegate?.stop()
            return
        }
        // Update View
        self.updateviewprocesstermination()
        self.outputprocess = OutputProcessRsync()
        if let index = self.stackoftasktobeestimated?.remove(at: 0).1 {
            self.index = index
            _ = EstimateremoteInformationOnetask(index: index, outputprocess: self.outputprocess, local: false, processtermination: self.processtermination, filehandler: self.filehandler)
        }
    }

    func filehandler() {
        weak var outputeverythingDelegate: ViewOutputDetails?
        outputeverythingDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllerMain
        if outputeverythingDelegate?.appendnow() ?? false {
            outputeverythingDelegate?.reloadtable()
        }
    }
}
