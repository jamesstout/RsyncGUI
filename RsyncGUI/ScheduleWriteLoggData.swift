//
//  ScheduleWriteLoggData.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 19.04.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Cocoa
import Foundation

class ScheduleWriteLoggData: SetConfigurations, ReloadTable, Deselect {
    var schedules: [ConfigurationSchedule]?
    var profile: String?

    typealias Row = (Int, Int)
    func deleteselectedrows(scheduleloggdata: ScheduleLoggData?) {
        guard scheduleloggdata?.loggdata != nil else { return }
        var deletes = [Row]()
        let selectdeletes = scheduleloggdata!.loggdata!.filter { ($0.value(forKey: "deleteCellID") as? Int)! == 1 }.sorted { (dict1, dict2) -> Bool in
            if (dict1.value(forKey: "parent") as? Int) ?? 0 > (dict2.value(forKey: "parent") as? Int) ?? 0 {
                return true
            } else {
                return false
            }
        }
        for i in 0 ..< selectdeletes.count {
            let parent = selectdeletes[i].value(forKey: "parent") as? Int ?? 0
            let sibling = selectdeletes[i].value(forKey: "sibling") as? Int ?? 0
            deletes.append((parent, sibling))
        }
        deletes.sort(by: { (obj1, obj2) -> Bool in
            if obj1.0 == obj2.0, obj1.1 > obj2.1 {
                return obj1 > obj2
            }
            return obj1 > obj2
        })
        for i in 0 ..< deletes.count {
            self.schedules?[deletes[i].0].logrecords.remove(at: deletes[i].1)
        }
        _ = PersistentStorageScheduling(profile: self.profile).savescheduleInMemoryToPersistentStore()
        self.reloadtable(vcontroller: .vcloggdata)
    }

    // Function adds results of task to file (via memory). Memory are
    // saved after changed. Used in single tasks
    // - parameter hiddenID : hiddenID for task
    // - parameter result : String representation of result
    // - parameter date : String representation of date and time stamp
    func addlog(hiddenID: Int, result: String) {
        if ViewControllerReference.shared.detailedlogging {
            // Set the current date
            let currendate = Date()
            let dateformatter = Dateandtime().setDateformat()
            let date = dateformatter.string(from: currendate)
            var resultannotaded: String?
            resultannotaded = result
            var inserted: Bool = self.addlogexisting(hiddenID: hiddenID, result: resultannotaded ?? "", date: date)
            // Record does not exist, create new Schedule (not inserted)
            if inserted == false {
                inserted = self.addlognew(hiddenID: hiddenID, result: resultannotaded ?? "", date: date)
            }
            if inserted {
                _ = PersistentStorageScheduling(profile: self.profile).savescheduleInMemoryToPersistentStore()
                self.deselectrowtable()
            }
        }
    }

    func addlogexisting(hiddenID: Int, result: String, date: String) -> Bool {
        var loggadded: Bool = false
        let index = self.schedules?.firstIndex(where: { _ in ViewControllerReference.shared.synctasks.contains(self.configurations?.getResourceConfiguration(hiddenID, resource: .task) ?? "") }) ?? -1
        guard index > -1 else { return false }
        if self.schedules?[index].hiddenID == hiddenID,
            self.schedules?[index].schedule == Scheduletype.manuel.rawValue,
            self.schedules?[index].dateStop == nil
        {
            let dict = NSMutableDictionary()
            dict.setObject(date, forKey: "dateExecuted" as NSCopying)
            dict.setObject(result, forKey: "resultExecuted" as NSCopying)
            self.schedules?[index].logrecords.append(dict)
            loggadded = true
        }
        return loggadded
    }

    private func addlognew(hiddenID: Int, result: String, date: String) -> Bool {
        var loggadded: Bool = false
        if ViewControllerReference.shared.synctasks.contains(self.configurations?.getResourceConfiguration(hiddenID, resource: .task) ?? "") {
            let masterdict = NSMutableDictionary()
            masterdict.setObject(hiddenID, forKey: "hiddenID" as NSCopying)
            masterdict.setObject("01 Jan 1900 00:00", forKey: "dateStart" as NSCopying)
            masterdict.setObject(Scheduletype.manuel.rawValue, forKey: "schedule" as NSCopying)
            let dict = NSMutableDictionary()
            dict.setObject(date, forKey: "dateExecuted" as NSCopying)
            dict.setObject(result, forKey: "resultExecuted" as NSCopying)
            let executed = NSMutableArray()
            executed.add(dict)
            let newSchedule = ConfigurationSchedule(dictionary: masterdict, log: executed, nolog: false)
            self.schedules?.append(newSchedule)
            loggadded = true
        }
        return loggadded
    }

    private func getconfig(hiddenID: Int) -> Configuration? {
        let index = self.configurations?.getIndex(hiddenID) ?? 0
        return self.configurations?.getConfigurations()[index]
    }

    init(profile: String?) {
        self.profile = profile
        self.schedules = [ConfigurationSchedule]()
    }
}
