//
//  ViewControllerSsh.swift
//  RsyncGUI
//
//  Created by Thomas Evensen on 23.04.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
//  swiftlint:disable line_length cyclomatic_complexity

import Cocoa
import Foundation

protocol ResetSequrityScopedURL: AnyObject {
    func resetsequrityscopedurl()
}

protocol SaveSequrityScopedURL: AnyObject {
    func savesequrityscopedurl(urlpath: URL)
}

protocol Loadsshparameters: AnyObject {
    func loadsshparameters()
}

protocol GetSource: AnyObject {
    func getSourceindex(index: Int)
}

class ViewControllerSsh: NSViewController, SetConfigurations, VcMain, Checkforrsync, Help {
    var sshcmd: Ssh?
    var hiddenID: Int?
    var data: [String]?
    var outputprocess: OutputProcess?
    var execute: Bool = false
    // Send messages to the sidebar
    weak var sidebaractionsDelegate: Sidebaractions?

    @IBOutlet var rsaCheck: NSButton!
    @IBOutlet var detailsTable: NSTableView!
    @IBOutlet var copykeycommand: NSTextField!
    @IBOutlet var sshport: NSTextField!
    @IBOutlet var sshkeypathandidentityfile: NSTextField!
    @IBOutlet var verifykeycommand: NSTextField!
    @IBOutlet var SequrityScopedTable: NSTableView!

    // Selecting profiles
    @IBAction func profiles(_: NSButton) {
        self.presentAsModalWindow(self.viewControllerProfile!)
    }

    func resetsequrityscoped() {
        let answer = Alerts.dialogOrCancel(question: "You are about to reset RsynGUI access to your files", text: "Please close and start RsyncGUI again", dialog: "Reset")
        if answer {
            weak var resetsequrityscopedDelegate: ResetSequrityScopedURL?
            resetsequrityscopedDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllerMain
            resetsequrityscopedDelegate?.resetsequrityscopedurl()
        }
    }

    @IBAction func showHelp(_: AnyObject?) {
        self.help()
    }

    func createPublicPrivateRSAKeyPair() {
        self.outputprocess = OutputProcess()
        self.sshcmd = Ssh(outputprocess: self.outputprocess,
                          processtermination: self.processtermination,
                          filehandler: self.filehandler)
        guard self.sshcmd?.islocalpublicrsakeypresent() ?? true == false else { return }
        self.sshcmd?.creatersakeypair()
    }

    func source() {
        guard self.sshcmd != nil else { return }
        self.presentAsModalWindow(self.viewControllerSource!)
    }

    var viewControllerSource: NSViewController? {
        return (self.sheetviewsstoryboard?.instantiateController(withIdentifier: "CopyFilesID")
            as? NSViewController)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ViewControllerReference.shared.setvcref(viewcontroller: .vcssh, nsviewcontroller: self)
        self.detailsTable.delegate = self
        self.detailsTable.dataSource = self
        self.SequrityScopedTable.delegate = self
        self.SequrityScopedTable.dataSource = self
        self.outputprocess = nil
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.sidebaractionsDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcsidebar) as? ViewControllerSideBar
        self.sidebaractionsDelegate?.sidebaractions(action: .sshviewbuttons)
        self.loadsshparameters()
        globalMainQueue.async { () -> Void in
            self.SequrityScopedTable.reloadData()
        }
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.copykeycommand.stringValue = ""
        self.verifykeycommand.stringValue = ""
    }

    private func checkforPrivateandPublicRSAKeypair() {
        self.sshcmd = Ssh(outputprocess: nil,
                          processtermination: self.processtermination,
                          filehandler: self.filehandler)
        if self.sshcmd?.islocalpublicrsakeypresent() ?? false {
            self.rsaCheck.state = .on
        } else {
            self.rsaCheck.state = .off
        }
    }

    func copylocalpubrsakeyfile() {
        guard self.sshcmd?.islocalpublicrsakeypresent() ?? false == true else { return }
        self.outputprocess = OutputProcess()
        self.sshcmd = Ssh(outputprocess: self.outputprocess,
                          processtermination: self.processtermination,
                          filehandler: self.filehandler)
        if let hiddenID = self.hiddenID {
            self.sshcmd?.copykeyfile(hiddenID: hiddenID)
            self.copykeycommand.stringValue = sshcmd?.commandCopyPasteTerminal ?? ""
            self.sshcmd?.verifyremotekey(hiddenID: hiddenID)
            self.verifykeycommand.stringValue = sshcmd?.commandCopyPasteTerminal ?? ""
        }
    }
}

