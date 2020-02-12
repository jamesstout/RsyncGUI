//
//  ViewControllerEstimatingTasks.swift
//  RsyncGUI
//
//  Created by Thomas Evensen on 21.04.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Cocoa
import Foundation

// Protocol for progress indicator
protocol CountRemoteEstimatingNumberoftasks: AnyObject {
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

    @IBOutlet var abort: NSButton!
    @IBOutlet var progress: NSProgressIndicator!

    @IBAction func abort(_: NSButton) {
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
        if (self.presentingViewController as? ViewControllerMain) != nil {
            self.dismissview(viewcontroller: self, vcontroller: .vctabmain)
        } else if (self.presentingViewController as? ViewControllerNewConfigurations) != nil {
            self.dismissview(viewcontroller: self, vcontroller: .vcnewconfigurations)
        } else if (self.presentingViewController as? ViewControllerSsh) != nil {
            self.dismissview(viewcontroller: self, vcontroller: .vcssh)
        } else if (self.presentingViewController as? ViewControllerVerify) != nil {
            self.dismissview(viewcontroller: self, vcontroller: .vcverify)
        } else if (self.presentingViewController as? ViewControllerLoggData) != nil {
            self.dismissview(viewcontroller: self, vcontroller: .vcloggdata)
        } else if (self.presentingViewController as? ViewControllerRestore) != nil {
            self.dismissview(viewcontroller: self, vcontroller: .vcrestore)
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
        if (self.presentingViewController as? ViewControllerMain) != nil {
            openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllerMain
        } else if (self.presentingViewController as? ViewControllerNewConfigurations) != nil {
            openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcnewconfigurations) as? ViewControllerNewConfigurations
        } else if (self.presentingViewController as? ViewControllerSsh) != nil {
            openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcssh) as? ViewControllerSsh
        } else if (self.presentingViewController as? ViewControllerVerify) != nil {
            openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcverify) as? ViewControllerVerify
        } else if (self.presentingViewController as? ViewControllerLoggData) != nil {
            openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcloggdata) as? ViewControllerLoggData
        } else if (self.presentingViewController as? ViewControllerRestore) != nil {
            openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcrestore) as? ViewControllerRestore
        }
        self.closeview()
        openDelegate?.openquickbackup()
    }
}
