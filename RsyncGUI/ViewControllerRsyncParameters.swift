//
//  ViewControllerRsyncParameters.swift
//  Rsync
//  The ViewController for rsync parameters.
//
//  Created by Thomas Evensen on 13/02/16.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
//  swiftlint:disable line_length function_body_length type_body_length

import Foundation
import Cocoa

// protocol for returning if userparams is updated or not
protocol RsyncUserParams: class {
    func rsyncuserparamsupdated()
}

// Protocol for sending selected index in tableView
// The protocol is implemented in ViewControllertabMain
protocol GetSelecetedIndex {
    func getindex() -> Int?
}

class ViewControllerRsyncParameters: NSViewController, SetConfigurations, SetDismisser, Index {

    var parameters: RsyncParameters?
    weak var userparamsupdatedDelegate: RsyncUserParams?
    var comboBoxValues = [String]()
    var diddissappear: Bool = false

    @IBOutlet weak var param1: NSTextField!
    @IBOutlet weak var param2: NSTextField!
    @IBOutlet weak var param3: NSTextField!
    @IBOutlet weak var param4: NSTextField!
    @IBOutlet weak var param5: NSTextField!

    @IBOutlet weak var param8: NSTextField!
    @IBOutlet weak var param9: NSTextField!
    @IBOutlet weak var param10: NSTextField!
    @IBOutlet weak var param11: NSTextField!
    @IBOutlet weak var param12: NSTextField!
    @IBOutlet weak var param13: NSTextField!
    @IBOutlet weak var param14: NSTextField!
    @IBOutlet weak var rsyncdaemon: NSButton!
    @IBOutlet weak var sshport: NSTextField!
    @IBOutlet weak var compressparameter: NSButton!
    @IBOutlet weak var esshparameter: NSButton!
    @IBOutlet weak var deleteparamater: NSButton!

    @IBOutlet weak var combo8: NSComboBox!
    @IBOutlet weak var combo9: NSComboBox!
    @IBOutlet weak var combo10: NSComboBox!
    @IBOutlet weak var combo11: NSComboBox!
    @IBOutlet weak var combo12: NSComboBox!
    @IBOutlet weak var combo13: NSComboBox!
    @IBOutlet weak var combo14: NSComboBox!

    @IBAction func close(_ sender: NSButton) {
        self.dismissview(viewcontroller: self, vcontroller: .vctabmain)
    }

    @IBAction func togglersyncdaemon(_ sender: NSButton) {
        if let index = self.index() {
            switch self.rsyncdaemon.state {
            case .on:
                self.configurations!.removeesshparameter(index: index, delete: true)
                self.param5.stringValue = self.configurations!.getConfigurations()[index].parameter5
                self.esshparameter.state = .on
            case .off:
                self.configurations!.removeesshparameter(index: index, delete: false)
                self.param5.stringValue = self.configurations!.getConfigurations()[index].parameter5 + " ssh"
                self.esshparameter.state = .off
            default:
                return
            }
        }
    }

    @IBAction func removecompressparameter(_ sender: NSButton) {
        if let index = self.index() {
            switch self.compressparameter.state {
            case .on:
                self.configurations!.removecompressparameter(index: index, delete: true)
            case .off:
                self.configurations!.removecompressparameter(index: index, delete: false)
            default:
                break
            }
            self.param3.stringValue = self.configurations!.getConfigurations()[index].parameter3
        }
    }

    @IBAction func removeesshparameter(_ sender: NSButton) {
        if let index = self.index() {
            switch self.esshparameter.state {
            case .on:
                self.configurations!.removeesshparameter(index: index, delete: true)
                self.param5.stringValue = self.configurations!.getConfigurations()[index].parameter5
            case .off:
                self.configurations!.removeesshparameter(index: index, delete: false)
                self.param5.stringValue = self.configurations!.getConfigurations()[index].parameter5 + " ssh"
            default:
                break
            }
        }
    }

    @IBAction func removedeleteparameter(_ sender: NSButton) {
        if let index = self.index() {
            switch self.deleteparamater.state {
            case .on:
                self.configurations!.removeedeleteparameter(index: index, delete: true)
            case .off:
                self.configurations!.removeedeleteparameter(index: index, delete: false)
            default:
                break
            }
            self.param4.stringValue = self.configurations!.getConfigurations()[index].parameter4
        }
    }

