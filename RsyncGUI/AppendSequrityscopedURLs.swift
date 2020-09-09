//
//  AppendSequrityscopedURLs.swift
//  RsyncGUI
//
//  Created by Thomas Evensen on 06/07/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//

import Foundation

struct AppendSequrityscopedURLs {
    var success: Bool = false
    var urlpath: URL?

    private func accessFiles(fileURL: URL) -> Bool {
        let permissionmanager = PermissionManager(bookmarksManager: BookmarksManager.defaultManager)
        let permission = permissionmanager.accessAndIfNeededAskUserForSecurityScopeForFileAtURL(fileURL: fileURL)
        let success = FileManager.default.isReadableFile(atPath: fileURL.path)
        return permission && success
    }

    init(path: String) {
        self.urlpath = URL(fileURLWithPath: path)
        guard self.urlpath != nil else { return }
        self.success = self.accessFiles(fileURL: self.urlpath!)
    }
}
