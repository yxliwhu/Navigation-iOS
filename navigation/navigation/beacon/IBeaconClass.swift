//
//  IBeaconClass.swift
//  navigation
//
//  Created by 郑旭 on 2021/1/25.
//

import Foundation
struct iBeacon {
    var name:String
    var major:Int
    var minor:Int64
    var proximityUuid:String
    var bluetoothAddress:String
    var txPower:Int
    var rssi:Int
    var distance:String
    init(){
        self.name = ""
        self.major = -1
        self.minor = -1
        self.proximityUuid = ""
        self.bluetoothAddress = ""
        self.txPower = -1
        self.rssi = -1000
        self.distance = ""
    }
}

class iBeaconClass{
    private static let CHexLookup : [Character] =
        [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F" ]
    
    static func fromScanData(_ deviceName:String,_ deviceAddr:String, _ rssi:Int,_ scanData:[UInt8]) -> iBeacon?{
        var startByte:Int = 2
        var patternFound:Bool = false
        while (startByte <= 5) {
            if ((scanData[startByte + 2] & 0xff) == 0x02 && (scanData[startByte + 3] & 0xff) == 0x15) {
                // 这是 iBeacon
                patternFound = true
                break
            } else if ((scanData[startByte] & 0xff) == 0x2d && (scanData[startByte + 1] & 0xff) == 0x24
                        && (scanData[startByte + 2] & 0xff) == 0xbf
                        && (scanData[startByte + 3] & 0xff) == 0x16) {
                var ibc = iBeacon()
                ibc.major = 0
                ibc.minor = 0
                ibc.proximityUuid = "00000000-0000-0000-0000-000000000000"
                ibc.txPower = -55
                ibc.distance = String(format:"%.2f", calculateAccuracy(ibc.txPower, rssi))
                return ibc
            } else if ((scanData[startByte] & 0xff) == 0xad && ( scanData[startByte + 1] & 0xff) == 0x77
                        && (scanData[startByte + 2] & 0xff) == 0x00
                        && (scanData[startByte + 3] & 0xff) == 0xc6) {
                
                var ibc = iBeacon()
                ibc.major = 0
                ibc.minor = 0
                ibc.proximityUuid = "00000000-0000-0000-0000-000000000000"
                ibc.txPower = -55
                ibc.distance = String(format: "%.2f", calculateAccuracy(ibc.txPower,rssi))
                return ibc
            }
            startByte = startByte + 1
        }
        
        if (patternFound == false) {
            // 这不是iBeacon
            return nil
        }
        let hex:Int64 = 0x100
        let hex00:Int64 = Int64(scanData[startByte + 20] & 0xff)
        let hex01:Int64 = Int64(scanData[startByte + 21] & 0xff)
        let hex02:Int64 = Int64(scanData[startByte + 22] & 0xff)
        let hex03:Int64 = Int64(scanData[startByte + 23] & 0xff)
        let minor:Int64 = hex02 * hex + hex03
        let major:Int64 = hex00 * hex + hex01
        
        var ibc = iBeacon()
        ibc.major = Int(major)
        ibc.minor = major*100000 + minor
        ibc.txPower = Int(scanData[startByte + 24])
        ibc.rssi = rssi
        
        // 格式化UUID
        let proximityUuidBytes:[UInt8] = arrayCopy(numbers: scanData,from:startByte+4,to:startByte+20)
        let hexString = bytesToHexString(proximityUuidBytes)
        var sb:String = ""
        
        sb.append(substring(hexString, 0, 8))
        sb.append("-")
        sb.append(substring(hexString, 8, 12))
        sb.append("-");
        sb.append(substring(hexString, 12, 16))
        sb.append("-");
        sb.append(substring(hexString, 16, 20))
        sb.append("-");
        sb.append(substring(hexString, 20, 32))
        ibc.proximityUuid = sb
        
        
        
        ibc.bluetoothAddress = deviceAddr
        ibc.name = deviceName
        
        ibc.distance = String(format:"%.2f", calculateAccuracy(ibc.txPower,rssi))
        if(ibc.proximityUuid == "b19af004-7f2a-4972-8f39-37d26c29cb9e"){//Kowloon
            return ibc
        }
        else {
            return nil
        }
        //        return  iBeacon;
    }
    
    static func arrayCopy(numbers: [UInt8], from: Int, to: Int) -> [UInt8] {
        let newNumbers = Array(numbers[from..<to])
        return newNumbers
    }
    
    static func substring(_ str:String,_ from: Int, _ to: Int)->String{
        let startIndex = str.index(str.startIndex,offsetBy: from)
        let endIndex = str.index(str.startIndex,offsetBy: to)
        let result = String(str[startIndex..<endIndex])
        return result
    }
    /**
     * 转换十进制
     *
     * @param src
     * @return
     */
    static func bytesToHexString(_ src:[UInt8])->String {
        var stringToReturn = ""
        
        for oneByte in src {
            let asInt = Int(oneByte)
            stringToReturn.append(iBeaconClass.CHexLookup[asInt >> 4])
            stringToReturn.append(iBeaconClass.CHexLookup[asInt & 0x0f])
        }
        return stringToReturn
    }
    
    /**
     * 估算用户设备到ibeacon的距离
     *
     * @param txPower
     * @param rssi
     * @return
     */
    static func calculateAccuracy(_ txPower:Int, _ rs:Int) -> Double{
        if (rs == 0) {
            return -1.0 // if we cannot determine accuracy, return -1.
        }
        
        let ratio = (Double(rs) * 1.0) / Double(txPower)
        if (ratio < 1.0) {
            return pow(ratio, 10)
        } else {
            let accuracy = (0.89976) * pow(ratio, 7.7095) + 0.111
            return accuracy
        }
    }
    
    static func getNowMillis()->Int64{
        let timeInterval: TimeInterval = Date().timeIntervalSince1970
        let millisecond = CLongLong(round(timeInterval*1000))
        return millisecond
    }
}
