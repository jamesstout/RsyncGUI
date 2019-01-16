//
//  DuCommandSsh.swift
//  RsyncGUI
//
//  Created by Thomas Evensen on 09/11/2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//

import Foundation

final class DuCommandSsh: ProcessCmd {
    func getprocess() -> Process? {
        return self.getProcess()
    }

    func setdelegate(object: UpdateProgress) {
        self.updateDelegate = object
    }

    override init (command: String?, arguments: [String]?) {
        super.init(command: command, arguments: arguments)
    }
}
