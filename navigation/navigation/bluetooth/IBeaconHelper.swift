//
//  IBeaconHelper.swift
//  navigation
//
//  Created by 郑旭 on 2021/2/1.
//

import CoreLocation

///传出蓝牙当前搜索到的设备信息
typealias BeaconDataBlock = (_ pData: [CLBeacon]) -> Void
typealias GPSDataBlock = (_ pData: CLLocation) -> Void
typealias HeadingDataBlock = (_ pData: CLHeading) -> Void

class IBeaconHelper: NSObject {
    static let scanUUID = "B5B182C7-EAB1-4988-AA99-B5C1517008D8"
    static let scanIdentifier = "ibeacon location"
    static let shared = IBeaconHelper()
    
    var beaconRegion: CLBeaconRegion?
    var locationManager: CLLocationManager?
    var beaconSatisfying: CLBeaconIdentityConstraint?
    
    var backBeaconDataBlock:BeaconDataBlock?
    var gpsDataBlock:GPSDataBlock?
    var headingDataBlock:HeadingDataBlock?
    
    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager!.delegate = self
        locationManager!.pausesLocationUpdatesAutomatically = false
        //请求一直允许定位
        locationManager!.requestAlwaysAuthorization()
        let uuid = UUID(uuidString: IBeaconHelper.scanUUID)!
//        print(uuid.uuidString)
        beaconRegion = CLBeaconRegion(uuid: uuid, identifier: IBeaconHelper.scanIdentifier)
        beaconRegion!.notifyEntryStateOnDisplay = false
        beaconSatisfying = CLBeaconIdentityConstraint(uuid: uuid)
        //开始扫描
    
        locationManager!.startMonitoring(for: beaconRegion!)
        locationManager!.startRangingBeacons(satisfying: beaconSatisfying!)
        
        
        //gps
        locationManager!.desiredAccuracy = kCLLocationAccuracyBest
        locationManager!.distanceFilter = kCLDistanceFilterNone
        locationManager!.startUpdatingLocation()
        
        //Heading
        locationManager!.startUpdatingHeading()
    }
    
    func setBackBeaconBlock(block:@escaping BeaconDataBlock){
        self.backBeaconDataBlock = block
    }
    
    func setGpsDataBlock(block:@escaping GPSDataBlock){
        self.gpsDataBlock = block
    }
    
    func setHeadingDataBlock(block:@escaping HeadingDataBlock){
        self.headingDataBlock = block
    }
}

extension IBeaconHelper:CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        locationManager!.startRangingBeacons(satisfying: beaconSatisfying!)
        print( "进入beacon区域")
    }
    
    //离开beacon区域
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        locationManager!.stopRangingBeacons(satisfying: beaconSatisfying!)
        print("离开beacon区域")
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        //返回是扫描到的beacon设备数组，这里取第一个设备
        guard beacons.count > 0 else { return }
        if let blockBeaconData = backBeaconDataBlock {
            blockBeaconData(beacons)
//            print("The number of beacons is: " + String(beacons.count))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Failed monitoring region: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        guard locations.count > 0 else {
            return
        }
        let currLocation : CLLocation = locations.last!  // 持续更新
        if let blockGpsData = gpsDataBlock {
            blockGpsData(currLocation)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading){
    
        let currHeading: CLHeading =  newHeading// 持续更新
        if let blockHeadingData = headingDataBlock {
            blockHeadingData(currHeading)
        }
    }
}
