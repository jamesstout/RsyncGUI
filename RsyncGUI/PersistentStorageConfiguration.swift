//
//  PersistentStoreageConfiguration.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 09/12/15.
//  Copyright © 2015 Thomas Evensen. All rights reserved.
//

import Foundation

final class PersistentStorageConfiguration: ReadWriteDictionary, SetConfigurations {

    /// Variable holds all configuration data from persisten storage
    var configurationsasdictionary: [NSDictionary]?

    /// Variable computes max hiddenID used
    /// MaxhiddenID is used when new configurations are added.
    private var maxhiddenID: Int {
        // Reading Configurations from memory
        let store: [Configuration] = self.configurations!.getConfigurations()
        if store.count > 0 {
            _ = store.sorted { (config1, config2) -> Bool in
                if config1.hiddenID > config2.hiddenID {
                    return true
                } else {
                    return false
                }
            }
            let index = store.count-1
            return store[index].hiddenID
        } else {
            return 0
        }
    }

    // Read configurations from persisten store
      func getConfigurations() -> [Configuration]? {
          let read = PersistentStorageConfiguration(profile: self.profile)
          guard read.configurationsasdictionary != nil else { return nil}
          var Configurations = [Configuration]()
          for dict in read.configurationsasdictionary! {
              let conf = Configuration(dictionary: dict)
              Configurations.append(conf)
          }
          return Configurations
      }

    // Saving Configuration from MEMORY to persistent store
    // Reads Configurations from MEMORY and saves to persistent Store
    func saveconfigInMemoryToPersistentStore() {
        var array = [NSDictionary]()
        let configs: [Configuration] = self.configurations!.getConfigurations()
        for i in 0 ..< configs.count {
            if let dict: NSMutableDictionary = ConvertConfigurations(index: i).configuration {
                array.append(dict)
            }
        }
        self.writeToStore(array: array)
    }

    // Add new configuration in memory to permanent storage
    func newConfigurations(dict: NSMutableDictionary) {
        var array = [NSDictionary]()
        // Get existing configurations from memory
        let configs: [Configuration] = self.configurations!.getConfigurations()
        // copy existing backups before adding
        for i in 0 ..< configs.count {
            if let dict: NSMutableDictionary = ConvertConfigurations(index: i).configuration {
                array.append(dict)
            }
        }
        // backup part
        dict.setObject(self.maxhiddenID + 1, forKey: "hiddenID" as NSCopying)
        dict.removeObject(forKey: "singleFile")
        array.append(dict)
        self.configurations!.appendconfigurationstomemory(dict: array[array.count - 1])
        self.saveconfigInMemoryToPersistentStore()
    }

    // Writing configuration to persistent store
    // Configuration is [NSDictionary]
    private func writeToStore(array: [NSDictionary]) {
        if self.writeNSDictionaryToPersistentStorage(array) {
            self.configurationsDelegate?.reloadconfigurationsobject()
        }
    }

    init (profile: String?) {
        super.init(whattoreadwrite: .configuration, profile: profile,
                   configpath: ViewControllerReference.shared.configpath)
        if self.configurations == nil {
            self.configurationsasdictionary = self.readNSDictionaryFromPersistentStore()
        }
    }

    init (profile: String?, allprofiles: Bool) {
        super.init(whattoreadwrite: .configuration, profile: profile,
                   configpath: ViewControllerReference.shared.configpath)
        self.configurationsasdictionary = self.readNSDictionaryFromPersistentStore()
    }
}
