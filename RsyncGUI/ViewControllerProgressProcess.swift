//
//  ViewControllerProgressProcess.swift
//  RsyncGUIver30
//
//  Created by Thomas Evensen on 24/08/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Cocoa

// Protocol for progress indicator
protocol Count: AnyObject {
    func maxCount() -> Int
    func inprogressCount() -> Int
}

class ViewControllerProgressProcess: NSViewController, SetConfigurations, SetDismisser, Abort {
    var count: Double = 0
    var maxcount: Double = 0
    weak var countDelegate: Count?
    @IBOutlet var abort: NSButton!
    @IBOutlet var progress: NSProgressIndicator!

    @IBAction func abort(_: NSButton) {
        switch self.countDelegate {
        case is ViewControllerMain:
            self.dismissview(viewcontroller: self, vcontroller: .vctabmain)
        case is ViewControllerRestore:
            self.dismissview(viewcontroller: self, vcontroller: .vcrestore)
        default:
            return
        }
        self.abort()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        ViewControllerReference.shared.setvcref(viewcontroller: .vcprogressview, nsviewcontroller: self)
        if (self.presentingViewController as? ViewControllerMain) != nil {
            if let pvc = (self.presentingViewController as? ViewControllerMain)?.singletask {
                self.countDelegate = pvc
            }
        }  else if (self.presentingViewController as? ViewControllerRestore) != nil {
            self.countDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcrestore) as? ViewControllerRestore
        }
        self.initiateProgressbar()
        self.abort.isEnabled = true
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        self.stopProgressbar()
        ViewControllerReference.shared.setvcref(viewcontroller: .vcprogressview, nsviewcontroller: nil)
    }

    private func stopProgressbar() {
        self.progress.stopAnimation(self)
    }

    // Progress bars
    private func initiateProgressbar() {
        self.progress.maxValue = Double(self.countDelegate?.maxCount() ?? 0)
        self.progress.minValue = 0
        self.progress.doubleValue = 0
        self.progress.startAnimation(self)
    }

    private func updateProgressbar(_ value: Double) {
        self.progress.doubleValue = value
    }
}

extension ViewControllerProgressProcess: UpdateProgress {
    func processTermination() {
        self.stopProgressbar()
        switch self.countDelegate {
        case is ViewControllerMain:
            self.dismissview(viewcontroller: self, vcontroller: .vctabmain)
        default:
            self.dismissview(viewcontroller: self, vcontroller: .vctabmain)
        }
    }

    func fileHandler() {
        guard self.countDelegate != nil else { return }
        self.updateProgressbar(Double(self.countDelegate!.inprogressCount()))
    }
}
