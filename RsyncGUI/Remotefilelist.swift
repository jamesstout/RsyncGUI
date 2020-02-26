//
//  Remotefilelist.swift
//  RsyncGUI
//
//  Created by Thomas Evensen on 14/06/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation

class Remotefilelist: ProcessCmd, SetConfigurations {
    var outputprocess: OutputProcess?
    var config: Configuration?
    var remotefilelist: [String]?
    weak var setremotefilelistDelegate: Updateremotefilelist?
    weak var outputeverythingDelegate: ViewOutputDetails?
    weak var sendprocess: SendProcessreference?

    init(hiddenID: Int) {
        super.init(command: nil, arguments: nil)
        self.sendprocess = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllerMain
        self.setremotefilelistDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcrestore) as? ViewControllerRestore
        self.outputeverythingDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllerMain
        let index = self.configurations?.getIndex(hiddenID: hiddenID) ?? -1
        self.config = self.configurations!.getConfigurations()[index]
        self.outputprocess = OutputProcess()
        self.sendprocess?.sendoutputprocessreference(outputprocess: self.outputprocess)
        self.arguments = RestorefilesArguments(task: .rsyncfilelistings, config: self.config,
                                               remoteFile: nil, localCatalog: nil, drynrun: nil).getArguments()
        self.command = RestorefilesArguments(task: .rsyncfilelistings, config: self.config,
                                             remoteFile: nil, localCatalog: nil, drynrun: nil).getCommand()
        self.setupdateDelegate(object: self)

        self.executeProcess(outputprocess: self.outputprocess)
    }
}

extension Remotefilelist: UpdateProgress {
    func processTermination() {
        self.remotefilelist = self.outputprocess?.trimoutput(trim: .one)
        self.setremotefilelistDelegate?.updateremotefilelist()
    }

    func fileHandler() {
        if self.outputeverythingDelegate?.appendnow() ?? false {
            outputeverythingDelegate?.reloadtable()
        }
    }
}
