//
//  ViewControllerEstimatingTasks.swift
//  RsyncGUI
//
//  Created by Thomas Evensen on 21.04.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation
import Cocoa

// Protocol for progress indicator
protocol CountRemoteEstimatingNumberoftasks: class {
    func maxCount() -> Int
    func inprogressCount() -> Int
}

class ViewControllerEstimatingTasks: NSViewController, Abort, SetConfigurations, SetDismisser {

    var count: Double = 0
    var maxcount: Double = 0
    var calculatedNumberOfFiles: Int?
    
    weak var countDelegate: CountRemoteEstimatingNumberoftasks?
    private var remoteinfotask: RemoteinfoEstimation?
    var diddissappear: Bool = false

    @IBOutlet weak var abort: NSButton!
    @IBOutlet weak var progress: NSProgressIndicator!

    @IBAction func abort(_ sender: NSButton) {
        self.abort()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ViewControllerReference.shared.setvcref(viewcontroller: .vcestimatingtasks, nsviewcontroller: self)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        guard self.diddissappear == false else { return }
        self.abort.isEnabled = true
        self.remoteinfotask = RemoteinfoEstimation(viewvcontroller: self)
        self.initiateProgressbar()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        self.diddissappear = true
    }
    
    // Progress bars
    private func initiateProgressbar() {
        self.progress.maxValue = Double(self.remoteinfotask?.maxCount() ?? 0)
        self.progress.minValue = 0
        self.progress.doubleValue = 0
        self.progress.startAnimation(self)
    }
    
    private func updateProgressbar(_ value: Double) {
        self.progress.doubleValue = value
    }
    
    private func closeview() {
        if (self.presentingViewController as? ViewControllertabMain) != nil {
            self.dismissview(viewcontroller: self, vcontroller: .vctabmain)
        } else if (self.presentingViewController as? ViewControllerNewConfigurations) != nil {
            self.dismissview(viewcontroller: self, vcontroller: .vcnewconfigurations)
        } else if (self.presentingViewController as? ViewControllerCopyFiles) != nil {
            self.dismissview(viewcontroller: self, vcontroller: .vccopyfiles)
        } else if (self.presentingViewController as? ViewControllerSsh) != nil {
            self.dismissview(viewcontroller: self, vcontroller: .vcssh)
        } else if (self.presentingViewController as? ViewControllerVerify) != nil {
            self.dismissview(viewcontroller: self, vcontroller: .vcverify)
        } else if (self.presentingViewController as? ViewControllerLoggData) != nil {
            self.dismissview(viewcontroller: self, vcontroller: .vcloggdata)
        }
    }
}

extension ViewControllerEstimatingTasks: UpdateProgress {
    func processTermination() {
        let progress = Double(self.remoteinfotask?.maxCount() ?? 0) - Double(self.remoteinfotask?.inprogressCount() ?? 0)
        self.updateProgressbar(progress)
    }
    
    func fileHandler() {
        //
    }
}

extension ViewControllerEstimatingTasks: StartStopProgressIndicator {
    func start() {
        //
    }
    
    func complete() {
        //
    }
    
    func stop() {
        weak var openDelegate: OpenQuickBackup?
        if (self.presentingViewController as? ViewControllertabMain) != nil {
            openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllertabMain
        } else if (self.presentingViewController as? ViewControllerNewConfigurations) != nil {
            openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcnewconfigurations) as? ViewControllerNewConfigurations
        } else if (self.presentingViewController as? ViewControllerCopyFiles) != nil {
            openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vccopyfiles) as? ViewControllerCopyFiles
        } else if (self.presentingViewController as? ViewControllerSsh) != nil {
            openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcssh) as? ViewControllerSsh
        } else if (self.presentingViewController as? ViewControllerVerify) != nil {
            openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcverify) as? ViewControllerVerify
        } else if (self.presentingViewController as? ViewControllerLoggData) != nil {
            openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcloggdata) as? ViewControllerLoggData
        }
        self.closeview()
        openDelegate?.openquickbackup()
    }
}
