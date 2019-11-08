//
//  Readwritefiles.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 25/10/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
//  let str = "/Rsync/" + serialNumber + profile? + "/scheduleRsync.plist"
//  let str = "/Rsync/" + serialNumber + profile? + "/configRsync.plist"
//  let str = "/Rsync/" + serialNumber + "/config.plist"
//

import Foundation
import Cocoa

enum WhatToReadWrite {
    case schedule
    case configuration
    case userconfig
    case none
}

class ReadWriteDictionary {

    // Name set for schedule, configuration or config
    private var plistname: String?
    // key in objectForKey, e.g key for reading what
    private var key: String?
    // Which profile to read
    var profile: String?
    // task to do
    private var task: WhatToReadWrite?
    // Path for configuration files
    private var filepath: String?
    // Set which file to read
    private var filename: String?
    // config path either
    // ViewControllerReference.shared.configpath or RcloneReference.shared.configpath
    private var configpath: String?

    private func setnameandpath() {
        let docupath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let docuDir = docupath.firstObject as? String ?? ""
        if ViewControllerReference.shared.macserialnumber == nil {
            ViewControllerReference.shared.macserialnumber = Macserialnumber().getMacSerialNumber() ?? ""
        }
        let macserialnumber = ViewControllerReference.shared.macserialnumber
        let profilePath = CatalogProfile()
        profilePath.createDirectory()
        // Use profile
        if let profile = self.profile {
            guard profile.isEmpty == false else { return }
            let profilePath = CatalogProfile()
            profilePath.createDirectory()
            self.filepath = self.configpath! + macserialnumber! + "/" + profile + "/"
            self.filename = docuDir + self.configpath! + macserialnumber! + "/" + profile + self.plistname!
        } else {
        // no profile
            self.filename = docuDir + self.configpath! + macserialnumber! + self.plistname!
            self.filepath = self.configpath! + macserialnumber! + "/"
        }
    }

    // Function for reading data from persistent store
    func readNSDictionaryFromPersistentStore() -> [NSDictionary]? {
        var data = [NSDictionary]()
        guard self.filename != nil && self.key != nil else { return nil }
        let dictionary = NSDictionary(contentsOfFile: self.filename!)
        let items: Any? = dictionary?.object(forKey: self.key!)
        guard items != nil else { return nil }
        if let arrayofitems = items as? NSArray {
            for i in 0 ..< arrayofitems.count {
                if let item = arrayofitems[i] as? NSDictionary {
                    data.append(item)
                }
            }
        }
        return data
    }

    // Function for write data to persistent store
    func writeNSDictionaryToPersistentStorage(array: [NSDictionary]) -> Bool {
        let dictionary = NSDictionary(object: array, forKey: self.key! as NSCopying)
        guard self.filename != nil else { return false }
        let write = dictionary.write(toFile: self.filename!, atomically: true)
        return write
    }

    // Set preferences for which data to read or write
    private func setpreferences (whattoreadwrite: WhatToReadWrite) {
        self.task = whattoreadwrite
        switch self.task! {
        case .schedule:
            self.plistname = "/scheduleRsync.plist"
            self.key = "Schedule"
        case .configuration:
            self.plistname = "/configRsync.plist"
            self.key = "Catalogs"
        case .userconfig:
            self.plistname = "/config.plist"
            self.key = "config"
        case .none:
            self.plistname = nil
        }
    }

    init(whattoreadwrite: WhatToReadWrite, profile: String?, configpath: String) {
        self.configpath = configpath
        self.profile = profile
        self.setpreferences(whattoreadwrite: whattoreadwrite)
        self.setnameandpath()
    }

}