    // Function for enabling backup of changed files in a backup catalog.
    // Parameters are appended to last two parameters (12 and 13).
    @IBAction func backup(_ sender: NSButton) {
        if let index = self.index() {
                   let configurations: [Configuration] = self.configurations!.getConfigurations()
                   let param = ComboboxRsyncParameters(config: configurations[index])
                   switch self.backupbutton.state {
                   case .on:
                       self.initcombox(combobox: self.combo12, index: (param.indexandvaluersyncparameter(SuffixstringsRsyncParameters().backupstrings[0]).0))
                       self.param12.stringValue = param.indexandvaluersyncparameter(SuffixstringsRsyncParameters().backupstrings[0]).1
                       let hiddenID = self.configurations!.gethiddenID(index: (self.index())!)
                       guard hiddenID > -1 else { return }
                       let localcatalog = self.configurations!.getResourceConfiguration(hiddenID: hiddenID, resource: .localCatalog)
                       let localcatalogParts = (localcatalog as AnyObject).components(separatedBy: "/")
                       self.initcombox(combobox: self.combo13, index: (param.indexandvaluersyncparameter(SuffixstringsRsyncParameters().backupstrings[1]).0))
                       self.param13.stringValue = "../backup" + "_" + localcatalogParts[localcatalogParts.count - 2]
                   case .off:
                       self.initcombox(combobox: self.combo12, index: (0))
                       self.param12.stringValue = ""
                       self.initcombox(combobox: self.combo13, index: (0))
                       self.param13.stringValue = ""
                       self.initcombox(combobox: self.combo14, index: (0))
                       self.param14.stringValue = ""
                   default : break
                   }
               }
    }

    // Function for enabling suffix date + time changed files. 
    // Parameters are appended to last parameter (14).
    @IBOutlet weak var suffixButton: NSButton!
    @IBAction func suffix(_ sender: NSButton) {
        if let index = self.index() {
                   self.suffixButton2.state = .off
                   let configurations: [Configuration] = self.configurations!.getConfigurations()
                   let param = ComboboxRsyncParameters(config: configurations[index])
                   switch self.suffixButton.state {
                   case .on:
                       let suffix = SuffixstringsRsyncParameters().suffixstringfreebsd
                       self.initcombox(combobox: self.combo14, index: (param.indexandvaluersyncparameter(suffix).0))
                       self.param14.stringValue = param.indexandvaluersyncparameter(suffix).1
                   case .off:
                       self.initcombox(combobox: self.combo14, index: (0))
                       self.param14.stringValue = ""
                   default:
                       break
                   }
               }
    }

    @IBOutlet weak var suffixButton2: NSButton!
    @IBAction func suffix2(_ sender: NSButton) {
       if let index = self.index() {
            let configurations: [Configuration] = self.configurations!.getConfigurations()
            let param = ComboboxRsyncParameters(config: configurations[index])
            self.suffixButton.state = .off
            switch self.suffixButton2.state {
            case .on:
                let suffix = SuffixstringsRsyncParameters().suffixstringlinux
                self.initcombox(combobox: self.combo14, index: (param.indexandvaluersyncparameter(suffix).0))
                self.param14.stringValue = param.indexandvaluersyncparameter(suffix).1
            case .off:
                self.initcombox(combobox: self.combo14, index: (0))
                self.param14.stringValue = ""
            default:
                break
            }
        }
    }

