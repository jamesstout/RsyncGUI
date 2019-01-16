//
//  persistentStoreAPI.swift
//  RsyncGUI
//
//  Created by Thomas Evensen on 09/12/15.
//  Copyright © 2015 Thomas Evensen. All rights reserved.
//

import Foundation

final class PersistentStorageAPI: SetConfigurations, SetSchedules {

    var profile: String?
    var forceread: Bool = false

    // CONFIGURATIONS

    // Read configurations from persisten store
    func getConfigurations() -> [Configuration]? {
        var read: PersistentStorageConfiguration?
        if self.forceread {
            read = PersistentStorageConfiguration(profile: self.profile, forceread: true)
        } else {
            read = PersistentStorageConfiguration(profile: self.profile)
        }
        // Either read from persistent store or return Configurations already in memory
        if read!.readConfigurationsFromPermanentStore() != nil {
            var Configurations = [Configuration]()
            for dict in read!.readConfigurationsFromPermanentStore()! {
                let conf = Configuration(dictionary: dict)
                Configurations.append(conf)
            }
            return Configurations
        } else {
            return nil
        }
    }

    // Saving configuration from memory to persistent store
    func saveConfigFromMemory() {
        let save = PersistentStorageConfiguration(profile: self.profile)
        save.saveconfigInMemoryToPersistentStore()
    }

    // Saving added configuration
    func addandsaveNewConfigurations(dict: NSMutableDictionary) {
        let save = PersistentStorageConfiguration(profile: self.profile)
        save.newConfigurations(dict)
        save.saveconfigInMemoryToPersistentStore()
    }

    // SCHEDULE

    // Saving Schedules from memory to persistent store
    func saveScheduleFromMemory() {
        let store = PersistentStorageScheduling(profile: self.profile)
        store.savescheduleInMemoryToPersistentStore()
    }

    // Read schedules and history
    // If no Schedule from persistent store return nil
    func getScheduleandhistory(nolog: Bool) -> [ConfigurationSchedule]? {
        var read: PersistentStorageScheduling?
        if self.forceread {
            read = PersistentStorageScheduling(profile: self.profile, forceread: true)
        } else {
            read = PersistentStorageScheduling(profile: self.profile)
        }
        var schedule = [ConfigurationSchedule]()
        // Either read from persistent store or return Schedule already in memory
        if read!.readSchedulesFromPermanentStore() != nil {
            for dict in read!.readSchedulesFromPermanentStore()! {
                if let log = dict.value(forKey: "executed") {
                    let conf = ConfigurationSchedule(dictionary: dict, log: log as? NSArray, nolog: nolog)
                    schedule.append(conf)
                } else {
                    let conf = ConfigurationSchedule(dictionary: dict, log: nil, nolog: nolog)
                    schedule.append(conf)
                }
            }
            return schedule
        } else {
            return nil
        }
    }

    // USERCONFIG

    // Saving user configuration
    func saveUserconfiguration() {
        let store = PersistentStorageUserconfiguration(readfromstorage: false)
        store.saveUserconfiguration()
    }

    func getUserconfiguration (readfromstorage: Bool) -> [NSDictionary]? {
        let store = PersistentStorageUserconfiguration(readfromstorage: readfromstorage)
        return store.readUserconfigurationsFromPermanentStore()
    }

    init(profile: String?) {
        self.profile = profile
    }

    init(profile: String?, forceread: Bool) {
        self.profile = profile
        self.forceread = forceread
    }
}
