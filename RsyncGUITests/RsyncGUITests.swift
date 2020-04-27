//
//  RsyncGUITests.swift
//  RsyncGUITests
//
//  Created by Thomas Evensen on 28/06/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//
// swiftlint:disable trailing_comma

@testable import RsyncGUI
import XCTest

class RsyncGUITests: XCTestCase, SetConfigurations {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        // Put setup code here. This method is called before the invocation of each test method in the class.
        _ = Selectprofile(profile: "XCTest", selectedindex: nil)
        ViewControllerReference.shared.temporarypathforrestore = "/temporaryrestore"
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testnumberofargumentstorsync() {
        let count = self.configurations?.arguments4rsync(index: 0, argtype: .argdryRun).count
        XCTAssertEqual(count, 14, "Should be equal to 14")
    }

    func testnumberofconfigurations() {
        let count = self.configurations?.getConfigurations().count
        XCTAssertEqual(count, 3, "Should be equal to 3")
    }

    func testargumentsdryrun() {
        let arguments = ["--archive", "--verbose", "--compress", "--delete", "-e", "ssh -p 22", "--exclude=.git",
                         "--backup", "--backup-dir=../backup_XCTest", "--suffix=_$(date +%Y-%m-%d.%H.%M)", "--dry-run",
                         "--stats", "/Users/thomas/XCTest/", "thomas@10.0.0.57:/backup2/RsyncOSX/XCTest/"]
        XCTAssertEqual(arguments, self.configurations?.arguments4rsync(index: 0, argtype: .argdryRun),
                       "Arguments should be equal")
    }

    func testargumentsrealrun() {
        let arguments = ["--archive", "--verbose", "--compress", "--delete", "-e", "ssh -p 22", "--exclude=.git",
                         "--backup", "--backup-dir=../backup_XCTest", "--suffix=_$(date +%Y-%m-%d.%H.%M)",
                         "--stats", "/Users/thomas/XCTest/", "thomas@web:~/XCTest/"]
        XCTAssertEqual(arguments, self.configurations?.arguments4rsync(index: 1, argtype: .arg),
                       "Arguments should be equal")
    }

    func testargumentsrestore() {
        let arguments = ["--archive", "--verbose", "--compress", "--delete", "-e", "ssh -p 22", "--exclude=.git",
                         "--backup", "--backup-dir=../backup_XCTest", "--suffix=_$(date +%Y-%m-%d.%H.%M)",
                         "--stats", "thomas@web:~/XCTest/", "/Users/thomas/XCTest/"]
        XCTAssertEqual(arguments, self.configurations?.arguments4restore(index: 1, argtype: .arg),
                       "Arguments should be equal")
    }

    func testargumentsverify() {
        let arguments = ["--checksum", "--recursive", "--verbose", "--compress", "--delete", "-e", "ssh -p 22",
                         "--exclude=.git", "--backup", "--backup-dir=../backup_XCTest",
                         "--suffix=_$(date +%Y-%m-%d.%H.%M)", "--dry-run", "--stats", "/Users/thomas/XCTest/",
                         "thomas@web:~/XCTest/"]
        XCTAssertEqual(arguments, self.configurations?.arguments4verify(index: 1),
                       "Arguments should be equal")
    }

    func testargumentsrestore0() {
        let arguments = ["--archive", "--verbose", "--compress", "--delete", "-e", "ssh -p 22", "--exclude=.git",
                         "--backup", "--backup-dir=../backup_XCTest", "--suffix=_$(date +%Y-%m-%d.%H.%M)",
                         "--stats", "thomas@10.0.0.57:/backup2/RsyncOSX/XCTest/", "/Users/thomas/XCTest/"]
        XCTAssertEqual(arguments, self.configurations?.arguments4restore(index: 0, argtype: .arg),
                       "Arguments should be equal")
    }

    func testargumentsrestoretmp() {
        let arguments = ["--archive", "--verbose", "--compress", "--delete", "-e", "ssh -p 22", "--exclude=.git",
                         "--backup", "--backup-dir=../backup_XCTest", "--suffix=_$(date +%Y-%m-%d.%H.%M)",
                         "--stats", "thomas@10.0.0.57:/backup2/RsyncOSX/XCTest/", "/temporaryrestore"]
        XCTAssertEqual(arguments, self.configurations?.arguments4tmprestore(index: 0, argtype: .arg),
                       "Arguments should be equal")
    }

