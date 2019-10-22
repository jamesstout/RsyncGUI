//
//  rsyncArguments.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 06.03.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//

import Foundation

final class RsyncParametersSingleFilesArguments: ProcessArguments {

    let archive: String = "--archive"
    let verbose: String = "--verbose"
    let compress: String = "--compress"
    let delete: String = "--delete"
    let eparam: String = "-e"
    let ssh: String = "ssh"
    let sshp: String = "ssh -p"
    let dryrun: String = "--dry-run"

    private var config: Configuration?
    private var args: [String]?
    private var argDisplay: String?

    // Set parameters for rsync
    private func arguments(remoteFile: String?, localCatalog: String?, drynrun: Bool?) {
        if let config = self.config {
            // Drop the two first characeters ("./") as result from the find . -name
            let remote_with_whitespace: String = String(remoteFile!.dropFirst(2))
            // Replace remote for white spaces
            let whitespace: String = "\\ "
            let remote = remote_with_whitespace.replacingOccurrences(of: " ", with: whitespace)
            let local: String = localCatalog!
            if config.sshport != nil {
                self.args!.append(self.eparam)
                self.args!.append(self.sshp + " " + String(config.sshport!))
            } else {
                self.args!.append(self.eparam)
                self.args!.append(self.ssh)
            }
            self.args!.append(self.archive)
            self.args!.append(self.verbose)
            // If copy over network compress files
            if config.offsiteServer.isEmpty {
                self.args!.append(self.compress)
            }
            // Set dryrun or not
            if drynrun != nil {
                if drynrun == true {
                    self.args!.append(self.dryrun)
                }
            }
            if config.offsiteServer.isEmpty {
                self.args!.append(config.offsiteCatalog + remote)
            } else {
                let rarg = config.offsiteUsername + "@" + config.offsiteServer + ":" + config.offsiteCatalog + remote
                self.args!.append(rarg)
            }
            self.args!.append(local)
        }
    }

    private func argumentstodisplay() {
        guard self.args != nil else { return }
        // Prepare the display version of arguments
        self.argDisplay = Getrsyncpath().rsyncpath ?? "" + " "
        for i in 0 ..< self.args!.count {
            if i == 1 && self.config!.sshport != nil {
                self.argDisplay = self.argDisplay!  + "\"" + self.args![i] + "\"  "
            } else {
                self.argDisplay = self.argDisplay!  + self.args![i] + " "

            }
        }
    }

    func getArguments() -> [String]? {
        return self.args
    }

    func getArgumentsDisplay() -> String? {
        return self.argDisplay
    }

    func getCommand() -> String? {
        return nil
    }

    init(config: Configuration, remoteFile: String?, localCatalog: String?, drynrun: Bool?) {
        self.config = config
        self.args = [String]()
        self.arguments(remoteFile: remoteFile, localCatalog: localCatalog, drynrun: drynrun)
        self.argumentstodisplay()
    }
}
