//
//  Keypathidentityfile.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 28/05/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Foundation

struct Keypathidentityfile {
    var fullsshkeypath: String?
    // If global keypath and identityfile is set must split keypath and identifile
    // create a new key require full path
    var identityfile: String?
    var onlysshkeypath: String?
    var userHomeDirectoryPath: String? {
        let pw = getpwuid(getuid())
        if let home = pw?.pointee.pw_dir {
            let homePath = FileManager.default.string(withFileSystemRepresentation: home, length: Int(strlen(home)))
            return homePath
        } else {
            return nil
        }
    }

    init(sshkeypathandidentityfile: String) {
        if sshkeypathandidentityfile.first == "~" {
            // must drop identityfile and then set rootpath
            // also drop the "~" character
            var sshkeypathandidentityfilesplit = sshkeypathandidentityfile.split(separator: "/")
            guard sshkeypathandidentityfilesplit.count > 2 else {
                // If anything goes wrong set to default global values
                self.fullsshkeypath = (userHomeDirectoryPath ?? "") + "/.ssh"
                ViewControllerReference.shared.sshkeypathandidentityfile = nil
                self.identityfile = "id_rsa"
                self.onlysshkeypath = nil
                return
            }
            self.identityfile =
                String(sshkeypathandidentityfilesplit[sshkeypathandidentityfilesplit.count - 1])
            sshkeypathandidentityfilesplit.remove(at: sshkeypathandidentityfilesplit.count - 1)
            self.fullsshkeypath = (userHomeDirectoryPath ?? "") +
                sshkeypathandidentityfilesplit.joined(separator: "/").dropFirst()
            self.onlysshkeypath = String(sshkeypathandidentityfilesplit.joined(separator: "/").dropFirst())
        } else {
            // If anything goes wrong set to default global values
            self.fullsshkeypath = (userHomeDirectoryPath ?? "") + "/.ssh"
            ViewControllerReference.shared.sshkeypathandidentityfile = nil
            self.identityfile = "id_rsa"
            self.onlysshkeypath = nil
        }
    }
}
