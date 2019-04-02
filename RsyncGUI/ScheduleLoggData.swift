//
//  ScheduleLoggData.swift
//  RsyncGUI
//
//  Created by Thomas Evensen on 23/09/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
//  Object for sorting and holding logg data about all tasks.
//  Detailed logging must be set on if logging data.
//

import Foundation

enum Sortandfilter {
    case remotecatalog
    case localcatalog
    case profile
    case remoteserver
    case task
    case backupid
    case numberofdays
    case executedate
}

final class ScheduleLoggData: SetConfigurations, SetSchedules, Sorting {

    var loggdata: [NSMutableDictionary]?
    private var scheduleConfiguration: [ConfigurationSchedule]?

    func filter(search: String?, filterby: Sortandfilter?) {
        guard search != nil && self.loggdata != nil && filterby != nil else { return }
        globalDefaultQueue.async(execute: {() -> Void in
            let valueforkey = self.filterbystring(filterby: filterby!)
            self.loggdata = self.loggdata?.filter({
                ($0.value(forKey: valueforkey) as? String)!.contains(search!)
            })
        })
    }

    private func readAndSortAllLoggdata(sortdirection: Bool) {
        var data = [NSMutableDictionary]()
        let input: [ConfigurationSchedule] = self.schedules!.getSchedule()
        for i in 0 ..< input.count {
            let hiddenID = self.schedules!.getSchedule()[i].hiddenID
            for j in 0 ..< input[i].logrecords.count {
                let dict = input[i].logrecords[j]
                let logdetail: NSMutableDictionary = [
                    "localCatalog": self.configurations!.getResourceConfiguration(hiddenID, resource: .localCatalog),
                    "offsiteServer": self.configurations!.getResourceConfiguration(hiddenID, resource: .offsiteServer),
                    "task": self.configurations!.getResourceConfiguration(hiddenID, resource: .task),
                    "backupID": self.configurations!.getResourceConfiguration(hiddenID, resource: .backupid),
                    "dateExecuted": dict.value(forKey: "dateExecuted") as? String ?? "",
                    "resultExecuted": dict.value(forKey: "resultExecuted") as? String ?? "",
                    "deleteCellID": dict.value(forKey: "deleteCellID") as? Int ?? 0,
                    "hiddenID": hiddenID,
                    "snapCellID": 0,
                    "parent": i,
                    "sibling": j]
                data.append(logdetail)
            }
        }
        self.loggdata = self.sortbyrundate(notsorted: data, sortdirection: sortdirection)
    }

    private func readAndSortAllLoggdata(hiddenID: Int, sortdirection: Bool) {
        var data = [NSMutableDictionary]()
        let input: [ConfigurationSchedule] = self.schedules!.getSchedule()
        for i in 0 ..< input.count {
            for j in 0 ..< input[i].logrecords.count where self.schedules!.getSchedule()[i].hiddenID == hiddenID {
                let dict = input[i].logrecords[j]
                let logdetail: NSMutableDictionary = [
                    "localCatalog": self.configurations!.getResourceConfiguration(hiddenID, resource: .localCatalog),
                    "offsiteServer": self.configurations!.getResourceConfiguration(hiddenID, resource: .offsiteServer),
                    "task": self.configurations!.getResourceConfiguration(hiddenID, resource: .task),
                    "backupID": self.configurations!.getResourceConfiguration(hiddenID, resource: .backupid),
                    "dateExecuted": dict.value(forKey: "dateExecuted") as? String ?? "",
                    "resultExecuted": dict.value(forKey: "resultExecuted") as? String ?? "",
                    "deleteCellID": dict.value(forKey: "deleteCellID") as? Int ?? 0,
                    "hiddenID": hiddenID,
                    "snapCellID": 0,
                    "parent": i,
                    "sibling": j]
                data.append(logdetail)
            }
        }
        self.loggdata = self.sortbyrundate(notsorted: data, sortdirection: sortdirection)
    }

    private func allreadAndSortAllLoggdata() {
        var data = [NSMutableDictionary]()
        let input: [ConfigurationSchedule]? = self.scheduleConfiguration
        guard input != nil else { return }
        for i in 0 ..< input!.count where input![i].logrecords.count > 0 {
            let profilename = input![i].profilename
            for j in 0 ..< input![i].logrecords.count {
                let dict = input![i].logrecords[j]
                dict.setValue(profilename, forKey: "profilename")
                data.append(dict)
            }
        }
        self.loggdata = self.sortbyrundate(notsorted: data, sortdirection: true)
    }

    let compare: (NSMutableDictionary, NSMutableDictionary) -> Bool = { (number1, number2) in
        if number1.value(forKey: "sibling") as? Int == number2.value(forKey: "sibling") as? Int &&
            number1.value(forKey: "parent") as? Int == number2.value(forKey: "parent") as? Int {
            return true
        } else {
            return false
        }
    }

    init (sortdirection: Bool) {
        if self.loggdata == nil {
            self.readAndSortAllLoggdata(sortdirection: sortdirection)
        }
    }

    init (allschedules: Allschedules?) {
        guard allschedules != nil else { return }
        self.scheduleConfiguration = allschedules!.getallschedules()
        self.allreadAndSortAllLoggdata()
    }

    init (hiddenID: Int, sortdirection: Bool) {
        if self.loggdata == nil {
            self.readAndSortAllLoggdata(hiddenID: hiddenID, sortdirection: sortdirection)
        }
    }
}
