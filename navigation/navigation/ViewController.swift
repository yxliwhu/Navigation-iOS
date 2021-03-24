//
//  ViewController.swift
//  navigation
//
//  Created by 郑旭 on 2021/1/30.
//

import UIKit
import  MapKit
import CoreLocation

class ViewController: UIViewController {
    
    var button: UIButton!
    var inScanning:Bool!
    var isInitFunc:Bool!
    var beaconHelper = IBeaconHelper.shared
    var motionHelper = MotionHelper.shared
    
    var curBeacon:iBeacon?
    var startTime:Int64 = 0
    var currentTime:Int64 = 0
    var indexPre:Int = 0
    var indexCurrent:Int = 0
    var gpsLocation:CLLocation?
    var timer: Timer!
    var beaconFile:URL!
    var stepDetecor:StepDetector?
    var userHeight:String!
    var realTime:Bool = true
    var preKey:Int64 = 0
    
    
    var CounterSys:UILabel!
    var GNSS_Precision:UILabel!
    var PosLat:UILabel!
    var heightText:UITextField!
    var mMap: MKMapView?
    var MoveMapCenter:Bool = true
    var posMark:MKPointAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view,typically from a nib.
        inScanning = false
        isInitFunc = false
        
        if (!realTime) {
            self.addScanningBtn()
        } else {
            self.addMapView()
            Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.display), userInfo: nil, repeats: true)
        }
        self.userHeight = "1.7"
        self.stepDetecor = StepDetector(self.userHeight,self.realTime)
        //Gesture to remove the keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func labelUI(label: inout UILabel,text:String,x:Int,y:Int){
        label.frame.size = CGSize(width: 200,height: 30)
        label.center = CGPoint(x: x, y: y)
        label.textColor = UIColor.red
        label.text = text
        self.view.addSubview(label)
    }
    
    func btnUI(btn: inout UIButton,text:String,x:Int,y:Int){
        btn.frame.size = CGSize(width: 120,height: 50)
        btn.center = CGPoint(x: x, y: y)
        btn.setTitle(text, for: UIControl.State.normal)
        btn.layer.cornerRadius = 10
        btn.layer.borderWidth = 2
        btn.setTitleColor(UIColor.black,for:[.normal])
        btn.layer.borderColor = UIColor.black.cgColor
        btn.tag = 100
        self.view.addSubview(btn)
    }
    
    func textFieldUI(t: inout UITextField,text:String,x:Int,y:Int){
        t.frame.size = CGSize(width: 200,height: 50)
        t.center = CGPoint(x: x, y: y)
        t.placeholder = text
        t.borderStyle = UITextField.BorderStyle.roundedRect
        self.view.addSubview(t)
    }
    
    func addMapView(){
        //使用代码创建
        self.mMap =  MKMapView(frame: self.view.frame)
        self.view.addSubview(self.mMap!)
        
        self.CounterSys = UILabel()
        self.GNSS_Precision = UILabel()
        self.PosLat = UILabel()
        
        labelUI(label: &self.CounterSys, text: "Step:", x: 120, y: 16)
        labelUI(label: &self.GNSS_Precision, text: "GPS:", x: 120, y: 46)
        labelUI(label: &self.PosLat, text: "Heading:", x: 120, y: 76)
        
        var setBtn = UIButton(type: .system) as UIButton
        let sx:Int = Int(self.view.bounds.width - 80)
        let sy:Int = Int(self.view.bounds.height - 200)
        btnUI(btn: &setBtn,text: "SET",x: sx,y: sy)
        setBtn.addTarget(self,action: #selector(setHeight(_:)),for: .touchUpInside)
        
        var rmBtn = UIButton(type: .system) as UIButton
        let rmx:Int = Int(76)
        let rmy:Int = Int(self.view.bounds.height - 136)
        btnUI(btn: &rmBtn,text: "REMOVE",x: rmx,y: rmy)
        rmBtn.addTarget(self,action: #selector(removeMaker(_:)),for: .touchUpInside)
        
        var rBtn = UIButton(type: .system) as UIButton
        let rx:Int = Int(210)
        let ry:Int = Int(self.view.bounds.height - 136)
        btnUI(btn: &rBtn,text: "SHOW",x: rx,y: ry)
        rBtn.addTarget(self,action: #selector(routerTo(_:)),for: .touchUpInside)
        
        heightText = UITextField()
        textFieldUI(t: &heightText,text: "Height(m)",x: 116,y: sy)
        
    }
    
    @objc func setHeight(_ btn: UIButton){
        if let hv:String = heightText.text {
            if (hv.count > 0){
                if let _ = Float(hv){
                    self.stepDetecor!.getDetector().setUserHeight(hv)
                }
            }
        }
    }
    
    @objc func removeMaker(_ btn: UIButton){
        
    }
    
    @objc func routerTo(_ btn: UIButton){
        
    }
    
    func toMapLocation(_ location: LatLng) -> CLLocation{
        return CLLocation(latitude: location.latitude, longitude: location.longitude)
    }
    
    func updatePosMK(pos:CLLocation,title:String){
        if let _ = self.posMark {
            self.mMap!.removeAnnotation(self.posMark!)
        }
        
        let  objectAnnotation = MKPointAnnotation()
        //设置大头针的显示位置
        objectAnnotation.coordinate = pos.coordinate
        //设置点击大头针之后显示的标题
        objectAnnotation.title = title
        self.posMark = objectAnnotation
        //添加大头针
        self.mMap!.addAnnotation(self.posMark!)
        
    }
    
    @objc func display(){
        var kalmanFiterPos:CLLocation? = nil
        var displayedHeading:Double = 0.0
        var positionNow:CLLocation? = nil
        var CorrectedPos:CLLocation? = nil
        var distanceHeanding:Double? = nil
        if let stp = self.stepDetecor {
            positionNow = toMapLocation(stp.getDetector().getPositionNow())
            CorrectedPos = toMapLocation(stp.getDetector().getCorrectedPos())
            displayedHeading = stp.getDetector().getDisplayedHeading()
            distanceHeanding = stp.getDetector().getDistanceHeanding()
            kalmanFiterPos = toMapLocation(stp.getDetector().getKalmanFiterPos())
            
            if (CorrectedPos != nil && CorrectedPos?.coordinate.latitude != -1.0) {
                let lat:Double = CorrectedPos!.coordinate.latitude
                let lon:Double = CorrectedPos!.coordinate.longitude
                let gtxt = "DLat:" + String(Algorithm.formatDouble(lat)) + " " + "DLon:" + String(Algorithm.formatDouble(lon)) + "," + "Pre:" + String(Algorithm.formatDouble(stp.getDetector().data.getGPSlocation()!.horizontalAccuracy))
                self.GNSS_Precision.text = gtxt
                
            } else {
                if let _ = stp.getDetector().data.getGPSlocation() {
                    let gtxt = "Pre:" + String(Algorithm.formatDouble(stp.getDetector().data.getGPSlocation()!.horizontalAccuracy))
                    self.GNSS_Precision.text = gtxt
                }
            }
            
            
            if (stp.getDetector().data.getStepNumOwn() != 0.0) {
                let ctxt = "Step:" + String(stp.getDetector().data.getStepNumOwn())
                self.CounterSys.text = ctxt
            }
            if (displayedHeading != 0.0) {
                var DisplayHeading:Double = 0
                if (distanceHeanding! < 0) {
                    DisplayHeading = distanceHeanding! + 360.0
                    let cmtxt = "UsedAngle:" + String(Algorithm.formatDouble(DisplayHeading)) + "Heading:" + String(Algorithm.formatDouble(displayedHeading))
                    self.PosLat.text = cmtxt
                } else {
                    let cmtxt = "UsedAngle:" + String(Algorithm.formatDouble(distanceHeanding!)) + "Heading:" + String(Algorithm.formatDouble(displayedHeading))
                    self.PosLat.text = cmtxt
                }
                
            } else {//DisplayedHeading == 0.0
                var DisplayHeading:Double = 0.0
                if (distanceHeanding! < 0) {
                    DisplayHeading = distanceHeanding! + 360.0
                    let cmtxt = "UsedAngle:" + String(Algorithm.formatDouble(DisplayHeading))
                    self.PosLat.text = cmtxt
                } else {
                    let cmtxt =  "UsedAngle:" + String(Algorithm.formatDouble(distanceHeanding!))
                    self.PosLat.text = cmtxt
                    
                }
            }
            ///todo:display location on google map
            
            if (positionNow != nil && positionNow?.coordinate.latitude != -1.0) {
                updatePosMK(pos: positionNow!,title: "RawPos")
            }
            if (kalmanFiterPos != nil && kalmanFiterPos?.coordinate.latitude != -1.0) {
                updatePosMK(pos: kalmanFiterPos!,title: "RawPos")
            }
        }
        
        if (MoveMapCenter) {
            if (positionNow != nil && positionNow?.coordinate.latitude != -1.0) {
                //创建一个MKCoordinateSpan对象，设置地图的范围（越小越精确）
                let latDelta = 0.05
                let longDelta = 0.05
                let currentLocationSpan: MKCoordinateSpan  =  MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
                
                //定义地图区域和中心坐标（
                //使用当前位置
                //var center:CLLocation = locationManager.location.coordinate
                //使用自定义位置
                let center: CLLocation = positionNow!
                let currentRegion: MKCoordinateRegion = MKCoordinateRegion (center: center.coordinate, span: currentLocationSpan)
                
                //设置显示区域
                self.mMap!.setRegion(currentRegion, animated:  true )
                MoveMapCenter = false
            }
        }
        
    }
    func addScanningBtn(){
        button = UIButton(type: .system) as UIButton
        button.addTarget(self,action: #selector(buttonAction(_:)),for: .touchUpInside)
        
        let x:Int = Int(self.view.bounds.width/2)
        let y:Int = Int(self.view.bounds.height/2)
        btnUI(btn: &self.button,text: "Start",x: x,y: y)
        
    }
    
    func getWsLine(_ major:Int,
                   _ minor:Int64,
                   _ rssi:Int,
                   _ start:Int64,
                   _ current:Int64,
                   _ index:Int)->String{
        
        let c_minor = String(major) + String(minor)
        return "postEveryBeacon," + c_minor + "," + String(rssi) + "," + String(start) + "," + String(current) + "," + String(index) + "," + "0"
    }
    
    func toCustomIbeacon(_ ibc: CLBeacon)->iBeacon{
        var ibeacon = iBeacon()
        ibeacon.major = ibc.major.intValue
        ibeacon.minor = ibc.minor.int64Value
        ibeacon.proximityUuid = ibc.uuid.uuidString
        ibeacon.rssi = ibc.rssi
        ibeacon.distance = String(format: "%.2f", ibc.accuracy)
        
        return ibeacon
    }
    
    func recordScanningData(){
        var wsContent = [String]()
        let line = self.getWsLine(self.curBeacon!.major, self.curBeacon!.minor, self.curBeacon!.rssi, self.startTime, self.currentTime, self.indexPre)
        wsContent.append(line)
        
        FileUtils.writeStrings(self.beaconFile, wsContent)
    }
    
    @objc func insertBeaconData(){
        guard self.inScanning else {
            return
        }
        let nTime = iBeaconClass.getNowMillis()
        let seqTime = nTime - self.currentTime
        if (seqTime >= 500){
            var wsContent = [String]()
            let line = "postEveryBeacon," + "0" + "," + "0" + "," + String(self.startTime) + "," + String(nTime) + "," + String(self.indexPre) + "," + "0"
            wsContent.append(line)
            
            FileUtils.writeStrings(self.beaconFile, wsContent)
        }
    }
    
    func ibeaconScanDataProcess(_ indexDelta:Int64){
        let scanService = BeaconScanService(self.curBeacon!,self.startTime,self.indexCurrent)
        scanService.StoreSignalPeakDetection(self.curBeacon!, self.currentTime)
        scanService.SignalPeak(self.currentTime)
        let KeyDistance:[Int64:[Double]] = BeaconPositioningAlgorithm.CalculateDistanceMapByStrongBeacon(self.curBeacon!, scanService.StoreScannedBeacon)
        if (KeyDistance.count > 3){
            let StrongBeaconPosXYTemp = BeaconPositioningAlgorithm.CalculatePositionByDistance(KeyDistance)
            let StrongBeaconPosXY:[Double] =  [StrongBeaconPosXYTemp[0], StrongBeaconPosXYTemp[1], StrongBeaconPosXYTemp[2], StrongBeaconPosXYTemp[3]]
            self.stepDetecor!.getDetector().setStrongBeaconPosXY(StrongBeaconPosXY)
        }
        if (self.realTime){
            self.stepDetecor!.getDetector().setBeaconUsed(self.curBeacon!)
            self.stepDetecor!.getDetector().setBeaconUsedRecord(true)
            
            if (scanService.ResultKeyTimeSize!.Key != preKey){
                self.stepDetecor!.getDetector().setKeyTimeSize(scanService.ResultKeyTimeSize!)
                self.preKey = scanService.ResultKeyTimeSize!.Key
            }
        }
        let beaconScanStartTime:Int64 = Int64(Int(self.startTime) + 1000 * self.indexCurrent + 500)
        if (indexDelta < 1) {
            scanService.UsedputtempBeaconAverageValues(self.curBeacon!.minor, beaconScanStartTime, Double(self.curBeacon!.rssi))
        }
        
        if (indexDelta >= 1 && indexDelta < 2) {
            
            scanService.UsedputtempBeaconAverageValues(self.curBeacon!.minor, beaconScanStartTime, Double(self.curBeacon!.rssi))
            
            scanService.updateAverageValues(beaconScanStartTime)
            scanService.BuildStrongBeaconMap()
            scanService.GetNonZeroMap(scanService.StrongBeacon)
            scanService.CalculateSlope(scanService.NonZeroStrongMap, scanService.StrongBeacon)
            scanService.StrongBeaconKeyIndicator = CalculateIndicator.StrongIndicator(scanService.minorSlope, &scanService.StrongBeaconKeyIndicator, scanService.StrongBeaconSlopeIndexPlus, scanService.StrongBeaconSlopeIndexMius)
            
            scanService.CalculateWeekBeaconIndicator()
            scanService.MergeHeadingANDClearData()
            scanService.SendHeadingToActivity()
            
            if(self.realTime && scanService.HeadingIndex[0] != 800){
                stepDetecor!.getDetector().setBeaconHeadVals(Float(scanService.HeadingIndex[0]), scanService.HeadingIndex[1], scanService.HeadingIndex[2])
            }
        }
    }
    
    func bleProcess(){
        self.beaconFile = FileUtils.urlFile("BeaconData")!
        if (!self.realTime) {
            self.timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(ViewController.insertBeaconData), userInfo: nil, repeats: true)
        }
        beaconHelper.setBackBeaconBlock { (pData) in
            guard self.inScanning else {
                return
            }
            if (self.startTime == 0) {
                self.startTime = iBeaconClass.getNowMillis()
            }
            self.currentTime = iBeaconClass.getNowMillis()
            let seqTime = self.currentTime - self.startTime
            
            self.indexCurrent = Int(floor(Double(seqTime) / 1000.0))
            let indexDelta = self.indexCurrent - self.indexPre
            
            if (indexDelta >= 1 && indexDelta < 2) {
                self.indexPre = self.indexCurrent
            }
            if(indexDelta >= 2){
                let tNow = iBeaconClass.getNowMillis()
                let tq = tNow - self.startTime
                let tempIndex = Int(floor(Double(tq) / 1000.0))
                self.indexPre = tempIndex
            }
            
            for tIBeacon in pData {
                self.curBeacon = self.toCustomIbeacon(tIBeacon)
                if (!self.realTime){
                    self.recordScanningData()
                }
                self.ibeaconScanDataProcess(Int64(indexDelta))
            }
        }
    }
    
    func getSensorWs(_ data:DeviceData)->[String]{
        var wsContent = [String]()
        let tNow = iBeaconClass.getNowMillis()
        let ts = "CurrentTime," + String(tNow)
        wsContent.append(ts)
        
        let accelerometer = "Accelerometer," + String(data.accelerometer!.acceleration.x) + "," + String(data.accelerometer!.acceleration.y) + "," + String(data.accelerometer!.acceleration.z)
        wsContent.append(accelerometer)
        
        let gyro = "GyroScope," + String(data.gyro!.rotationRate.x) + "," + String(data.gyro!.rotationRate.y) + "," + String(data.gyro!.rotationRate.z)
        
        wsContent.append(gyro)
        
        let magnetic = "Magnetic," + String(data.magnetic!.magneticField.x) + "," +
            String(data.magnetic!.magneticField.y) + "," + String(data.magnetic!.magneticField.z)
        wsContent.append(magnetic)
        
        let gravity = "Motion-Gravity," + String(data.motion!.gravity.x) + "," + String(data.motion!.gravity.y) + "," + String(data.motion!.gravity.z)
        
        wsContent.append(gravity)
        
        let attitude = "Motion-Attitude," + String(data.motion!.attitude.pitch) + "," + String(data.motion!.attitude.roll) + "," + String(data.motion!.attitude.yaw)
        
        wsContent.append(attitude)
        
        let rotationRate = "Motion-RotationRate," + String(data.motion!.rotationRate.x) + "," +
            String(data.motion!.rotationRate.y) + "," + String(data.motion!.rotationRate.z)
        
        if let tlocation = self.gpsLocation {
            let gpsInfo = "GPS," + String(tlocation.coordinate.latitude) + "," + String(tlocation.coordinate.longitude) + "," + String(tlocation.altitude)
            wsContent.append(gpsInfo)
        }
        
        wsContent.append(rotationRate)
        return wsContent
    }
    
    func motionProcess(){
        let storeFile = FileUtils.urlFile("SensorData")!
        motionHelper.setMdBlock{ (pData) in
            guard self.inScanning else {
                return
            }
            if (!self.realTime) {
                let wsContent = self.getSensorWs(pData)
                FileUtils.writeStrings(storeFile, wsContent)
            }
            self.stepDetecor!.onSensorChanged(pData)// 算法触发入口
        }
    }
    
    func gpsProcess(){
        beaconHelper.setGpsDataBlock{ (pData) in
            self.gpsLocation = pData
            self.stepDetecor!.data.setGPSlocation(self.gpsLocation!, iBeaconClass.getNowMillis())
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /// 响应按钮点击事件
    @objc func buttonAction(_ btn: UIButton)->Bool {
        if let isScanning = inScanning {
            guard !isScanning else{
                button.setTitle("Start", for: UIControl.State.normal)
                inScanning = false
                return false
            }
            
            button.setTitle("Scanning", for: UIControl.State.normal)
            inScanning = true
            guard !isInitFunc else {
                return false
            }
            self.motionProcess()
            self.bleProcess()
            self.gpsProcess()
            isInitFunc = true
        }
        
        return true
    }
    
}
