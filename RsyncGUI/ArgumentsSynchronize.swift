//
//  ArgumentsSynchronize.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 13/10/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//

import Foundation

final class ArgumentsSynchronize: RsyncParameters {

    var config: Configuration?

    /// Function for initialize arguments array. RsyncOSX computes four argumentstrings
    /// two arguments for dryrun, one for rsync and one for display
    /// two arguments for realrun, one for rsync and one for display
    /// which argument to compute is set in parameter to function
    /// - parameter config: structure (configuration) holding configuration for one task
    /// - parameter dryRun: true if compute dryrun arguments, false if compute arguments for real run
    /// - paramater forDisplay: true if for display, false if not
    /// - returns: Array of Strings
    func argumentssynchronize(dryRun: Bool, forDisplay: Bool) -> [String] {
        self.localCatalog = self.config!.localCatalog
        self.remoteargs(config: self.config!)
        self.setParameters1To6(config: self.config!, dryRun: dryRun, forDisplay: forDisplay, verify: false)
        self.setParameters8To14(config: self.config!, dryRun: dryRun, forDisplay: forDisplay)
        switch self.config?.task {
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
