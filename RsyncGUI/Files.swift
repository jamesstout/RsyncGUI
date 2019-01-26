//
//  files.swift
//  RsyncGUI
//
//  Created by Thomas Evensen on 26.04.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation

enum WhatRoot {
    case profileRoot
    case realRoot
    case sandboxedRoot
}

enum Fileerrortype {
    case openlogfile
    case writelogfile
    case profilecreatedirectory
    case profiledeletedirectory
    case filesize
    case sequrityscoped
}

// Protocol for reporting file errors
protocol Fileerror: class {
    func errormessage(errorstr: String, errortype: Fileerrortype)
}

protocol Reportfileerror {
    var errorDelegate: Fileerror? { get }
}

extension Reportfileerror {
    weak var errorDelegate: Fileerror? {
        return ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllertabMain
    }

    func error(error: String, errortype: Fileerrortype) {
        self.errorDelegate?.errormessage(errorstr: error, errortype: errortype)
    }
}

protocol Fileerrormessage {
    func errordescription(errortype: Fileerrortype) -> String
}

extension Fileerrormessage {
    func errordescription(errortype: Fileerrortype) -> String {
        switch errortype {
        case .openlogfile:
            guard ViewControllerReference.shared.fileURL != nil else {
                return "No logfile, creating a new one"
            }
            return "No logfile, creating a new one: " + String(describing: ViewControllerReference.shared.fileURL!)
        case .writelogfile:
            return "Could not write to logfile"
        case .profilecreatedirectory:
            return "Could not create profile directory"
        case .profiledeletedirectory:
            return "Could not delete profile directory"
        case .filesize:
            return "Filesize of logfile is getting bigger"
        case .sequrityscoped:
            return "Could not save SequrityScoped URL"
        }
    }
}

class Files: Reportfileerror {

    var whatroot: WhatRoot?
    var realrootpath: String?
    var sandboxedrootpath: String?
    var sshrealrootpath: String?
    private var configpath: String?
    var userHomeDirectoryPath: String {
        let pw = getpwuid(getuid())
        if let home = pw?.pointee.pw_dir {
            let homePath = FileManager.default.string(withFileSystemRepresentation: home, length: Int(strlen(home)))
            return homePath
        }
        return ""
    }

    private func setrootpath() {
        switch self.whatroot! {
        case .profileRoot:
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
            let docuDir = (paths.firstObject as? String)!
            let profilePath = docuDir + self.configpath! + Macserialnumber().getMacSerialNumber()!
            self.realrootpath = profilePath
        case .realRoot:
            self.realrootpath = self.userHomeDirectoryPath
            self.sshrealrootpath = self.userHomeDirectoryPath + "/.ssh/"
        case .sandboxedRoot:
             self.sandboxedrootpath = NSHomeDirectory()
        }
    }

    // Function for returning files in path as array of URLs
    func getFilesURLs() -> [URL]? {
        var array: [URL]?
        if let filePath = self.realrootpath {
            let fileManager = FileManager.default
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: filePath, isDirectory: &isDir) {
                guard isDir.boolValue else { return nil }
                } else { return nil }
                if let fileURLs = self.getfileURLs(path: filePath) {
                    array = [URL]()
                    for i in 0 ..< fileURLs.count where fileURLs[i].isFileURL {
                        array!.append(fileURLs[i])
                    }
                    return array
                }
            }
        return nil
    }

    // Function for returning files in path as array of Strings
    func getsshcatalogsfilestrings() -> [String]? {
        var array: [String]?
        if let filePath = self.sshrealrootpath {
            let fileManager = FileManager.default
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: filePath, isDirectory: &isDir) {
                guard isDir.boolValue else { return nil }
                } else { return nil }
                if let fileURLs = self.getfileURLs(path: filePath) {
                    array = [String]()
                    for i in 0 ..< fileURLs.count where fileURLs[i].isFileURL {
                        array!.append(fileURLs[i].path)
                    }
                    return array
                }
            }
        return nil
    }

    // Function for returning profiles as array of Strings
    func getDirectorysStrings() -> [String] {
        var array = [String]()
        if let filePath = self.realrootpath {
            if let fileURLs = self.getfileURLs(path: filePath) {
                for i in 0 ..< fileURLs.count where fileURLs[i].hasDirectoryPath {
                    let path = fileURLs[i].pathComponents
                    let i = path.count
                    array.append(path[i-1])
                }
                return array
            }
        }
        return array
    }

    // Func that creates directory if not created
    func createDirectory() {
        let fileManager = FileManager.default
        if let path = self.realrootpath {
            // Profile root
            if fileManager.fileExists(atPath: path) == false {
                do {
                    try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                } catch let e {
                    let error = e as NSError
                    self.error(error: error.description, errortype: .profilecreatedirectory)
                }
            }
        }
    }

    // Function for getting fileURLs for a given path
    func getfileURLs (path: String) -> [URL]? {
        let fileManager = FileManager.default
        if let filepath = URL.init(string: path) {
            do {
                let files = try fileManager.contentsOfDirectory(at: filepath, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                return files
            } catch let e {
                let error = e as NSError
                self.error(error: error.description, errortype: .profilecreatedirectory)
                return nil
            }
        } else {
            return nil
        }
    }

    init (root: WhatRoot, configpath: String) {
        self.configpath = configpath
        self.whatroot = root
        self.setrootpath()
    }
}
