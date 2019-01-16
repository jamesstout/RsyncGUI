//
//  SnapshotCreateCatalog.swift
//  RsyncGUI
//
//  Created by Thomas Evensen on 18.01.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//

// swiftlint:disable line_length

import Foundation

final class SnapshotCreateCatalog: ProcessCmd {
    override init (command: String?, arguments: [String]?) {
        super.init(command: command, arguments: arguments)
        self.updateDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcnewconfigurations) as? ViewControllerNewConfigurations
    }
}
