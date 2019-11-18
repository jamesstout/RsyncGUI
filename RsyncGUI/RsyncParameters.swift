//
//  RsyncParametersProcess.swift
//
//  Created by Thomas Evensen on 08/02/16.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
// swiftlint:disable cyclomatic_complexity

import Foundation

class RsyncParameters {

    var stats: Bool?
    var arguments: [String]?
    var localCatalog: String?
    var offsiteCatalog: String?
    var offsiteUsername: String?
    var offsiteServer: String?
    var remoteargs: String?
    var linkdestparam: String?

    func setParameters1To6(config: Configuration, dryRun: Bool, forDisplay: Bool, verify: Bool) {
        var parameter1: String?
        if verify {
            parameter1 = "--checksum"
        } else {
            parameter1 = config.parameter1
        }
        let parameter2: String = config.parameter2
        let parameter3: String = config.parameter3
        let parameter4: String = config.parameter4
        let parameter5: String = config.parameter5
        let offsiteServer: String = config.offsiteServer
        self.arguments!.append(parameter1 ?? "")
        if verify {
            if forDisplay {self.arguments!.append(" ")}
            self.arguments!.append("--recursive")
        }
        if forDisplay {self.arguments!.append(" ")}
        self.arguments!.append(parameter2)
        if forDisplay {self.arguments!.append(" ")}
        if offsiteServer.isEmpty  == false {
            if parameter3.isEmpty == false {
                self.arguments!.append(parameter3)
                if forDisplay {self.arguments!.append(" ")}
            }
        }
        if parameter4.isEmpty == false {
            self.arguments!.append(parameter4)
            if forDisplay {self.arguments!.append(" ")}
        }
        if offsiteServer.isEmpty {
            // nothing
        } else {
            if parameter5.isEmpty == false {
                self.sshportparameter(config: config, forDisplay: forDisplay)
            }
        }
    }

    // Compute user selected parameters parameter8 ... parameter14
    // Brute force, check every parameter, not special elegant, but it works
    func setParameters8To14(config: Configuration, dryRun: Bool, forDisplay: Bool) {
        self.stats = false
        if config.parameter8 != nil {
            self.appendParameter(parameter: config.parameter8!, forDisplay: forDisplay)
        }
        if config.parameter9 != nil {
            self.appendParameter(parameter: config.parameter9!, forDisplay: forDisplay)
        }
        if config.parameter10 != nil {
            self.appendParameter(parameter: config.parameter10!, forDisplay: forDisplay)
        }
        if config.parameter11 != nil {
            self.appendParameter(parameter: config.parameter11!, forDisplay: forDisplay)
        }
        if config.parameter12 != nil {
            self.appendParameter(parameter: config.parameter12!, forDisplay: forDisplay)
        }
        if config.parameter13 != nil {
            let split = config.parameter13!.components(separatedBy: "+$")
            if split.count == 2 {
                if split[1] == "date" {
                    self.appendParameter(parameter: split[0].setdatesuffixbackupstring, forDisplay: forDisplay)
                }
            } else {
                self.appendParameter(parameter: config.parameter13!, forDisplay: forDisplay)
            }
        }
        if config.parameter14 != nil {
            if config.offsiteServer.isEmpty == true {
                if config.parameter14! == SuffixstringsRsyncParameters().suffixstringfreebsd ||
                config.parameter14! == SuffixstringsRsyncParameters().suffixstringlinux {
                    self.appendParameter(parameter: self.setdatesuffixlocalhost(), forDisplay: forDisplay)
                }
            } else {
                self.appendParameter(parameter: config.parameter14!, forDisplay: forDisplay)
            }
        }
        // Append --stats parameter to collect info about run
        if dryRun {
            self.dryrunparameter(config: config, forDisplay: forDisplay)
        } else {
            if self.stats == false {
                self.appendParameter(parameter: "--stats", forDisplay: forDisplay)
            }
        }
    }

    func sshportparameter(config: Configuration, forDisplay: Bool) {
        let parameter5: String = config.parameter5
        let parameter6: String = config.parameter6
        // -e
        self.arguments!.append(parameter5)
        if forDisplay {self.arguments!.append(" ")}
        if let sshport = config.sshport {
            // "ssh -p xxx"
            if forDisplay {self.arguments!.append(" \"")}
            self.arguments!.append("ssh -p " + String(sshport))
            if forDisplay {self.arguments!.append("\" ")}
        } else {
            // ssh
            self.arguments!.append(parameter6)
        }
        if forDisplay {self.arguments!.append(" ")}
    }

