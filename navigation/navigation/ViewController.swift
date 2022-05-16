//
//  ViewController.swift
//  navigation
//
//  Created by 郑旭 on 2021/1/30.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController , MKMapViewDelegate{
    
    var button: UIButton!
    var inScanning:Bool!
    var isInitFunc:Bool!
    var beaconHelper = IBeaconHelper.shared
    var motionHelper = MotionHelper.shared
    
//    var curBeacon:iBeacon?
    var startTime:Int64 = 0
    var currentTime:Int64 = 0
    var indexPre:Int = 0
    var indexCurrent:Int = 0
    var gpsLocation:CLLocation?
    var trueHeaningMagn:CLHeading?
    var timer: Timer!
    var beaconFile:URL!
    var stepDetecor:StepDetector?
    var userHeight:String!
    var realTime:Bool = true
    var preKey:Int64 = 0
    
    var recordData: Bool = true
    
    
    var CounterSys:UILabel!
    var GNSS_Precision:UILabel!
    var PosLat:UILabel!
    var heightText:UITextField!
    var mMap: MKMapView?
    var MoveMapCenter:Bool = true
    var posMark:MKPointAnnotation?
    
    var locationArrayGPS: [CLLocationCoordinate2D] = []
    var locationArrayFilter: [CLLocationCoordinate2D] = []
    var scanService: BeaconScanService? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view,typically from a nib.
        inScanning = true
        isInitFunc = false
        

        self.addMapView()
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ViewController.display), userInfo: nil, repeats: true)

        mMap?.delegate = self
        self.userHeight = "1.7"
        self.stepDetecor = StepDetector(self.userHeight,self.realTime)
        //Gesture to remove the keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        // The enter point of the project
        startCollectDataset()
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
        PosLat.adjustsFontSizeToFitWidth=true
        
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
    
    /*
     Set the hight of the users
     */
    @objc func setHeight(_ btn: UIButton){
        if let hv:String = heightText.text {
            if (hv.count > 0){
                if let _ = Float(hv){
                    self.stepDetecor!.getDetector().setUserHeight(hv)
                }
            }
        }
    }
    /*
     Remove the Makers from the map view
     */
    @objc func removeMaker(_ btn: UIButton){
        removeRouteformMap()
    }
    /*
     Remove the Routes form the map view
     */
    func removeRouteformMap(){
        var shouldRomove: [MKOverlay] = [ ]
        if !self.mMap!.overlays.isEmpty{
            for index in 0 ..< self.mMap!.overlays.count {
                if (self.mMap!.overlays[index].title != nil && self.mMap!.overlays[index].title == "Route"){
                shouldRomove.append(self.mMap!.overlays[index])
                }
            }
            self.mMap!.removeOverlays(shouldRomove)
        }
    }
    /*
    Add route toe the map view
     */
    @objc func routerTo(_ btn: UIButton){
        removeRouteformMap()
        let Route1 = MKPolyline(coordinates: locationArrayGPS, count: locationArrayGPS.count)
        Route1.title = "Route"
        Route1.subtitle = "GPS"
        
        let Route2 = MKPolyline(coordinates: locationArrayFilter, count: locationArrayFilter.count)
        Route2.title = "Route"
        Route2.subtitle = "Filter"
        let region = MKCoordinateRegion(center: locationArrayFilter[0], span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001))
        mMap?.setRegion(region, animated: true)
        mMap?.addOverlay(Route1)
        mMap?.addOverlay(Route2)
        
    }
    
    /*
     Setting up for different Makers
     */
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "MyMarker")
        switch annotation.title!! {
            case "NowPos":
                annotationView.markerTintColor = UIColor.green
            case "GPSPos":
                annotationView.markerTintColor = UIColor.red
            default:
                annotationView.markerTintColor = UIColor.blue
        }
        return annotationView
    }
    
    /*
     Seeting for different route trajectory
     */
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
       
        if let polyline = overlay as? MKPolyline{
            if (polyline.subtitle == "GPS"){
                let renderer = MKPolylineRenderer(polyline: polyline)

                renderer.strokeColor = .red
                renderer.lineWidth = 5.0
                return renderer
            }
            
            if (polyline.subtitle == "Filter"){
                let renderer = MKPolylineRenderer(polyline: polyline)
            
                renderer.strokeColor = .green
                renderer.lineWidth = 5.0
                return renderer
            }
        }else{
            
        }
        NSException(name:NSExceptionName(rawValue: "InvalidMKOverlay"), reason:"Did you add an overlay but forget to provide a matching renderer here? The class was type \(type(of: overlay))", userInfo:["wasClass": type(of: overlay)]).raise()
        return MKOverlayRenderer()
    }
    
    func startCollectDataset(){
        self.motionProcess()
        self.bleProcess()
        self.gpsProcess()
    }
    
    
    /*
     The function to modify the display of the view
     */
    @objc func display(){
        var kalmanFiterPos:CLLocation? = nil
        var displayedHeading:Double = 0.0
        var positionNow:CLLocation? = nil
        var CorrectedPos:CLLocation? = nil
        var GPSLocation:CLLocation? = nil
        var distanceHeanding:Double? = nil
        if let stp = self.stepDetecor {
            positionNow = toMapLocation(stp.getDetector().getPositionNow())
            CorrectedPos = toMapLocation(stp.getDetector().getCorrectedPos())
            displayedHeading = stp.getDetector().getDisplayedHeading()
            distanceHeanding = stp.getDetector().getDistanceHeanding()
            kalmanFiterPos = toMapLocation(stp.getDetector().getKalmanFiterPos())
            GPSLocation = stp.getDetector().data.getGPSlocation()!
            
            
            if (CorrectedPos != nil && CorrectedPos?.coordinate.latitude != -1.0) {
                let lat:Double = CorrectedPos!.coordinate.latitude
                let lon:Double = CorrectedPos!.coordinate.longitude
                let gtxt = "DLat:" + String(Algorithm.formatDouble(lat)) + " " + "DLon:" + String(Algorithm.formatDouble(lon)) + "," + "Pre:" + String(Algorithm.formatDouble(GPSLocation!.horizontalAccuracy))
                self.GNSS_Precision.text = gtxt
                
            } else {
                if let _ = stp.getDetector().data.getGPSlocation() {
                    let gtxt = "Pre:" + String(Algorithm.formatDouble(GPSLocation!.horizontalAccuracy))
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
                updatePosMK(pos: positionNow!,title: "NowPos")
                locationArrayFilter.append(positionNow!.coordinate)
//                print("The value of position now:  " + String(positionNow!.coordinate.latitude) + "," + String(positionNow!.coordinate.longitude))
            }
            if (GPSLocation != nil && GPSLocation?.coordinate.latitude != -1.0) {
                locationArrayGPS.append(GPSLocation!.coordinate)
                updatePosMK(pos: GPSLocation!,title: "GPSPos")
            }
        }
        
        if (MoveMapCenter) {
            if (positionNow != nil && positionNow?.coordinate.latitude != -1.0) {
                //创建一个MKCoordinateSpan对象，设置地图的范围（越小越精确）
                let latDelta = 0.001
                let longDelta = 0.001
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
    
    /*
     Transform the location to "CLLocation" format
     */
    func toMapLocation(_ location: LatLng) -> CLLocation{
        return CLLocation(latitude: location.latitude, longitude: location.longitude)
    }
    
    /*
     Add uer's current location marker to the map view
     */
    func updatePosMK(pos:CLLocation,title:String){
        
        if let mMap = self.mMap {
            for marker in mMap.annotations {
                if (marker.title == title){
                    mMap.removeAnnotation(marker)
                }
            }
        }
        
        let  objectAnnotation = MKPointAnnotation()
        //设置大头针的显示位置
        objectAnnotation.coordinate = pos.coordinate
        //设置点击大头针之后显示的标题
        objectAnnotation.title = title
        //添加大头针
        self.mMap!.addAnnotation(objectAnnotation)
        
    }

    /*
     The functions to process motion sensors
     */
    func motionProcess(){
        let storeFile = FileUtils.urlFile("SensorData")!
        // Here, get the sensor data from montionhelper then store to the file
        motionHelper.setMdBlock{ (pData) in
            if (self.recordData){
                let wsContent = self.getSensorWs(pData)
                FileUtils.writeStrings(storeFile, wsContent)
            }
            self.stepDetecor!.onSensorChanged(pData)// Step Counter 算法触发入口
        }
    }
    
    /*
     Get the data of motion sensors and store to "pData"
     */
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
    
    /*
     The functions to process GPS sensor
     */
    func gpsProcess(){
        let storeFile = FileUtils.urlFile("GpsData")!
        beaconHelper.setGpsDataBlock{ (pData) in
            if (self.recordData){
                let wsContent = self.getGpsWs(pData)
                FileUtils.writeStrings(storeFile, wsContent)
            }
            self.gpsLocation = pData
        }
        beaconHelper.setHeadingDataBlock{ (pData) in
            self.trueHeaningMagn = pData
            self.stepDetecor?.kalmanPositionDetector.setMagnHeading(self.trueHeaningMagn!.trueHeading)
        }
    }
    /*
     Get the data of GPS and sotre to "pData"
     */
    func getGpsWs(_ data:CLLocation)->[String]{
        var wsContent = [String]()
        let tNow = Int64(data.timestamp.timeIntervalSince1970 * 1000)

        let ts = "CurrentTime," + String(tNow)
        wsContent.append(ts)
        
        let position = "Latitude:" + String(data.coordinate.latitude) + ", Longitude" + String(data.coordinate.longitude)
        wsContent.append(position)
        self.stepDetecor?.getDetector().data.setGPSlocation(data, tNow)
        return wsContent
    }
    
    /*
     The functions to process BLE sensor
     */
    func bleProcess(){
        self.beaconFile = FileUtils.urlFile("BeaconData")!
        //Record the BLE data every 0.5 second
        if (self.realTime) {
            self.timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(ViewController.insertBeaconData), userInfo: nil, repeats: true)
        }
        beaconHelper.setBackBeaconBlock { (pData) in
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
            let beaconScanStartTime:Int64 = Int64(Int(self.startTime) + 1000 * self.indexCurrent + 500)
            for tIBeacon in pData {
                var m_beacon = self.toCustomIbeacon(tIBeacon)
                // Sometimes, the record of rssi is zero, here we treat it as -99 (very week signal)
                if (m_beacon.rssi == 0){
                    m_beacon.rssi = -99
                }
                if (self.indexCurrent < 1){
                    self.scanService = BeaconScanService(m_beacon,self.startTime,self.indexCurrent)
                }else{
                    
                }
                if (self.recordData){
                    self.recordScanningData(m_beacon)
                }
                self.stepDetecor?.kalmanPositionDetector.BeaconUsedRecord = true
                self.stepDetecor?.kalmanPositionDetector.setBeaconUsed(m_beacon)
                self.stepDetecor?.kalmanPositionDetector.initSensorChange()
                self.stepDetecor?.kalmanPositionDetector.calculate(indexUsed: 0)
                
                
                
                // ******modified 2022.05.09: find this code is no used
                self.scanService!.StoreSignalPeakDetection(m_beacon, self.currentTime)
                self.scanService!.SignalPeak(self.currentTime)
                // ******modified 2022.05.09: find this code is no use
                self.scanService!.UsedputtempBeaconAverageValues(m_beacon.minor, beaconScanStartTime, Double(m_beacon.rssi))
                

                let KeyDistance:[Int64:[Double]] = BeaconPositioningAlgorithm.CalculateDistanceMapByStrongBeacon(m_beacon, self.scanService!.StoreScannedBeaconStrong)
                if (KeyDistance.count >= 3){
                    self.scanService!.StoreScannedBeaconStrong.removeAll()
                    let StrongBeaconPosXYTemp = BeaconPositioningAlgorithm.CalculatePositionByDistance(KeyDistance)
                    let StrongBeaconPosXY:[Double] =  [StrongBeaconPosXYTemp[0], StrongBeaconPosXYTemp[1], StrongBeaconPosXYTemp[2], StrongBeaconPosXYTemp[3]]
                    self.stepDetecor!.getDetector().setStrongBeaconPosXY(StrongBeaconPosXY)
                }
            }
            self.ibeaconScanDataProcess(Int64(indexDelta), beaconScanStartTime)
            
        }
    }

    
    /*
     Format the stored BLE file (add nil value to the time gap)
     */
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
            
//            FileUtils.writeStrings(self.beaconFile, wsContent)
        }
    }
    
    /*
     Transform the format of BLE samples
     Here merge the major and minor to the minor value: 0-4 is major 5-9 is minor
     */
    func toCustomIbeacon(_ ibc: CLBeacon)->iBeacon{
        var ibeacon = iBeacon()
        ibeacon.major = ibc.major.intValue
        ibeacon.minor = Int64(ibc.major.intValue * 100000) + ibc.minor.int64Value
        ibeacon.proximityUuid = ibc.uuid.uuidString
        ibeacon.rssi = ibc.rssi
        ibeacon.distance = String(format: "%.2f", ibc.accuracy)
        return ibeacon
    }
    
    /*
     Function to scan and process the BLE
     */
    func ibeaconScanDataProcess(_ indexDelta:Int64, _ beaconScanStartTime:Int64){
        let beaconScanStartTime:Int64 = Int64(Int(self.startTime) + 1000 * self.indexCurrent + 500)
        
        if (indexDelta >= 1 && indexDelta < 2) {
            self.scanService!.updateAverageValues(beaconScanStartTime)
            self.scanService!.BuildStrongBeaconMap()
            self.scanService!.GetNonZeroMap(self.scanService!.StrongBeacon)
            self.scanService!.CalculateSlope(self.scanService!.NonZeroStrongMap, self.scanService!.StrongBeacon)
            self.scanService!.StrongBeaconKeyIndicator = CalculateIndicator.StrongIndicator(self.scanService!.minorSlope, &self.scanService!.StrongBeaconKeyIndicator, self.scanService!.StrongBeaconSlopeIndexPlus, self.scanService!.StrongBeaconSlopeIndexMius)
            
            self.scanService!.CalculateWeekBeaconIndicator()
            self.scanService!.MergeHeadingANDClearData()
            self.scanService!.SendHeadingToActivity()
            
            if(!self.scanService!.HeadingIndex.isEmpty && self.scanService!.HeadingIndex[0] != 800){
                stepDetecor!.getDetector().setBeaconHeadVals(Float(self.scanService!.HeadingIndex[0]), self.scanService!.HeadingIndex[1], self.scanService!.HeadingIndex[2])
                self.scanService!.HeadingIndex[0] = 800
            }
        }
    }
    
    /*
     Store the BLE data to the storage
     */
    func recordScanningData(_ m_beacon: iBeacon){
        var wsContent = [String]()
        let line = self.getWsLine(m_beacon.major, m_beacon.minor, m_beacon.rssi, self.startTime, self.currentTime, self.indexPre)
        wsContent.append(line)
        FileUtils.writeStrings(self.beaconFile, wsContent)
    }
    
    /*
     Create string line to be storage for BLE samples
     */
    func getWsLine(_ major:Int,
                   _ minor:Int64,
                   _ rssi:Int,
                   _ start:Int64,
                   _ current:Int64,
                   _ index:Int)->String{
        
        let c_minor = String(major) + String(minor)
        return "postEveryBeacon," + c_minor + "," + String(rssi) + "," + String(start) + "," + String(current) + "," + String(index) + "," + "0"
    }
    
    /*
     Reomve the keyboard from screen
     */
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    /*
    Basic setting for the labels
     */
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
    
    /*
     The functions not used in Lee's version
     */
    
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
    
    func addScanningBtn(){
        button = UIButton(type: .system) as UIButton
        button.addTarget(self,action: #selector(buttonAction(_:)),for: .touchUpInside)
        
        let x:Int = Int(self.view.bounds.width/2)
        let y:Int = Int(self.view.bounds.height/2)
        btnUI(btn: &self.button,text: "Start",x: x,y: y)
        
    }
    
    /*
     System default functions
     */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func printTime(){
        let date = Date()
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "yyy-MM-dd' at 'HH:mm:ss.SSS"
        let strNowTime = timeFormatter.string(from: date) as String
        print(strNowTime)
    }
    
}
