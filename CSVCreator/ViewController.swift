//
//  ViewController.swift
//  CSVCreator
//
//  Created by Cole M on 9/14/20.
//  Copyright © 2020 Cole M. All rights reserved.
//

import Cocoa
import Collections
import AsyncCollections
import NIO


class ViewController: NSViewController {
    
    var fileToRemoveButton: NSButton = {
        var btn = NSButton()
        btn.title = "Choose a CSVFile to remove"
        btn.font = NSFont.boldSystemFont(ofSize: 18)
        btn.contentTintColor = .white
        btn.layer?.backgroundColor = .none
        btn.isBordered = false
        return btn
    }()
    var generateCSV: NSButton = {
        var btn = NSButton()
        btn.title = "Generate New CSV"
        btn.font = NSFont.boldSystemFont(ofSize: 18)
        btn.contentTintColor = .white
        btn.layer?.backgroundColor = .none
        btn.isBordered = false
        return btn
    }()
    var deleteDatabase: NSButton = {
        var btn = NSButton()
        btn.title = "Delete Database"
        btn.font = NSFont.boldSystemFont(ofSize: 18)
        btn.contentTintColor = .white
        btn.layer?.backgroundColor = .none
        btn.isBordered = false
        return btn
    }()
    var filesToRemoveStack = NSStackView()
    
