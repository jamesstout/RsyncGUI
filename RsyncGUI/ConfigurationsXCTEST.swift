//
//  ConfigurationsXCTEST.swift
//  RsyncGUI
//
//  Created by Thomas Evensen on 20/12/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation

class ConfigurationsXCTEST: Configurations {
    private var maxhiddenID: Int {
        // Reading Configurations from memory
        if let store: [Configuration] = self.getConfigurations() {
            if store.count > 0 {
                _ = store.sorted { (config1, config2) -> Bool in
                    if config1.hiddenID > config2.hiddenID {
                        return true
                    } else {
                        return false
                    }
                }
                let index = store.count - 1
                return store[index].hiddenID
            } else {
                return 0
            }
        } else {
            return 0
        }
    }

    override func addNewConfigurations(dict: NSMutableDictionary) {
        var array = [NSDictionary]()
        if let configs: [Configuration] = self.getConfigurations() {
            for i in 0 ..< configs.count {
                if let dict: NSMutableDictionary = ConvertConfigurations(index: i).configuration {
                    array.append(dict)
                }
            }
            dict.setObject(self.maxhiddenID + 1, forKey: DictionaryStrings.hiddenID.rawValue as NSCopying)
            array.append(dict)
            guard Validatenewconfigs(dict: dict).validated == true else { return }
            self.appendconfigurationstomemory(dict: array[array.count - 1])
        }
    }

    override func readconfigurations() {
        self.argumentAllConfigurations = [ArgumentsOneConfiguration]()
        let store: [Configuration]? = PersistentStorageConfiguration(profile: self.profile, allprofiles: true).getConfigurations()
        for i in 0 ..< (store?.count ?? 0) {
            if ViewControllerReference.shared.synctasks.contains(store![i].task) {
                self.configurations?.append(store![i])
                let rsyncArgumentsOneConfig = ArgumentsOneConfiguration(config: store![i])
                self.argumentAllConfigurations!.append(rsyncArgumentsOneConfig)
            }
        }
        // Then prepare the datasource for use in tableviews as Dictionarys
        var data = [NSMutableDictionary]()
        for i in 0 ..< (self.configurations?.count ?? 0) {
            let task = self.configurations?[i].task
            if ViewControllerReference.shared.synctasks.contains(task ?? "") {
                data.append(ConvertOneConfig(config: self.configurations![i]).dict)
            }
        }
        self.configurationsDataSource = data
    }
}
