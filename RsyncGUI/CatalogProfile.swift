//
//  profiles.swift
//  RsyncGUI
//
//  Created by Thomas Evensen on 17/10/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation

final class CatalogProfile: Files {
    // Function for creating new profile directory
    func createProfileDirectory(profileName: String) -> Bool {
        let fileManager = FileManager.default
        if let path = self.rootpath {
            let profileDirectory = path + "/" + profileName
            if fileManager.fileExists(atPath: profileDirectory) == false {
                do {
                    try fileManager.createDirectory(atPath: profileDirectory,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
                    return true
                } catch let e {
                    let error = e as NSError
                    self.error(error: error.description, errortype: .profilecreatedirectory)
                    return false
                }
            } else {
                return false
            }
        }
        return false
    }

    // Function for deleting profile
    func deleteProfileDirectory(profileName: String) {
        let fileManager = FileManager.default
        if let path = self.rootpath {
            let profileDirectory = path + "/" + profileName
            if fileManager.fileExists(atPath: profileDirectory) == true {
                let answer = Alerts.dialogOrCancel(question: "Delete profile: " + profileName + "?", text: "Cancel or OK", dialog: "Delete")
                if answer {
                    do {
                        try fileManager.removeItem(atPath: profileDirectory)
                    } catch let e {
                        let error = e as NSError
                        self.error(error: error.description, errortype: .profiledeletedirectory)
                    }
                }
            }
        }
    }

    init() {
        super.init(whichroot: .profileRoot, configpath: ViewControllerReference.shared.configpath)
    }
}
