//
//  MotionHelper.swift
//  navigation
//
//  Created by 郑旭 on 2021/1/28.
//
import Foundation
import CoreMotion

struct DeviceData{
    var accelerometer:CMAccelerometerData?
    var gyro:CMGyroData?
    var magnetic:CMMagnetometerData?
    var motion:CMDeviceMotion?
}

///传出蓝牙当前搜索到的设备信息
typealias MotionDeviceBlock = (_ pData: DeviceData) -> Void

class MotionHelper: NSObject {
    static let shared = MotionHelper()
    let motionManager = CMMotionManager()
    var timer: Timer!
    var mdBlock:MotionDeviceBlock?
    static let sampleTime: Double = 20.0 //in millisecond (20 = 50Hz)
    
    override init() {
        super.init()
        self.motionManager.deviceMotionUpdateInterval = 1.0/50.0
        self.motionManager.startAccelerometerUpdates()
        self.motionManager.startGyroUpdates()
        self.motionManager.startMagnetometerUpdates()
        self.motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical)
        
        self.timer = Timer.scheduledTimer(timeInterval: Double(MotionHelper.sampleTime / 1000), target: self, selector: #selector(MotionHelper.update), userInfo: nil, repeats: true)
    }
    
    func setMdBlock(block:@escaping MotionDeviceBlock) {
        self.mdBlock = block
    }
    
    
    @objc func update() {
        var deviceData = DeviceData()
        if let accelerometerData = self.motionManager.accelerometerData {
            deviceData.accelerometer = accelerometerData
        }
        if let gyroData = self.motionManager.gyroData {
            deviceData.gyro = gyroData
        }
        if let magnetometerData = self.motionManager.magnetometerData {
            deviceData.magnetic = magnetometerData
        }
        if let deviceMotion = self.motionManager.deviceMotion {
            deviceData.motion = deviceMotion
        }
        
        if let tBlock = mdBlock {
            tBlock(deviceData)
        }
    }
}
