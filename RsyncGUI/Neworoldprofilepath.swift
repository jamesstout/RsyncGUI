//
//  Neworoldprofilepath.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 29/08/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Files
import Foundation

struct Neworoldprofilepath {
    var oldpath: String?
    var newpath: String?
    var usenewpath: Bool = false
    var useoldpath: Bool = false

    func verifyoldpath() -> Bool {
        if let oldpath = self.oldpath {
            do {
                _ = try Folder(path: oldpath)
                return true
            } catch {
                return false
            }
        }
        return false
    }

    func verifynewpath() -> Bool {
        if let newpath = self.newpath {
            do {
                _ = try Folder(path: newpath)
                return true
            } catch {
                return false
            }
        }
        return false
    }

    init() {
        ViewControllerReference.shared.usenewconfigpath = false
    }
}
