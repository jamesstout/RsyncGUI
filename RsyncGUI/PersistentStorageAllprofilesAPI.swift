//
//  PersistentStorageAllprofilesAPI.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 22/02/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//

import Foundation

class PersistentStorageAllprofilesAPI: SetConfigurations, SetSchedules {
    var profile: String?

    // Read configurations from persisten store
    func getConfigurations() -> [Configuration]? {
        let read = PersistentStorageConfiguration(profile: self.profile, allprofiles: true)
        guard read.configurationsasdictionary != nil else { return nil }
        var Configurations = [Configuration]()
        for dict in read.configurationsasdictionary! {
            let conf = Configuration(dictionary: dict)
            Configurations.append(conf)
        }
        return Configurations
    }

    // Read schedules and history
    // If no Schedule from persistent store return nil
    func getScheduleandhistory(includelog: Bool) -> [ConfigurationSchedule]? {
        var schedule = [ConfigurationSchedule]()
        let read = PersistentStorageScheduling(profile: self.profile, readonly: true)
        guard read.schedulesasdictionary != nil else { return nil }
        for dict in read.schedulesasdictionary! {
            if let log = dict.value(forKey: "executed") {
                let conf = ConfigurationSchedule(dictionary: dict, log: log as? NSArray, includelog: includelog)
                schedule.append(conf)
            } else {
                let conf = ConfigurationSchedule(dictionary: dict, log: nil, includelog: includelog)
                schedule.append(conf)
            }
        }
        return schedule
    }

    init(profile: String?) {
        self.profile = profile
    }
}