    var files = [String]()
    var newCSVArray: [Dictionary<String, String>] =  Array()
    var csvModelArray: [CSVModel] = []
    var introductions: NSTextView = {
        var txt = NSTextView()
        txt.font = NSFont.boldSystemFont(ofSize: 14)
        txt.textColor = .white
        txt.layer?.backgroundColor = .none
        txt.string = """
                    Welcome to CSV Generator. Here you can add csv file data to the local database. Duplicates will be filtered out by duplicate phone numbers and business names. The Generate New CSV button will create a CSV file with whatever is in the database. Enjoy...
                    """
        return txt
    }()
    var removeListFile = NSTextField()
    var delegate: CSVStoreProtocol?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1).next()
            let store = try? await SQLiteStore.create(on: eventLoop)
            delegate = store
            let csvs = try await delegate?.fetchCSVS()
            self.csvModelArray = csvs ?? []
        }
        setupView()
        gestures()
        mouseActions()
    }
    
    @objc func removeAllCSVS() {
        DispatchQueue.main.async {
            let alert = NSAlert()
                alert.configuredCustomButtonAlert(title: "Are you sure you want to delete?", text: "This actions cannot be undone", firstButtonTitle: "Cancel", secondButtonTitle: "DELETE", switchRun: true)
                let run = alert.runModal()
                switch run {
                case .alertFirstButtonReturn:
                    debugPrint("Cancel")
                case .alertSecondButtonReturn:
                    debugPrint("we delete")
                    Task {
                    do {
                        let csvs = try await self.delegate?.fetchCSVS()
                        csvs?.forEach({ c in
                            Task {
                                print("REMOVED CSV: \(c)")
                                try? await self.delegate?.removeCSV(c)
                            }
                        })
                    } catch {
                        print(error)
                    }
                    }
                default:
                    break
                }
            }
        }
    
    
    
    deinit {
        
    }
    
    
    func setupView() {
        view.addSubview(fileToRemoveButton)
        view.addSubview(filesToRemoveStack)
        view.addSubview(generateCSV)
        view.addSubview(deleteDatabase)
        view.addSubview(introductions)
        deleteDatabase.translatesAutoresizingMaskIntoConstraints = false
        deleteDatabase.topAnchor.constraint(equalTo: view.topAnchor, constant: 40).isActive = true
        deleteDatabase.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40).isActive = true
        fileToRemoveButton.translatesAutoresizingMaskIntoConstraints = false
        filesToRemoveStack.translatesAutoresizingMaskIntoConstraints = false
        fileToRemoveButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 40).isActive = true
        fileToRemoveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        filesToRemoveStack.topAnchor.constraint(equalTo: fileToRemoveButton.topAnchor, constant: 40).isActive = true
        filesToRemoveStack.leadingAnchor.constraint(equalTo: fileToRemoveButton.leadingAnchor, constant: 10).isActive = true
        filesToRemoveStack.orientation = .vertical
        introductions.translatesAutoresizingMaskIntoConstraints = false
        introductions.topAnchor.constraint(equalTo: deleteDatabase.bottomAnchor, constant: 120).isActive = true
        introductions.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -100).isActive = true
        introductions.heightAnchor.constraint(equalToConstant: 400).isActive = true
        introductions.widthAnchor.constraint(equalToConstant: 400).isActive = true
        generateCSV.translatesAutoresizingMaskIntoConstraints = false
        generateCSV.topAnchor.constraint(equalTo: view.topAnchor, constant: 40).isActive = true
        generateCSV.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    
    func gestures() {
        fileToRemoveButton.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(fileToRemoveButtonClicked)))
        generateCSV.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(generateCSVClicked)))
        deleteDatabase.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(removeAllCSVS)))
    }
    
    @objc func fileToRemoveButtonClicked() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.begin { (result) -> Void in
            if result == .OK {
                let selectedPath = openPanel.url!
                Task {
                    await self.processURL(url: selectedPath)
                    await self.createDictionary()
                }
            }
        }
    }
    
    @objc func generateCSVClicked() {

        self.csvModelArray.forEach {
            var dct = Dictionary<String, String>()
            dct.updateValue($0.id.uuidString, forKey: "Id")
            dct.updateValue($0.name ?? "", forKey: "Name")
            dct.updateValue($0.floor ?? "", forKey: "Floor")
            dct.updateValue($0.address ?? "", forKey: "Address")
            dct.updateValue($0.unit ?? "", forKey: "Unit")
            dct.updateValue($0.district ?? "", forKey: "District")
            dct.updateValue($0.phoneNumber ?? "", forKey: "Phone Number")
            newCSVArray.append(dct)
            
        }
        createCSV(from: newCSVArray)
    }
    
    func appendModel(model: CSVModel) async {
        do {
            try await delegate?.createCSV(model)
            let csvs = try await self.delegate?.fetchCSVS()
            self.csvModelArray = csvs ?? []
        } catch {
            print(error)
        }
    }
    
    @MainActor
    func processURL(url: URL) async {
        do {
            let s = try String(contentsOf: url).components(separatedBy: "\n")
            _ = await s.asyncMap { row in
                let array = row.components(separatedBy: ",")
                
                
                let model = CSVModel(id: UUID(), name: array[optional: 2], floor: array[optional: 3], unit: array[optional: 4], address: array[optional: 5], district: array[optional: 6], phoneNumber: array[optional: 7])
                
                
                let contains = await self.csvModelArray.contains(where: { $0.phoneNumber == model.phoneNumber })
                if !contains,
                   model.phoneNumber != nil,
                   model.name != nil,
                   model.phoneNumber != "",
                   model.phoneNumber != "Phone Number" {
                    await self.appendModel(model: model)
                }  else if model.phoneNumber != "" {
                    //TODO: - Generate only Address CSV
                }
            }
            if filesToRemoveStack.arrangedSubviews.count > 0 {
                filesToRemoveStack.removeFullyAllArrangedSubviews()
            }
            
            files.append(String(url.lastPathComponent))
            for file in files {
                let fileToRemove = NSTextField.newLabel()
                filesToRemoveStack.addArrangedSubview(fileToRemove)
                fileToRemove.stringValue += file
            }
        } catch {
            print(error)
        }
    }
    
    
    func createDictionary() async {
        let newArray = csvModelArray.reduce(into: [UUID: CSVModel]()) {
            $0[$1.id] = $1
        }
        print("NEW ARRAY", newArray)
    }
    
    //    fileprivate func subtractFromList() {
    //        let removalList =
    //"""
    //\n36793988,
    //36673030,
    //25202525,
    //25296196,
    //25202390,
    //25224488,
    //25250361,
    //21809398,
    //36673030,
    //36793988,
    //25202525,
    //25296196,
    //25202390,
    //28698265,
    //28493399,
    //28902823,
    //28815505,
    //28989777,
    //25975330,
    //28681827,
    //25161000,
    //25720246,
    //25120702,
    //37025177,
    //25251351,
    //25662033,
    //28828161,
    //37412235,
    //28611681,
    //28311508,
    //28697288,
    //28939699,
    //21108318,
    //28915111,
    //35763880,
    //25080457,
    //28930330,
    //28023953,
    //29703033,
    //28152171,
    //28577000,
    //25257381,
    //31693444,
    //25376063,
    //25283538,
    //25986086,
    //28908083,
    //25730118,
    //23806223,
    //25165226,
    //27211881,
    //27211881,
    //21579363,
    //28876828,
    //25666686,
    //28389860,
    //31063902,
    //31806383,
    //31198111,
    //31198111,
    //25087700,
    //28231388,
    //39008388,
    //22016800,
    //28339918,
    //34202330,
    //31806708,
    //39033888,
    //29262030,
    //31806335,
    //25570275,
    //25791330,
    //38448100,
    //28389819,
    //81207475,
    //36006868,
    //25766376,
    //28386238,
    //25722100,
    //23693889,
    //23697678,
    //28816690,
    //28085000,
    //39023003,
    //28386238,
    //28386238,
    //25641191,
    //28821494,
    //28386238,
    //25618278,
    //28331939,
    //29078888,
    //29078888,
    //28815250,
    //21532796,
    //37088697,
    //22309900,
    //28319191,
    //25610183,
    //25610183,
    //25610183,
    //31059995,
    //29158111,
    //28916687,
    //25114261,
    //29156028,
    //28655878,
    //22330000,
    //34122222,
    //29560828,
    //25742655,
    //36016973,
    //37678777,
    //35430708,
    //28958111,
    //25663090,
    //25166128,
    //25776368,
    //25919178,
    //28814505,
    //28106801,
    //28331008,
    //28111938,
    //68196870,
    //29751111,
    //28952616,
    //35092081,
    //28913738,
    //36651000,
    //25859188,
    //23281888,
    //22050229,
    //35092081,
    //22345070,
    //25101030,
    //25293968,
    //28656868,
    //22091799,
    //37967188,
    //58049350,
    //28805333,
    //34721688,
    //21479678,
    //39569659,
    //58088852,
    //36192319,
    //26902410,
    //28805333,
    //31582123,
    //23712822,
    //21168464,
    //35889400,
    //28868733,
    //36110360,
    //22198780,
    //27107732,
    //29088428,
    //25276862,
    //90138378,
    //25620123,
    //29082501,
    //29088429,
    //29088338,
    //22663940,
    //28722000,
    //34678888,
    //26496866,
    //25668711,
    //22797310,
    //21087222,
    //25595888,
    //28870099,
    //25080228,
    //28271180,
    //25280128,
    //25443344,
    //27360820,
    //24701927,
    //27360820,
    //35636771,
    //36930568,
    //21689200,
    //22385555,
    //28063822,
    //28773033,
    //81025711,
    //25109138,
    //25631831,
    //25713123,
    //28119017,
    //25622183,
    //28037611,
    //28879789,
    //25705061,
    //28851133,
    //39565390,
    //93260519,
    //25665931,
    //34283299,
    //25034871,
    //25786025,
    //28877725,
    //25616601,
    //25791369,
    //24559622,
    //25666117,
    //28060882,
    //28879818,
    //26557757,
    //25785158,
    //91265739,
    //25711336,
    //28560322,
    //23846118,
    //81025711,
    //23241112,
    //31044889,
    //25169101,
    //28119008,
    //25711336,
    //25711336,
    //25711336,
    //25711336,
    //25711336,
    //25711336,
    //25617823,
    //25666620,
    //25086108,
    //26666095,
    //25717595,
    //25637365,
    //25661396,
    //28871299,
    //28871299,
    //25669986,
    //36193179,
    //25663063,
    //28990787,
    //28990787,
    //21809398,
    //25635802,
    //28113733,
    //25705061,
    //29110063,
    //21043121,
    //25126128,
    //25665678,
    //25662488,
    //25623929,
    //25623929,
    //25648847,
    //60856008,
    //28879887,
    //25620123,
    //25620123,
    //25708220,
    //25708220,
    //25708220,
    //34279254,
    //37088010,
    //25634041,
    //25031621,
    //28112208,
    //22345776,
    //24680333,
    //23802100,
    //36195190,
    //35685613,
    //25910666,
    //25086858,
    //25787303,
    //34843384,
    //21918833,
    //21918833,
    //21918833,
    //25167283,
    //37089090,
    //37089090,
    //22199012,
    //31120361,
    //25610301,
    //25788021,
    //28876320,
    //25663032,
    //27544748,
    //27544748,
    //25706920,
    //26178700,
    //25666686,
    //25713816,
    //28055221,
    //28872800,
    //23888054,
    //25100789,
    //29110800,
    //25669628,
    //25108363,
    //31571652,
    //25627979,
    //25169765,
    //25700012,
    //25700012,
    //25700012,
    //25701791,
    //25706930,
    //25706930,
    //25780912,
    //25628444,
    //25628444,
    //25616601,
    //25128227,
    //28106696,
    //34228763,
    //28842380,
    //25619713,
    //25646012,
    //29040009,
    //23662632,
    //25128383,
    //25578870,
    //25710808,
    //26701331,
    //28063860,
    //25703328,
    //28560888,
    //28873136,
    //28702201,
    //28026057,
    //29790289,
    //25789382,
    //25646222,
    //23449633,
    //25661783,
    //25783535,
    //25251439,
    //26887008,
    //23622812,
    //28573454,
    //22679100,
    //22646621,
    //25238333,
    //28188807,
    //21551777,
    //29970488,
    //64064006,
    //92110879,
    //28084468,
    //26887007,
    //28971800,
    //22176077,
    //60141422,
    //29526477,
    //95816669,
    //28827135,
    //65300288,
    //28243001,
    //23469855,
    //25707088,
    //28828227,
    //31018045,
    //27200080,
    //28816339,
    //25668411,
    //28070181,
    //35808851,
    //21468282,
    //35687006,
    //56000421,
    //39545381,
    //27639886,
    //28872983,
    //57211250,
    //24136483,
    //28568675,
    //25668468,
    //68488786,
    //27711911,
    //25669966,
    //25709200,
    //22658858,
    //25713348,
    //25712222,
    //28056130,
    //28870428,
    //31059600,
    //39545918,
    //27157777,
    //25228599,
    //25667012,
    //28805224,
    //21212689,
    //64361038,
    //23456826,
    //28897799,
    //35946069,
    //39545867,
    //35794755,
    //28162733,
    //90123148,
    //28817996,
    //54021598,
    //63607676,
    //22346691,
    //39569207,
    //25457908,
    //25112700,
    //35280208,
    //36221795,
    //28064922,
    //28064918,
    //28110545,
    //28111630,
    //23858255,
    //25110190,
    //28064938,
    //64001076,
    //28805224,
    //38969898,
    //31070334,
    //28566238,
    //22672988,
    //21800000,
    //35989309,
    //23333538,
    //25169415,
    //28805224,
    //38969888,
    //28560290,
    //26832703,
    //25650909,
    //21807781,
    //31758884,
    //23481222,
    //37020500,
    //21397420,
    //24876200,
    //21109948,
    //37088010,
    //62220691,
    //25881111,
    //90456694,
    //25763238,
    //28148365,
    //21042218,
    //39137193,
    //25703228,
    //27544748,
    //29410006,
    //34275028,
    //34288633,
    //23024571,
    //28110328,
    //34228873,
    //25646269,
    //61639309,
    //28669090,
    //28138369,
    //28118007,
    //35801893,
    //23951700,
    //21867018,
    //25167283,
    //25662828,
    //31980622,
    //25296196,
    //31980600,
    //27399377,
    //23113322,
    //25202525,
    //25202390,
    //68540992,
    //25250361,
    //36193179,
    //25166978,
    //31980238,
    //31980800,
    //34870068,
    //28112655,
    //26180108,
    //98455272,
    //56085606,
    //22178889,
    //31980840,
    //"""
    //
    //        let masterList =
    //"""
    //\n28111811,
    //25707028,
    //28873860,
    //29546188,
    //28380102,
    //29079634,
    //29223002,
    //35425680,
    //25719823,
    //25787806,
    //28870968,
    //25641848,
    //25700583,
    //25712181,
    //28070768,
    //25735766,
    //25107608,
    //28878533,
    //23638603,
    //31028388,
    //28870517,
    //25250171,
    //25041188,
    //28062210,
    //28329993,
    //25086230,
    //28875382,
    //25740295,
    //28389819,
    //25080892,
    //26832613,
    //25720862
    //"""
    //
    //        var arr = masterList.components(separatedBy: ",")
    //        print("MASTER LIST", arr.count, "-")
    //        let arr2 = removalList.components(separatedBy: ",")
    //        print("REMOVAL LIST", arr2.count, "=")
    //        arr = Array(Set(arr).subtracting(arr2))
    //
    //        print("EQUALS", arr)
    //
    //        //TODO CLEAN Up and append a common to each string
    ////        for i in arr {
    ////            print(i)
    ////            var dct = OrderedDictionary<String, AnyObject>()
    ////            dct.updateValue(i as AnyObject, forKey: "proid")
    ////            print(dct)
    ////            newCSVArray.append(dct)
    ////        }
    ////        createCSV(from: newCSVArray)
    //    }
    
    func createCSV(from recArray:[Dictionary<String, String>]) {
        
        var csvString = "\("Id"),\("Name"),\("Floor"),\("Address"),\("Unit"),\("District"),\("Phone Number")\n\n"
        for dct in recArray {
            csvString = csvString.appending("\(String(describing: dct["Id"]!)) ,\(String(describing: dct["Name"]!)) ,\(String(describing: dct["Floor"]!)) ,\(String(describing: dct["Address"]!)) ,\(String(describing: dct["Unit"]!)) ,\(String(describing: dct["District"]!)) ,\(String(describing: dct["Phone Number"]!))\n")
        }

            let savePanel = NSSavePanel()
            savePanel.title = NSLocalizedString("Create your csv file", comment: "enableFileMenuItems")
            savePanel.nameFieldStringValue = ""
            savePanel.prompt = NSLocalizedString("Create", comment: "enableFileMenuItems")
            let fileManager = FileManager.default
    
            
            
            savePanel.begin() { (result) -> Void in
                if result == .OK {
                    let fileWithExtensionURL = savePanel.url!  //  May test that file does not exist already
                    if fileManager.fileExists(atPath: fileWithExtensionURL.path) {
                    } else {
                        print("File Path: ", fileWithExtensionURL)
                        try? csvString.write(to: fileWithExtensionURL, atomically: true, encoding: .utf8)
                    }
            }
            }
    }
}


