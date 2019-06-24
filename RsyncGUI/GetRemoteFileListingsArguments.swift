//
//  getRemoteFilelist.swift
//  RsyncGUI
//
//  Created by Thomas Evensen on 21.05.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//

import Foundation

protocol ProcessArguments {
    func getArguments() -> [String]?
    func getCommand() -> String?
}

final class GetRemoteFileListingsArguments: ProcessArguments {

    private var config: Configuration?
    private var args: [String]?
    private var command: String?

    private func remotearguments(recursive: Bool) {
        if let config = self.config {
            if config.sshport != nil {
                let eparam: String = "-e"
                let sshp: String = "ssh -p"
                self.args!.append(eparam)
                self.args!.append(sshp + String(config.sshport!))
            } else {
                let eparam: String = "-e"
                let ssh: String = "ssh"
                self.args!.append(eparam)
                self.args!.append(ssh)
            }
            if recursive {
                self.args!.append("-r")
            }
            self.args!.append("--list-only")
            if config.offsiteServer.isEmpty == false {
                self.args!.append(config.offsiteUsername + "@" + config.offsiteServer + ":" + config.offsiteCatalog)
            } else {
                self.args!.append(":" + config.offsiteCatalog)
            }
        }
    }

    private func localarguments(recursive: Bool) {
        if recursive {
            self.args!.append("-r")
        }
        self.args!.append("--list-only")
        self.args!.append(config!.offsiteCatalog)
    }

    func getArguments() -> [String]? {
        guard self.args != nil else { return nil }
        return self.args
    }

    func getCommand() -> String? {
        guard self.command != nil else {
            return nil
        }
        return self.command
    }

    init(config: Configuration, recursive: Bool) {
        self.config = config
        self.args = [String]()
        if config.offsiteServer.isEmpty == false {
            self.remotearguments(recursive: recursive)
        } else {
            self.localarguments(recursive: recursive)
        }
    }
}
