//
//  AllProfilenames.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 15.05.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//

import Foundation

class AllProfilenames {
    var allprofiles: [String]?

    private func getprofilenames() {
        let profile = Catalogsandfiles(profileorsshrootpath: .profileroot)
        self.allprofiles = profile.getcatalogsasstringnames()
        guard self.allprofiles != nil else { return }
        self.allprofiles?.append("Default profile")
    }

    init() {
        self.getprofilenames()
    }
}