extension ViewController {
    func mouseActions() {
        let trackingArea1 = NSTrackingArea(rect: CGRect(x: 0, y: 0, width: 245, height: 20), options: [NSTrackingArea.Options.activeAlways ,NSTrackingArea.Options.mouseEnteredAndExited], owner: self, userInfo: ["btn":"button1"])
        let trackingArea2 = NSTrackingArea(rect: CGRect(x: 0, y: 0, width: 170, height: 20), options: [NSTrackingArea.Options.activeAlways ,NSTrackingArea.Options.mouseEnteredAndExited], owner: self, userInfo: ["btn":"button2"])
        let trackingArea3 = NSTrackingArea(rect: CGRect(x: 0, y: 0, width: 150, height: 20), options: [NSTrackingArea.Options.activeAlways ,NSTrackingArea.Options.mouseEnteredAndExited], owner: self, userInfo: ["btn":"button3"])
        fileToRemoveButton.addTrackingArea(trackingArea1)
        generateCSV.addTrackingArea(trackingArea2)
        deleteDatabase.addTrackingArea(trackingArea3)
    }
    
    override func mouseEntered(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = 0.7
            if let buttonName = event.trackingArea?.userInfo?.values.first as? String {
                switch buttonName {
                case "button1":
                    fileToRemoveButton.animator().alphaValue = 0.5
                    fileToRemoveButton.toolTip = "Choose a file to create the master csv"
                case "button2":
                    generateCSV.animator().alphaValue = 0.5
                    generateCSV.toolTip = "Click to generate"
                case "button3":
                    deleteDatabase.animator().alphaValue = 0.5
                    deleteDatabase.toolTip = "Wipe master DB Data"
                default:
                    print("The given button name: \"\(buttonName)\" is unknown!")
                }
            }
        }, completionHandler:{
//            print("completed")
        })
    }
    
    override func mouseExited(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = 1.0
            fileToRemoveButton.animator().alphaValue = 0.9
            generateCSV.animator().alphaValue = 0.9
            deleteDatabase.animator().alphaValue = 0.9
        }, completionHandler:{
//            print("completed")
        })
    }
}
