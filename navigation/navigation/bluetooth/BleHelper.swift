//
//  BleHelper.swift
//  navigation
//
//  Created by 郑旭 on 2021/1/28.
//
import Foundation
import CoreBluetooth

enum BleState: Int {
    case ready
    case scanning
    case connecting
    case connected
}

///传出蓝牙当前搜索到的设备信息
typealias BlePeripheralsBlock = (_ pPeripheral: CBPeripheral,_ pData: [String : Any],_ rssi: NSNumber) -> Void
//当设备连接成功时，记录该设备，用于请求设备版本号
typealias BleConnectedBlock = (_ peripheral: CBPeripheral, _ characteristic:CBCharacteristic) -> Void

class BleHelper: NSObject {
    private let BLE_WRITE_UUID = "xxxx"
    private let BLE_NOTIFY_UUID = "xxxx"
    
    static let shared = BleHelper()
    
    var bleState:BleState = .ready
    
    //传出扫描到的设备
    var backPeripheralsBlock:BlePeripheralsBlock?
    ///传出当前连接成功的设备
    var backConnectedBlock:BleConnectedBlock?
  
    var centralManager:CBCentralManager?
    ///扫描到的所有设备
    var aPeArray:[CBPeripheral] = []
    //当前连接的设备
    var pe:CBPeripheral?
    var writeCh: CBCharacteristic?
    var notifyCh: CBCharacteristic?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey:false])
    }
    
    //MARK: - Public Method
    
    ///保存当前选中的设备
    func setSelectedPeripherals(peripheral:CBPeripheral) {
        pe = peripheral
    }
    
    //主动获取搜索到的peripheral列表
    func getPeripheralList() -> [CBPeripheral] {
        return aPeArray
    }
    
    //MARK: - Private Method
    
    //连接指定的设备
    func doConnect(peripheral:CBPeripheral) {
        bleState = .connecting
        centralManager?.connect(peripheral, options: nil)
        peripheral.delegate = self
    }
    
    ///断开连接
    func disconnect(peripheral: CBPeripheral) {
        centralManager?.cancelPeripheralConnection(peripheral)
    }
    
    ///开始扫描
    func startScan(serviceUUIDS:[CBUUID]? = nil, options:[String: Any]? = nil) {
        aPeArray = []
        
        bleState = .scanning
        centralManager?.scanForPeripherals(withServices: serviceUUIDS, options: options)
    }
    
    ///停止扫描
    func stopScan() {
        centralManager?.stopScan()
    }
            
    ///传出当前扫描出来的设备信息
    func setPeripheralsBlock(block:@escaping BlePeripheralsBlock) {
        backPeripheralsBlock = block
    }
    
    ///传出已连接的设备的信息，该参数当前用于获取设备版本号
    func setConnectedBlock(block:@escaping BleConnectedBlock) {
        backConnectedBlock = block
    }
    
}

//MARK: - Ble Delegate

extension BleHelper:CBCentralManagerDelegate {
    // MARK: 检查运行这个App的设备是不是支持BLE。
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if #available(iOS 10.0, *) {
            if central.state == CBManagerState.poweredOn {
                print("powered on")
                
                startScan()
            } else {
                if central.state == CBManagerState.poweredOff {
                    print("BLE powered off")
                } else if central.state == CBManagerState.unauthorized {
                    print("BLE unauthorized")
                } else if central.state == CBManagerState.unknown {
                    print("BLE unknown")
                } else if central.state == CBManagerState.resetting {
                    print("BLE ressetting")
                }
            }
        } else {
        
            // Fallback on earlier versions
        }
    }
    
    // 开始扫描之后会扫描到蓝牙设备，扫描到之后走到这个代理方法
    // MARK: 中心管理器扫描到了设备
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let deviceName = peripheral.name, deviceName.count > 0 else {
            return
        }
        //传出去实时刷新
        if let backPeripheralsBlock = backPeripheralsBlock {
            backPeripheralsBlock(peripheral,advertisementData,RSSI)
        }
        
        guard !aPeArray.contains(peripheral) else {
            return
        }
        aPeArray.append(peripheral)
    }
    
    // MARK: 连接外设成功，开始发现服务
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("\(#function)连接外设成功。\ncentral:\(central),peripheral:\(peripheral)\n")
        // 设置代理
        peripheral.delegate = self
        // 开始发现服务
        peripheral.discoverServices(nil)
    }
    
    // MARK: 连接外设失败
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("\(#function)连接外设失败\n\(String(describing: peripheral.name))连接失败：\(String(describing: error))\n")
        // 这里可以发通知出去告诉设备连接界面连接失败
        
        
    }
    
    // MARK: 连接丢失
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("\(#function)连接丢失\n外设：\(String(describing: peripheral.name))\n错误：\(String(describing: error))\n")
        // 这里可以发通知出去告诉设备连接界面连接丢失
        
    }
}

extension BleHelper: CBPeripheralDelegate {
    //MARK: 匹配对应服务UUID
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error  {
            print("\(#function)搜索到服务-出错\n设备(peripheral)：\(String(describing: peripheral.name)) 搜索服务(Services)失败：\(error)\n")
            return
        } else {
            print("\(#function)搜索到服务\n设备(peripheral)：\(String(describing: peripheral.name))\n")
        }
        for service in peripheral.services ?? [] {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    //MARK: 服务下的特征
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let _ = error {
            print("\(#function)发现特征\n设备(peripheral)：\(String(describing: peripheral.name))\n服务(service)：\(String(describing: service))\n扫描特征(Characteristics)失败：\(String(describing: error))\n")
            return
        } else {
            print("\(#function)发现特征\n设备(peripheral)：\(String(describing: peripheral.name))\n服务(service)：\(String(describing: service))\n服务下的特征：\(service.characteristics ?? [])\n")
        }
        
        for characteristic in service.characteristics ?? [] {
            if characteristic.uuid.uuidString.lowercased().isEqual(BLE_WRITE_UUID) {
                pe = peripheral
                writeCh = characteristic
                
                if let block = backConnectedBlock {
                    block(peripheral,characteristic)
                }
            } else if characteristic.uuid.uuidString.lowercased().isEqual(BLE_NOTIFY_UUID) {
                //该组参数无用
                notifyCh = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
            //此处代表连接成功
        }
    }
    
    // MARK: 获取外设发来的数据
    // 注意，所有的，不管是 read , notify 的特征的值都是在这里读取
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let _ = error {
            return
        }
    }
    
    //MARK: 检测中心向外设写数据是否成功
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("\(#function)\n发送数据失败！错误信息：\(error)")
        }
    }
}