    func testargumentssyncremoterealrun() {
        let arguments = ["--archive", "--verbose", "--compress", "--delete", "-e", "ssh -p 22", "--exclude=.git",
                         "--stats", "thomas@web:~/remotecatalog/", "/Users/thomas/localcatalog/"]
        XCTAssertEqual(arguments, self.configurations?.arguments4rsync(index: 2, argtype: .arg),
                       "Arguments should be equal")
    }

    func testalllogs() {
        let schedules = ScheduleLoggData(sortascending: true)
        XCTAssertEqual(1, schedules.loggdata?.count, "Should be one")
    }

    func testselectedlog() {
        let schedules = ScheduleLoggData(hiddenID: 2, sortascending: true)
        XCTAssertEqual(1, schedules.loggdata?.count, "Should be one")
    }

    func testnologg() {
        let schedules = ScheduleLoggData(hiddenID: 1, sortascending: true)
        XCTAssertEqual(0, schedules.loggdata?.count, "Should be zero")
    }

    func testaddconfig() {
        let configurations = ConfigurationsXCTEST(profile: "XCTest")
        let dict: NSMutableDictionary = [
            "task": ViewControllerReference.shared.synchronize,
            "backupID": "backupID",
            "localCatalog": "localCatalog",
            "offsiteCatalog": "offsiteCatalog",
            "offsiteServer": "offsiteServer",
            "offsiteUsername": "offsiteUsername",
            "parameter1": "parameter1",
            "parameter2": "parameter2",
            "parameter3": "parameter3",
            "parameter4": "parameter4",
            "parameter5": "parameter5",
            "parameter6": "parameter6",
            "dryrun": "dryrun",
            "dateRun": "",
            "singleFile": 0,
            "batch": 0,
        ]
        dict.setValue(1, forKey: "snapshotnum")
        configurations.addNewConfigurations(dict: dict)
        let count = configurations.getConfigurations().count
        XCTAssertEqual(count, 4, "Should be equal to 4")
    }

    func testaddnoconfig1() {
        // Missing "offsiteUsername": "offsiteUsername",
        let configurations = ConfigurationsXCTEST(profile: "XCTest")
        let dict: NSMutableDictionary = [
            "task": ViewControllerReference.shared.syncremote,
            "backupID": "backupID",
            "localCatalog": "localCatalog",
            "offsiteCatalog": "offsiteCatalog",
            "offsiteServer": "offsiteServer",
            "parameter1": "parameter1",
            "parameter2": "parameter2",
            "parameter3": "parameter3",
            "parameter4": "parameter4",
            "parameter5": "parameter5",
            "parameter6": "parameter6",
            "dryrun": "dryrun",
            "dateRun": "",
            "singleFile": 0,
            "batch": 0,
        ]
        dict.setValue(1, forKey: "snapshotnum")
        configurations.addNewConfigurations(dict: dict)
        let count = configurations.getConfigurations().count
        XCTAssertEqual(count, 3, "Should be equal to 3")
    }

    func testaddnoconfig2() {
        // Missing  "offsiteServer": "offsiteServer"
        let configurations = ConfigurationsXCTEST(profile: "XCTest")
        let dict: NSMutableDictionary = [
            "task": ViewControllerReference.shared.syncremote,
            "backupID": "backupID",
            "localCatalog": "localCatalog",
            "offsiteCatalog": "offsiteCatalog",
            "offsiteUsername": "offsiteUsername",
            "parameter1": "parameter1",
            "parameter2": "parameter2",
            "parameter3": "parameter3",
            "parameter4": "parameter4",
            "parameter5": "parameter5",
            "parameter6": "parameter6",
            "dryrun": "dryrun",
            "dateRun": "",
            "singleFile": 0,
            "batch": 0,
        ]
        dict.setValue(1, forKey: "snapshotnum")
        configurations.addNewConfigurations(dict: dict)
        let count = configurations.getConfigurations().count
        XCTAssertEqual(count, 3, "Should be equal to 3")
    }
}
