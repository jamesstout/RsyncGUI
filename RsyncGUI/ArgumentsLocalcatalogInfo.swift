//
//  ArgumentsLocalcatalogInfo.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 13/10/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//

import Foundation

final class ArgumentsLocalcatalogInfo: RsyncParameters {
    var config: Configuration?

    func argumentslocalcataloginfo(dryRun: Bool, forDisplay: Bool) -> [String] {
        self.localCatalog = self.config!.localCatalog
        self.setParameters1To6(config: self.config!, dryRun: dryRun, forDisplay: forDisplay, verify: false)
        self.setParameters8To14(config: self.config!, dryRun: dryRun, forDisplay: forDisplay)
        switch self.config!.task {
        case ViewControllerReference.shared.synchronize:
            self.argumentsforsynchronize(dryRun: dryRun, forDisplay: forDisplay)
        default:
            break
        }
        return self.arguments ?? [""]
    }

    init(config: Configuration?) {
        super.init()
        self.config = config
    }
}