    @IBOutlet weak var backupbutton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.userparamsupdatedDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllerMain
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        guard self.diddissappear == false else { return }
        if let index = self.index() {
            let configurations: [Configuration] = self.configurations!.getConfigurations()
            let param = ComboboxRsyncParameters(config: configurations[index])
            self.comboBoxValues = param.getComboBoxValues()
            self.backupbutton.state = .off
            self.suffixButton.state = .off
            self.suffixButton2.state = .off
            self.param1.stringValue = configurations[index].parameter1
            self.param2.stringValue = configurations[index].parameter2
            self.param3.stringValue = configurations[index].parameter3
            self.param4.stringValue = configurations[index].parameter4
            if configurations[index].parameter5.isEmpty == false {
                self.param5.stringValue = configurations[index].parameter5 + " " + configurations[index].parameter6
            }
            if configurations[index].parameter3.isEmpty == true {
                self.compressparameter.state = .on
            } else {
                self.compressparameter.state = .off
            }
            if configurations[index].parameter4.isEmpty == true {
                self.self.deleteparamater.state = .on
            } else {
                self.deleteparamater.state = .off
            }
            if configurations[index].parameter5.isEmpty == true {
                self.esshparameter.state = .on
            } else {
                self.esshparameter.state = .off
            }
            let value8 = param.getParameter(rsyncparameternumber: 8).0
            self.initcombox(combobox: self.combo8, index: value8)
            self.param8.stringValue = param.getParameter(rsyncparameternumber: 8).1
            let value9 = param.getParameter(rsyncparameternumber: 9).0
            self.initcombox(combobox: self.combo9, index: value9)
            self.param9.stringValue = param.getParameter(rsyncparameternumber: 9).1
            let value10 = param.getParameter(rsyncparameternumber: 10).0
            self.initcombox(combobox: self.combo10, index: value10)
            self.param10.stringValue = param.getParameter(rsyncparameternumber: 10).1
            let value11 = param.getParameter(rsyncparameternumber: 11).0
            self.initcombox(combobox: self.combo11, index: value11)
            self.param11.stringValue = param.getParameter(rsyncparameternumber: 11).1
            let value12 = param.getParameter(rsyncparameternumber: 12).0
            self.initcombox(combobox: self.combo12, index: value12)
            self.param12.stringValue = param.getParameter(rsyncparameternumber: 12).1
            let value13 = param.getParameter(rsyncparameternumber: 13).0
            self.initcombox(combobox: self.combo13, index: value13)
            self.param13.stringValue = param.getParameter(rsyncparameternumber: 13).1
            let value14 = param.getParameter(rsyncparameternumber: 14).0
            self.initcombox(combobox: self.combo14, index: value14)
            self.param14.stringValue = param.getParameter(rsyncparameternumber: 14).1
            if configurations[index].rsyncdaemon != nil {
                self.rsyncdaemon.state = NSControl.StateValue(rawValue: configurations[index].rsyncdaemon!)
            } else {
                self.rsyncdaemon.state = .off
            }
            if configurations[index].sshport != nil {
                self.sshport.stringValue = String(configurations[index].sshport!)
            }
        }
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.diddissappear = true
    }

    // Function for saving changed or new parameters for one configuration.
    @IBAction func update(_ sender: NSButton) {
         var configurations: [Configuration] = self.configurations!.getConfigurations()
               guard configurations.count > 0 else { return }
               // Get the index of selected configuration
               if let index = self.index() {
                   let param = SetrsyncParameter()
                   configurations[index].parameter8 = param.setrsyncparameter(indexComboBox:
                       self.combo8.indexOfSelectedItem, value: getValue(value: self.param8.stringValue))
                   configurations[index].parameter9 = param.setrsyncparameter(indexComboBox:
                       self.combo9.indexOfSelectedItem, value: getValue(value: self.param9.stringValue))
                   configurations[index].parameter10 = param.setrsyncparameter(indexComboBox:
                       self.combo10.indexOfSelectedItem, value: getValue(value: self.param10.stringValue))
                   configurations[index].parameter11 = param.setrsyncparameter(indexComboBox:
                       self.combo11.indexOfSelectedItem, value: getValue(value: self.param11.stringValue))
                   configurations[index].parameter12 = param.setrsyncparameter(indexComboBox:
                       self.combo12.indexOfSelectedItem, value: getValue(value: self.param12.stringValue))
                   configurations[index].parameter13 = param.setrsyncparameter(indexComboBox:
                       self.combo13.indexOfSelectedItem, value: getValue(value: self.param13.stringValue))
                   configurations[index].parameter14 = param.setrsyncparameter(indexComboBox:
                       self.combo14.indexOfSelectedItem, value: getValue(value: self.param14.stringValue))
                   configurations[index].rsyncdaemon = self.rsyncdaemon.state.rawValue
                   if let port = self.sshport {
                       configurations[index].sshport = Int(port.stringValue)
                   }
                   // Update configuration in memory before saving
                   self.configurations!.updateConfigurations(configurations[index], index: index)
                   // notify an update
                   self.userparamsupdatedDelegate?.rsyncuserparamsupdated()
               }
               self.dismissview(viewcontroller: self, vcontroller: .vctabmain)
    }

    // There are eight comboboxes, all eight are initalized during ViewDidLoad and the correct index is set.
    private func initcombox(combobox: NSComboBox, index: Int) {
        combobox.removeAllItems()
        combobox.addItems(withObjectValues: self.comboBoxValues)
        combobox.selectItem(at: index)
    }

    // Returns nil or value from stringvalue (rsync parameters)
    private func getValue(value: String) -> String? {
        if value.isEmpty {
            return nil
        } else {
            return value
        }
    }
}
