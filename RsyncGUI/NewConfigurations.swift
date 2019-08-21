//
//  NewConfigurations.swift
//  RsyncGUI
//
//  Created by Thomas Evensen on 17.09.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//

import Foundation

class NewConfigurations {

    // Temporary structure to hold added Configurations before writing to permanent store
    private var newConfigurations: [NSMutableDictionary]?

    /// Function is getting all added (new) configurations
    /// - returns : Array of Dictionary storing all new configurations
    func getnewConfigurations () -> [NSMutableDictionary]? {
        return self.newConfigurations
    }

    // Appending
    func appendnewConfigurations(dict: NSMutableDictionary) {
        guard self.newConfigurations != nil else {
            self.newConfigurations = [NSMutableDictionary]()
            self.newConfigurations?.append(dict)
            return
        }
        self.newConfigurations?.append(dict)
    }

    func newConfigurationsCount() -> Int {
        return self.newConfigurations?.count ?? 0
    }

    init() {
        self.newConfigurations = [NSMutableDictionary]()
    }
}
