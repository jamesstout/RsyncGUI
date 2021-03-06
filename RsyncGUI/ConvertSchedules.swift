//
//  ConvertSchedules.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 26/04/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//
// swiftlint:disable trailing_comma line_length

import Foundation

struct ConvertSchedules: SetSchedules {
    var schedules: [NSDictionary]?

    init() {
        var array = [NSDictionary]()
        if let schedules = self.schedules?.getSchedule() {
            for i in 0 ..< schedules.count {
                let dict: NSMutableDictionary = [
                    DictionaryStrings.hiddenID.rawValue: schedules[i].hiddenID,
                    DictionaryStrings.dateStart.rawValue: schedules[i].dateStart,
                    DictionaryStrings.schedule.rawValue: schedules[i].schedule,
                    DictionaryStrings.offsiteserver.rawValue: schedules[i].offsiteserver ?? DictionaryStrings.localhost.rawValue,
                ]
                if let log = schedules[i].logrecords {
                    var logrecords = [NSDictionary]()
                    for i in 0 ..< log.count {
                        let dict: NSDictionary = [
                            DictionaryStrings.dateExecuted.rawValue: log[i].dateExecuted ?? "",
                            DictionaryStrings.resultExecuted.rawValue: log[i].resultExecuted ?? "",
                        ]
                        logrecords.append(dict)
                    }
                    dict.setObject(logrecords, forKey: DictionaryStrings.executed.rawValue as NSCopying)
                }
                if schedules[i].dateStop != nil {
                    dict.setValue(schedules[i].dateStop, forKey: DictionaryStrings.dateStop.rawValue)
                }
                if schedules[i].delete ?? false == false {
                    array.append(dict)
                } else {
                    if schedules[i].logrecords?.isEmpty == false {
                        if schedules[i].delete ?? false == false {
                            array.append(dict)
                        }
                    }
                }
            }
        }
        self.schedules = array
    }
}
