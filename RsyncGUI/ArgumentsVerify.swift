//
//  ArgumentsVerify.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 13/10/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//

import Foundation

final class ArgumentsVerify: RsyncParameters {

    var config: Configuration?

     func argumentsverify(forDisplay: Bool) -> [String] {
        self.localCatalog = self.config!.localCatalog
        self.remoteargs(config: self.config!)
        self.setParameters1To6(config: self.config!, dryRun: true, forDisplay: forDisplay, verify: true)
        self.setParameters8To14(config: self.config!, dryRun: true, forDisplay: forDisplay)
        switch self.config!.task {
           case ViewControllerReference.shared.synchronize:
        self.argumentsforsynchronize(dryRun: true, forDisplay: forDisplay)
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
