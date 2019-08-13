//
//  EstimateRemoteInformationTask.swift
//  RsyncGUI
//
//  Created by Thomas Evensen on 31.12.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation

final class EstimateRemoteInformationTask: SetConfigurations {
    var arguments: [String]?
    init(index: Int, outputprocess: OutputProcess?, local: Bool) {
        weak var setprocessDelegate: SendProcessreference?
        setprocessDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllertabMain
        if local {
            self.arguments = self.configurations!.arguments4rsync(index: index, argtype: .argdryRunlocalcataloginfo)
        } else {
            self.arguments = self.configurations!.arguments4rsync(index: index, argtype: .argdryRun)
        }
        let process = Rsync(arguments: self.arguments)
        process.executeProcess(outputprocess: outputprocess)
        setprocessDelegate?.sendprocessreference(process: process.getProcess()!)
        setprocessDelegate?.sendoutputprocessreference(outputprocess: outputprocess)
    }
}