extension ViewControllerSsh: DismissViewController {
    func dismiss_view(viewcontroller: NSViewController) {
        self.dismiss(viewcontroller)
        self.copylocalpubrsakeyfile()
        self.loadsshparameters()
    }
}

extension ViewControllerSsh: GetSource {
    func getSourceindex(index: Int) {
        self.hiddenID = index
        if let config = self.configurations?.getConfigurations()?[self.configurations?.getIndex(hiddenID ?? 0) ?? 0] {
            if config.offsiteServer.isEmpty == true {
                self.execute = false
            } else {
                self.execute = true
            }
        }
    }
}

extension ViewControllerSsh: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == self.detailsTable {
            return self.data?.count ?? 0
        } else {
            return self.configurations?.SequrityScopedURLs?.unique().count ?? 0
        }
    }
}

extension ViewControllerSsh: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if let tableColumn = tableColumn {
            if tableView == self.detailsTable {
                switch tableColumn.identifier.rawValue {
                case "outputID":
                    return self.data?[row] ?? ""
                default:
                    return nil
                }
            } else {
                guard self.configurations?.SequrityScopedURLs?.unique() != nil else { return nil }
                guard row < (self.configurations?.SequrityScopedURLs?.unique().count ?? -1) else { return nil }
                if let object: NSDictionary = self.configurations?.SequrityScopedURLs?.unique()[row] {
                    switch tableColumn.identifier.rawValue {
                    case DictionaryStrings.SecurityScoped.rawValue:
                        if (object.value(forKey: DictionaryStrings.SecurityScoped.rawValue) as? Bool) == true {
                            return #imageLiteral(resourceName: "green")
                        } else {
                            return #imageLiteral(resourceName: "red")
                        }
                    case DictionaryStrings.rootcatalog.rawValue:
                        return (object.value(forKey: DictionaryStrings.rootcatalog.rawValue) as? NSURL)?.absoluteString ?? ""
                    case DictionaryStrings.localcatalog.rawValue:
                        return (object.value(forKey: DictionaryStrings.localcatalog.rawValue) as? NSURL)?.absoluteString ?? ""
                    default:
                        return nil
                    }
                }
            }
            return nil
        }
        return nil
    }
}

extension ViewControllerSsh {
    func processtermination() {
        globalMainQueue.async { () -> Void in
            self.checkforPrivateandPublicRSAKeypair()
        }
    }

    func filehandler() {
        self.data = self.outputprocess?.getOutput()
        globalMainQueue.async { () -> Void in
            self.detailsTable.reloadData()
        }
    }
}

extension ViewControllerSsh: OpenQuickBackup {
    func openquickbackup() {
        globalMainQueue.async { () -> Void in
            self.presentAsSheet(self.viewControllerQuickBackup!)
        }
    }
}

extension ViewControllerSsh: Loadsshparameters {
    func loadsshparameters() {
        self.sshkeypathandidentityfile.stringValue = ViewControllerReference.shared.sshkeypathandidentityfile ?? ""
        if let sshport = ViewControllerReference.shared.sshport {
            self.sshport.stringValue = String(sshport)
        } else {
            self.sshport.stringValue = ""
        }
        self.checkforPrivateandPublicRSAKeypair()
    }
}

extension ViewControllerSsh: Sidebarbuttonactions {
    func sidebarbuttonactions(action: Sidebaractionsmessages) {
        switch action {
        case .CreateKey:
            self.createPublicPrivateRSAKeyPair()
        case .Remote:
            self.source()
        case .Reset:
            self.resetsequrityscoped()
        default:
            return
        }
    }
}
