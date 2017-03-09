//
//  PeripheralScanner.swift
//  Super Gluu
//
//  Created by Nazar Yavornytskyy on 3/9/17.
//  Copyright © 2017 Gluu. All rights reserved.
//

import UIKit
import CoreBluetooth

struct Constants {
    static let ConnectTimeout: TimeInterval = 5
    static let DidUpdateValueForCharacteristic = "didUpdateValueForCharacteristic"
    static let DidWriteValueForCharacteristic = "didWriteValueForCharacteristic"
    static let DidUpdateNotificationStateForCharacteristic = "didUpdateNotificationStateForCharacteristic"
    
    static let u2fControlPoint_uuid = "F1D0FFF1-DEAA-ECEE-B42F-C9BA7ED623BB"
    static let u2fStatus_uuid = "F1D0FFF2-DEAA-ECEE-B42F-C9BA7ED623BB"
    static let u2fControlPointLength_uuid = "F1D0FFF3-DEAA-ECEE-B42F-C9BA7ED623BB"
}

class PeripheralScanner : NSObject {
    
    var centralManager: CBCentralManager!
    
    var peripherals = [(peripheral: CBPeripheral, serviceCount: Int, UUIDs: [CBUUID]?)]()
    
    var connectTimer: Timer?
    
    var serviceScanner : ServiceScanner!
    
    var scanning = false {
        didSet {
            
            if scanning {
                //				let uuid1 = CBUUID(string: "180A")
                //				let uuid2 = CBUUID(string: "180D")
                //				centralManager.scanForPeripheralsWithServices([uuid1, uuid2], options: nil)
                
                //Vasco u2f token device's UUID
                //                let uuid = CBUUID(string: "8610C427-C32E-4AEB-A086-D6ACF31BCF24")
                //				centralManager.scanForPeripherals(withServices: [uuid], options: nil)
                
                centralManager.scanForPeripherals(withServices: nil, options: nil)
                NSLog("scanning...")
            } else {
                centralManager.stopScan()
                cancelConnections()
                NSLog("scanning stopped.")
            }
        }
    }
    

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        serviceScanner = ServiceScanner()
    }
    
    func cancelConnections() {
        print("cancelConnections")
        for peripheralCouple in peripherals {
            centralManager.cancelPeripheralConnection(peripheralCouple.peripheral)
        }
    }
    
    func tryToDiscoverVascoToken(){
        if peripherals.count > 0 {
            //There is at least one Vasco's token
            let peripheralCouple = peripherals[0]
            let peripheral = peripheralCouple.peripheral
            //Doing service(s) discovering
            serviceScanner.peripheral = peripheral
            serviceScanner.advertisementDataUUIDs = peripheralCouple.UUIDs
            NSLog("connectPeripheral \(peripheral.name) (\(peripheral.state))")
            centralManager.connect(peripheral, options: nil)
            connectTimer = Timer.scheduledTimer(timeInterval: Constants.ConnectTimeout, target: self, selector: #selector(PeripheralScanner.cancelConnections), userInfo: nil, repeats: false)
        }
    }
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
////        tableView.rowHeight = UITableViewAutomaticDimension
////        tableView.estimatedRowHeight = 60
//        
//        centralManager = CBCentralManager(delegate: self, queue: nil)
//    }
//    
//    override func viewDidAppear(_ animated: Bool) {
//        cancelConnections()
//    }
    
}


extension PeripheralScanner : CBCentralManagerDelegate{

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print(centralManager.state)
        if centralManager.state != .poweredOn {
            if scanning {
                UIAlertView(title: "Unable to scan", message: "bluetooth is in \(centralManager.state.rawValue)-state", delegate: nil, cancelButtonTitle: "Ok").show()
            }
        }
        scanning = centralManager.state == .poweredOn
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        NSLog("discovered \(peripheral.name ?? "Noname") RSSI: \(RSSI)\n\(advertisementData)")
        
        let contains = peripherals.contains { (peripheralInner: CBPeripheral, serviceCount: Int, UUIDs: [CBUUID]?) -> Bool in
            return peripheral == peripheralInner
        }
        
        if peripheral.name != "SClick U2F" {
            return
        }
        
        if !contains {
            if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
                let UUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as! [CBUUID]
                peripherals.append((peripheral, serviceUUIDs.count, UUIDs))
            } else {
                peripherals.append((peripheral, 0, nil))
            }
        }
        tryToDiscoverVascoToken()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        NSLog("didConnectPeripheral \(peripheral.name)")
        
        connectTimer?.invalidate()
        
        if let serviceScan = serviceScanner {
            peripheral.delegate = serviceScan
        }
        
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        NSLog("didDisconnectPeripheral \(peripheral.name)")
        peripherals.removeAll()
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        NSLog("\tdidFailToConnectPeripheral \(peripheral.name)")
        UIAlertView(title: "Fail To Connect", message: nil, delegate: nil, cancelButtonTitle: "Dismiss").show()
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        NSLog("willRestoreState \(dict)")
    }
    
}