    func setdatesuffixlocalhost() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "-yyyy-MM-dd"
        return  "--suffix=" + formatter.string(from: Date())
    }

    func dryrunparameter(config: Configuration, forDisplay: Bool) {
        let dryrun = "--dry-run"
        self.arguments!.append(dryrun)
        if forDisplay {self.arguments!.append(" ")}
        if self.stats! == false {
            self.arguments!.append("--stats")
            if forDisplay {self.arguments!.append(" ")}
        }
    }

    func appendParameter (parameter: String, forDisplay: Bool) {
        if parameter.count > 1 {
            if parameter == "--stats" {
                self.stats = true
            }
            self.arguments!.append(parameter)
            if forDisplay {
                self.arguments!.append(" ")
            }
        }
    }

    func remoteargs(config: Configuration) {
        self.offsiteCatalog = config.offsiteCatalog
        self.offsiteUsername = config.offsiteUsername
        self.offsiteServer = config.offsiteServer
        if self.offsiteServer!.isEmpty == false {
            if config.rsyncdaemon != nil {
                if config.rsyncdaemon == 1 {
                    self.remoteargs = self.offsiteUsername! + "@" + self.offsiteServer! + "::" + self.offsiteCatalog!
                } else {
                    self.remoteargs = self.offsiteUsername! + "@" + self.offsiteServer! + ":" + self.offsiteCatalog!
                }
            } else {
                self.remoteargs = self.offsiteUsername! + "@" + self.offsiteServer! + ":" + self.offsiteCatalog!
            }
        }
    }

    func remoteargssnapshot(config: Configuration) {
        self.offsiteCatalog = config.offsiteCatalog + "/"
        self.offsiteUsername = config.offsiteUsername
        self.offsiteServer = config.offsiteServer
        if self.offsiteServer!.isEmpty == false {
            if config.rsyncdaemon != nil {
                if config.rsyncdaemon == 1 {
                    self.remoteargs = self.offsiteUsername! + "@" + self.offsiteServer! + "::" + self.offsiteCatalog!
                } else {
                    self.remoteargs = self.offsiteUsername! + "@" + self.offsiteServer! + ":" + self.offsiteCatalog!
                }
            } else {
                self.remoteargs = self.offsiteUsername! + "@" + self.offsiteServer! + ":" + self.offsiteCatalog!
            }
        }
    }

    func argumentsforsynchronize(dryRun: Bool, forDisplay: Bool) {
        self.arguments!.append(self.localCatalog!)
        guard self.offsiteCatalog != nil else { return }
        if self.offsiteServer!.isEmpty {
            if forDisplay {self.arguments!.append(" ")}
            self.arguments!.append(self.offsiteCatalog!)
            if forDisplay {self.arguments!.append(" ")}
        } else {
            if forDisplay {self.arguments!.append(" ")}
            self.arguments!.append(remoteargs!)
            if forDisplay {self.arguments!.append(" ")}
        }
    }

    func argumentsforsynchronizesnapshot(dryRun: Bool, forDisplay: Bool) {
        guard self.linkdestparam != nil else {
            self.arguments!.append(self.localCatalog!)
            return
        }
        self.arguments!.append(self.linkdestparam!)
        if forDisplay {self.arguments!.append(" ")}
        self.arguments!.append(self.localCatalog!)
        if self.offsiteServer!.isEmpty {
            if forDisplay {self.arguments!.append(" ")}
            self.arguments!.append(self.offsiteCatalog!)
            if forDisplay {self.arguments!.append(" ")}
        } else {
            if forDisplay {self.arguments!.append(" ")}
            self.arguments!.append(remoteargs!)
            if forDisplay {self.arguments!.append(" ")}
        }
    }

    func argumentsforrestore(dryRun: Bool, forDisplay: Bool, tmprestore: Bool) {
        if self.offsiteServer!.isEmpty {
            self.arguments!.append(self.offsiteCatalog!)
            if forDisplay {self.arguments!.append(" ")}
        } else {
            if forDisplay {self.arguments!.append(" ")}
            self.arguments!.append(remoteargs!)
            if forDisplay {self.arguments!.append(" ")}
        }
        if tmprestore {
            let restorepath = ViewControllerReference.shared.restorePath ?? ""
            self.arguments!.append(restorepath)
        } else {
            self.arguments!.append(self.localCatalog!)
        }
    }

    init () {
        self.arguments = [String]()
    }
}
