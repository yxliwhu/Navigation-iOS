//
//  KalmanPositionDetector.swift
//  navigation
//
//  Created by 郑旭 on 2021/1/26.
//

import Foundation

class KalmanPositionDetector {
    var counter:Int = 0
    var accNow:Double = 0.0
    var accPre:Double = 0.0
    var peakPre:Double = 0.0
    var numDown:Int = 0
    var numUp:Int = 0
    var stepNum:Double = 0.0
    var UPDATE_FREQUENCY:Double = 50.0
    var stepNow:Double = 0.0
    var stepPre:Double = 0.0
    var allDistance_N:Double = 0.0
    var allDistence_S:Double = 0.0
    var PreTime:Int64 = 0
    var PreStepRecord:Float = 0.0
    var DeltaStep:Float = 0
    var RecordNowTime:Bool = true
    var AdjuststepLong:Float = 0.0
    var distance:Double = 0.0
    var AdjuststepLengthBeacon:Float = 0.0
    var StartAdjustStep:Float = 0.0
    var distanceBeacon:Float = 0.0
    var UpdatedTimeFirst:Bool = true
    var PreGetGPSTime:Int64 = 0
    var PreGetDGPStime:Int64 = 0
    
    var Realtime:Bool
    var CurrentTime:Int64 = 0
    // ArrayList<String> ReciveValueFromService_List = new ArrayList<>()
    var iniSystem:Bool = true
    var iniTime:Int64 = 0
    var currentIndex:Int = 0
    var BeaconUsedRecord:Bool = false
    var BeaconUsed:iBeacon
    var BeaconSignalThreshold:Float = -88.0
    var weakMinorRssiIndex = [Int64:[[[Int]]]]()
    var timeWindow:Int = 2
    var frequency:Int = 3
    
    var StrongBeaconPosXY = [Double]()
    var PreStrongBeaconPosXY = [Double]()
    var initialHeading:Float = -800.0//16.5  11.4
    var data:Data
    var StrongBeaconHeadingIndex:Double = 0.0
    var WeekBeaconHeadingIndex:Double = 0.0
    var GetGPSTime:Int64 = 0
    var GetDGPStime:Int64 = 0
    var CorrectedPos:LatLng = navigation.LatLng(-1.0,-1.0)
    var positionNow:LatLng = navigation.LatLng(-1.0,-1.0)
    var positionPast:LatLng = navigation.LatLng(-1.0,-1.0)
    var algorithm:Algorithm
    var starttimeNowForRecordPosition:Int64 = 0
    var TimeWindowRecordTimePositionStep:Int64 = 10000
    var StoredPosition = [[Double]]()
    var keyTimeSize:KeyTimeSize
    var selfKey:Int64 = 0
    var deltaXY:[Double] = [0.0, 0.0, 0.0, 0.0]
    var RoadWith:Double = 0.3 // use for PositionByBeacon(int centerBeacon, double RoadWidth, double velecity)
    var Velecity:Double = 1.2 // use for PositionByBeacon(int centerBeacon, double RoadWidth, double velecity)
    var filePath:String = ""
    var PDRflag:Bool = false
    var stepNumber:Double = 0.0
    var key:Double = 0.0
    var stepLong:Float = 0.7
    var StepLenghtTimeDifference:Float = 1000.0
    var userHeight:String
    
    var BeaconList = [Double]()
    var TurnAngleList = [Double]()
    var StepListForLength = [Double]()
    var TurnAngleThreshold:Double = 60.0
    var MaxBeaconAdjustStepLenghtThreshold:Double = 1.0 // max step length adjustment value limitation
    var MiNBeaconAdjustStepLenghtThreshold:Double = 0.2 // min step length adjustment value limitation
    var preTimeUsed:Int64 = 0
    
    var lp:Float = 0.0
    var step:Double = 0.0
    
    var mValues = [Float](repeating: 0, count: 3)
    var mMatrix = [Float](repeating: 0, count: 9)
    var magnHeading:Double = -800.0
    
    var MygyroHeading:Float = 0.0
    var CountTime:Int = 0
    var StartTime:Int64 = 0
    var Angle:Float = 0.0
    var TimeGyroAngle = [Float]()
    // double Elevation = 9999
    var GPSPrecisionLimitedForPDRStrategy:Double = 5.0
    
    var allDistance:[Double] = [0.0, 0.0]
    var allDistancePast:[Double] = [0.0, 0.0]
    var distanceHeanding:Double = 0.0
    var Scale:Double = 0
    
    var ProgramStart:Bool = true
    var lastUsedBeaconMinor:Int64 = 0
    var lastUsedBeaconTime:Int64 = 0
    var BeaconSurveyorDistance:Double = 0.0
    
    var KalmanFiterPos:LatLng = navigation.LatLng(-1, -1)
    var SetInitial:Bool = true
    var X_k:Matrix
    var P_k:Matrix
    var X_k_1:Matrix
    var P_k_1:Matrix
    
    var PDRPrecisionComputed:Double = 0 //PDR Precision
    //ArrayList<MarkerOptions> allBeaconMarker = new ArrayList<MarkerOptions>()
    var allBeaconMarker = [navigation.LatLng]()
    var UseInternalGPS:Bool = true
    var InitialGPSPrecision:Double = 23.0
    var hdop:Double = 0.0
    
    //private PolylineOptions BeaconDRRouteOptions = new PolylineOptions()
    //private PolylineOptions BeaconDRRouteOptionsFilter = new PolylineOptions()
    
    //PolylineOptions GPSDRRouteOptions = new PolylineOptions()
    var gpsPosList = [navigation.LatLng]()
    var HDOPThreshold:Double = 33.0 // Set the HDOP filter threshold value  20ye
    var DiffOfGetGPSTime:Int64 = 0
    var DiffofDGPSTime:Int64 = 0
    var GPSPosPrevious = [Double](repeating: 0.0, count: 2) // Previous GPS position
    var GPSPosNow = [Double](repeating: 0.0, count: 2)// Current GPS position
    var PDRTotalDistance:Double = 0.0
    var PrePDRTotalDistance:Double = 0.0
    var PDRTotalNE:[Double] = [0, 0]
    var PrePDRTotalNE:[Double] = [0, 0]
    var GPSTotalDistance:Double = 0 // GPS Moved distance from start point
    var VList = [[Double]]()
    var PreviousPrecisionGPS:[Double] = [0, 0]
    var kalmanFilterFunction:KalmanFilterFunction
    var lastUsedBeaconTimeThreshold:Double = 320000.0//180000； 75000；
    var setR:Bool = false
    var NotUseGPSTime:Int64 = 0
    var ProgramStartTime:Int64 = 0
    
    // PostBeaconScan postBeaconScan
    var DisplayedHeading:Float = 0.0
    var gyroHeadingUsed:Float = 0.0
    var UseBeaconHeading:Bool = false
    var goAhead:Bool = true
    var BiasOfHeadingBeaconHeadig:Double = 30.0
    var stepUsed:Double = 0.0
    
    init(_ data:inout Data,_ userHeight:String,_ realtime:Bool){
        self.data = data
        self.userHeight = userHeight
        self.Realtime = realtime
        self.kalmanFilterFunction = navigation.KalmanFilterFunction()
        self.algorithm = navigation.Algorithm()
        self.BeaconUsed = iBeacon()
        self.keyTimeSize = KeyTimeSize()
        self.X_k = Matrix(paramInt1: 4,paramInt2: 4)
        self.P_k = Matrix(paramInt1: 4,paramInt2: 4)
        self.X_k_1 = Matrix(paramInt1: 4,paramInt2: 4)
        self.P_k_1 = Matrix(paramInt1: 4,paramInt2: 4)
    }
    
    func initSensorChange(){
        // Get the time for the system start
        self.CurrentTime = iBeaconClass.getNowMillis()
        if (self.iniSystem) {
            self.iniTime = self.CurrentTime
            self.iniSystem = false
        }
        self.currentIndex = Int((CurrentTime - iniTime) / 1000)
        
        if (self.BeaconUsedRecord) {
            self.BeaconUsedRecord = false
            
            var RssiTime = [[Int]](repeating: [Int](repeating: 0, count: 2), count: 1)
            if (self.BeaconUsed.rssi > Int(self.BeaconSignalThreshold)) {//只有当RSSI大于-88，才会加入到weakMinorRssiIndex中
                RssiTime[0][0] = self.BeaconUsed.rssi
                RssiTime[0][1] = Int((self.CurrentTime - self.iniTime) / 1000)
                var weakRssiTime = [[[Int]]]()
                if (self.weakMinorRssiIndex[self.BeaconUsed.minor] != nil) {
                    weakRssiTime = self.weakMinorRssiIndex[self.BeaconUsed.minor]!
                    let lastIndex = weakRssiTime[0][0][1]
                    if (Int(RssiTime[0][1]) - lastIndex > self.timeWindow){//修改为，将连续3秒时间内的RSSI和time记下来
                        self.weakMinorRssiIndex.removeValue(forKey: self.BeaconUsed.minor)
                        weakRssiTime.removeAll()
                    }
                    weakRssiTime.append(RssiTime)
                } else {
                    weakRssiTime.append(RssiTime)
                }
                self.weakMinorRssiIndex[self.BeaconUsed.minor] = weakRssiTime
            }
            
            var rmKeys = [Int64]()
            for (k,v) in self.weakMinorRssiIndex {
                let list = v
                let timeIndex = list[0][0][1]
                if ((self.currentIndex - timeIndex) > 10) {//当weakMinorRssiIndex里面存放的某个beacon的时间过于久远（和当前时间相隔超过10秒）就将其信息删除
                    rmKeys.append(k)
                }
            }
            for rk in rmKeys {
                self.weakMinorRssiIndex.removeValue(forKey: rk)
            }
            //todo:挑选出weakMinorRssiIndex里面链表最长的weak beacon做为当前定位的位置
            var max_size = 0
            var max_time = 0
            var size = 0
            var time = 0
            var minorSelected:Int64 = 0
            var minorRssi = 0
            for (k,v) in self.weakMinorRssiIndex {
                size = self.weakMinorRssiIndex[k]!.count
                if (size > max_size) {
                    max_size = size
                    minorSelected = k
                    minorRssi = v[max_size - 1][0][0]
                    max_time = v[max_size - 1][0][1]
                } else if (size == max_size) {//当链表长度一致时，哪个beacon的时间最新，就选择哪个beacon
                    time = v[size - 1][0][1]
                    if (time >= max_time) {
                        max_time = time
                        minorSelected = k
                        minorRssi = v[size - 1][0][0]
                    }
                }
            }
            if (minorSelected != 0) {
                var usedBeacon = iBeacon()
                usedBeacon.minor = minorSelected
                usedBeacon.rssi = minorRssi
                self.BeaconUsed = usedBeacon
            }
            //todo: when received weakbeacon is more than 3 times in 1 second, then remove previous weakbeacon in case PDR go back to prevoious beacon
            let listNow = self.weakMinorRssiIndex[self.BeaconUsed.minor]
            if (listNow != nil && !listNow!.isEmpty && listNow!.count >= self.frequency) {
                let indexNow = listNow![0][0][1]
                var rmKeys_0 = [Int64]()
                for (k,v) in self.weakMinorRssiIndex {
                    let list = v
                    let IndexBefore = list[0][0][1]
                    if (IndexBefore < indexNow) {//当weakMinorRssiIndex里面存放的某个beacon的时间过于久远（和当前时间相隔超过10秒）就将其信息删除
                        rmKeys_0.append(k)
                    }
                }
                for rk in rmKeys_0 {
                    self.weakMinorRssiIndex.removeValue(forKey: rk)
                }
            }
        }
        
        
        if (!self.StrongBeaconPosXY.isEmpty) {
            if (self.PreStrongBeaconPosXY != self.StrongBeaconPosXY) {
                self.PreStrongBeaconPosXY = self.StrongBeaconPosXY
            }
        }
        
        
        if (self.data.getGPSlocation()!.coordinate.latitude != -1 && self.data.getGPSlocation()!.coordinate.longitude != -1) {
            self.GetGPSTime = data.getGPSGetTime()
            if (self.PreGetGPSTime != self.GetGPSTime) {
                self.PreGetGPSTime = self.GetGPSTime
            }
        }
        
        if (self.CorrectedPos.latitude != -1 && self.CorrectedPos.longitude != -1) {
            if (self.PreGetDGPStime != self.GetDGPStime) {
                self.PreGetDGPStime = self.GetDGPStime
            }
        }
        
        ////todo: self part is to set x,y, step for detected signal peak for beacon
        if (self.positionNow.latitude != -1) {
            let xy = self.algorithm.LatLongToDouble(self.positionNow) // Convert KalamnFilterPos to double values
            if (self.UpdatedTimeFirst) {
                self.starttimeNowForRecordPosition = self.CurrentTime // update starttimeNowForRecordPosition in the first time
                self.UpdatedTimeFirst = false
            }
        }
        ////todo: End
        ////todo: self part is for step length adjustment using model correction
        let PreStepLength = stepLong// Get previous steplength
        //Step length adjustment method 1
        if (self.RecordNowTime) {
            self.PreTime = self.CurrentTime // update time
            self.PreStepRecord = self.data.getStepNumOwn() //update recorded previous step number
            self.RecordNowTime = false
        }
        if ((self.CurrentTime - self.PreTime) > Int64(StepLenghtTimeDifference)) {
            self.DeltaStep = self.data.getStepNumOwn() - PreStepRecord // calculate delta step number
            distance = distance + Double(DeltaStep * AdjuststepLong) // calculate accumulative distance
            var str1 = ""
            str1 = self.userHeight// Get surveyor height
            //str1="1.76"
            if (str1.contains(".")) {
                let height = Float(str1) // Get surveyor height
                //stepLong = StepLenghtAdjustmentByChenMethod(height, DeltaStep)
                self.AdjuststepLong = Algorithm.StepLenghtAdjustmentByChenMethod(height!, DeltaStep) // Ajust step length by model
                self.stepLong = self.AdjuststepLong//set adjusted step length to step length
//                print("The value of Step length:  " + String(self.stepLong))
                // WriteFile.writeTxtToFiles(filePath, fileNameStartTime + "AdjustStepLenghtChen.txt", String.valueOf(AdjuststepLong) + "," + data.getStepNumOwn() + "," + distance + "\n")
                self.RecordNowTime = true
            }
            
        }
        //todo: End the method model correction
        //todo The second step lenght adjustment method using week beacon correction
        if (self.deltaXY[3] != 0.0) {
            //deltaXY[2] denotes the strong signal step number
            //deltaXY[3] denotes the strong signal beacon object
            let adjustResult = self.OptimizeStepLength(Int64(deltaXY[3]), stepLong)// Get step length correct result
            self.AdjuststepLengthBeacon = adjustResult[0]
            if (self.AdjuststepLengthBeacon != 0) {
                if (self.stepLong != AdjuststepLengthBeacon) {
                    self.stepLong = AdjuststepLengthBeacon//set adjusted step length to step length
                    self.StartAdjustStep = adjustResult[1] // used strong signal step value not begin adjusted step
                }
            }
        }
        
        if (self.stepPre != self.stepNow) {
            self.distanceBeacon = (self.data.getStepNumOwn() - self.StartAdjustStep) * self.AdjuststepLengthBeacon // self is for test, calculate the adjusted distance, compare to real distance
        }
    }
    
    /*
     Main enter point for the position calculation
     */
    func calculate(){
        self.calculateDistanceChanged(self.data)//Calculate changed distance
        if (self.positionNow.latitude == -1 && self.ProgramStart){
            self.ProgramStart = getInitialPosition(self.data, self.BeaconUsed, self.allDistance)
            self.data.setStartStep(self.stepNow)
            self.preTimeUsed = self.CurrentTime
        }else{
            if (self.CurrentTime - self.preTimeUsed > 1000) {
                //if step changed or new week beacon appeared
                let allDistancePastUsed = self.allDistancePast
                self.CalculatePosition(self.data, self.allDistance, allDistancePastUsed, self.positionPast, self.BeaconUsed, self.CurrentTime)
                self.data.setStartStep(self.stepNow)
                self.preTimeUsed = self.CurrentTime
            } else{
                // Do nothing when the time is less than 1000ms
            }
        }
    }
    
    func getInitialPosition(_ data_p:Data, _ BeaconUsed_p:iBeacon, _ DistanceNow:[Double]) -> Bool{
        if (!self.weakBeaconForPositioning(BeaconUsed_p,DistanceNow)){
            return self.weakBeaconForPositioning(BeaconUsed_p,DistanceNow)
        }else if (!self.strongBeaconforPositioning(BeaconUsed_p)) {
            return self.strongBeaconforPositioning(BeaconUsed_p)
        }else if (!self.GPSforPositioning(data_p, DistanceNow)){
            return self.GPSforPositioning(data_p, DistanceNow)
        } else{
            return true
        }
    }
    
    /*
     Using weak beacon for the Initial positioning
     */
    func weakBeaconForPositioning(_ m_beacon: iBeacon, _ DistanceNow:[Double]) -> Bool {
        var result: Bool = true
        if (m_beacon.rssi >= Int(self.BeaconSignalThreshold) && BeaconCoordinates.positionFromBeacon(m_beacon.minor).latitude != -1){
            let WeekBeaconPos = BeaconCoordinates.positionFromBeacon(m_beacon.minor)// get coordinates
            if (self.weakMinorRssiIndex[m_beacon.minor] != nil && self.weakMinorRssiIndex[m_beacon.minor]!.count >= self.frequency) {//当某个weak beacon在同一个index中有至少三个RSSI大于-88
                self.positionNow = BeaconCoordinates.positionFromBeacon(m_beacon.minor)
                self.allDistancePast[0] = DistanceNow[0]
                self.allDistancePast[1] = DistanceNow[1]
                self.positionPast = self.positionNow
                self.KalmanFiterPos = self.positionNow
                if (self.allBeaconMarker.count == 0) {
                    self.allBeaconMarker.append(WeekBeaconPos)
                } else {
                    var count = 0
                    for i in  0..<self.allBeaconMarker.count {
                        if (self.allBeaconMarker[i].equals(WeekBeaconPos)) {
                            break//如果链表里已经存有这个beacon的位置，就不再往里存放
                        } else {
                            count += 1
                            if (count == self.allBeaconMarker.count) {
                                //MarkerOptions BeaconMarkerOptions = new MarkerOptions()
                                self.allBeaconMarker.append(WeekBeaconPos)
                            }
                        }
                    }
                }
                result = false
            }
        }
        return result
    }
    
    /*
     Using Strong beacon for the Initial positioning
     */
    func strongBeaconforPositioning (_ m_beacon: iBeacon) -> Bool {
        var result: Bool = true
        if (!self.StrongBeaconPosXY.isEmpty && self.StrongBeaconPosXY[0] != 0) {
            let strongBeaconXY:[Double] = [self.StrongBeaconPosXY[0], self.StrongBeaconPosXY[1]]
            let strongBeaconXYPrecision:[Double] = [self.StrongBeaconPosXY[2], self.StrongBeaconPosXY[3]]
            let xy = self.algorithm.DoubleToLatLong(strongBeaconXY)
            self.positionNow = navigation.LatLng(xy.latitude, xy.longitude)
            self.positionPast = self.positionNow
            self.KalmanFiterPos = self.positionNow
            result = false
        }
        return result
    }
    
    /*
     Using GPS for the Initial positioning
     */
    func GPSforPositioning (_ data_p: Data, _ DistanceNow:[Double]) -> Bool{
        var result: Bool = true
        if (self.currentIndex > 3) {
            if (data_p.getGPSlocation()!.coordinate.latitude != -1 && data_p.getGPSlocation()!.coordinate.longitude != -1) {
                self.positionNow = navigation.LatLng(data_p.getGPSlocation()!.coordinate.latitude, data_p.getGPSlocation()!.coordinate.longitude)
            }
            if (self.positionNow.latitude != -1) {
                self.allDistancePast[0] = DistanceNow[0]
                self.allDistancePast[1] = DistanceNow[1]
                self.positionPast = self.positionNow
                self.KalmanFiterPos = self.positionNow
            }
            result = false
        }
        return result
    }
    
    func CalculatePosition(_ data_p:Data, _ DistanceNow:[Double],
                           _ DistancePast: [Double], _ PastPos:LatLng, _ beaconUsed:iBeacon, _ CurrentTime_p:Int64) {
        
        if (data_p.getGPSlocation()!.coordinate.latitude != -1) {
            if (data_p.getGPSlocation()!.horizontalAccuracy <= self.GPSPrecisionLimitedForPDRStrategy) {
                CalculatePosUseGPSOnly(data_p, DistanceNow, DistancePast)
            } else {
                CalculatePosBeaconPDR(beaconUsed, DistanceNow, DistancePast, PastPos)
            }
        } else {
            CalculatePosBeaconPDR(beaconUsed, DistanceNow, DistancePast, PastPos)
        }
    }

    func CalculatePosBeaconPDR(_ beaconUsed:iBeacon, _ DistanceNow:[Double],
                               _ DistancePast:[Double], _ PastPos:LatLng) {
        
        if (self.PDRflag) {
            let xy = self.algorithm.LatLongToDouble(positionNow)
            let xy_correct:[Double] = [xy[0] + deltaXY[0], xy[1] + deltaXY[1]]
            self.positionNow = self.algorithm.DoubleToLatLong(xy_correct)
            self.positionPast = self.positionNow
            self.allDistancePast[0] = self.allDistance[0]
            self.allDistancePast[1] = self.allDistance[1]
            self.PDRflag = false
        } else {
            self.positionNow = calculateBeaconDRPosition(PastPos, DistanceNow, DistancePast)
            self.positionPast = self.positionNow
            self.allDistancePast[0] = self.allDistance[0]
            self.allDistancePast[1] = self.allDistance[1]
        }
    }
    
    
    func CalculatePosUseGPSOnly(_ data_p:Data, _ DistanceNow:[Double],
                                _ allDistancePast: [Double]) {
        if (self.CorrectedPos.latitude != -1 && CorrectedPos.longitude != 0) {
            //DGPS Position is not null
            self.positionNow = self.CorrectedPos
        } else {
            //Use GPS value
            self.positionNow = navigation.LatLng(data_p.getGPSlocation()!.coordinate.latitude, data_p.getGPSlocation()!.coordinate.longitude)
        }
        self.allDistancePast[0] = DistanceNow[0]
        self.allDistancePast[1] = DistanceNow[1]
        self.positionPast = self.positionNow
    }
    
    
    
    /*
     Update the positiong with past locaiton and moving distance
     */
    func calculateBeaconDRPosition(_ PastP:LatLng, _ Distance:[Double],
                                   _ DistancePast:[Double]) ->LatLng{
        var now:[Double] = [0.0, 0.0]
        let past = self.algorithm.LatLongToDouble(PastP)// Past Position
        now[0] = past[0] + Distance[0] - DistancePast[0]//Now Coordinate
        now[1] = past[1] + Distance[1] - DistancePast[1]//Now Coordinate
        let result = self.algorithm.DoubleToLatLong(now)
        return result
    }
    
    
    
    /*
     Calcuate the heading info
     */
    func calculateDistanceChanged(_ data_p:Data) {
        ///todo: Angle fusion using compass filtered angle, gyro cumulative angle and beacon angle
        if (self.initialHeading == -800) {
            if (data_p.getCompassFilteredAngle() != 0) {
                self.gyroHeadingUsed = data_p.getCompassFilteredAngle()//Use the filtered Compass heading
                self.MygyroHeading = 0.0 //Set gyro cumulative angle to zero
                self.UseBeaconHeading = true // Set it to true, it's a control to use beacon heading to correct initial compass heading
            }
        }
        if (self.initialHeading == 800) {
            _ = Int((CurrentTime - iniTime) / 1000)
            var TempCompassAngle:Double
            if (data_p.getCompassFilteredAngle() < 0) {
                //if angle exceeds 180, convert it to -180 ~ 180
                TempCompassAngle = Double(data_p.getCompassFilteredAngle() + 360)
            } else {
                //if angle is in the range of (0, 180), keep it
                TempCompassAngle = Double(data_p.getCompassFilteredAngle())
            }
            if (self.goAhead) {
                self.gyroHeadingUsed = self.gyroHeadingUsed - self.MygyroHeading
                if (self.MygyroHeading != 0) {
                    //    WriteFile.writeTxtToFiles(filePath, fileNameStartTime + "7.5_P20test2_Gyro.txt", "gyroHeadingUsed:" + gyroHeadingUsed + ", MygyroHeading:" + MygyroHeading + ",index:" + index + ", step:" + step + "\n")
                }
                self.MygyroHeading =  0.0
                
            }
        }

        if (self.initialHeading != 800 && self.initialHeading != -800) {//hillday & is a bug
            
            if (self.StrongBeaconHeadingIndex == 1) {
                if (abs(self.initialHeading - self.gyroHeadingUsed) < 30) {
                    /////////need take care compassangle gyroangle range
                    self.gyroHeadingUsed = self.initialHeading//Use beacon heading and gyro cumulative angle to decide end angle
                    self.initialHeading = 800 //Set beacon heading to 800
                    self.MygyroHeading = 0.0 //Set gyro cumulative angle to zero
                    self.UseBeaconHeading = false // Set
                } else {
                    if (self.initialHeading > 270 && self.gyroHeadingUsed < 90) {
                        //if (abs((360.0 - initialHeading) - gyroHeadingUsed) < 30) {
                        if (abs((360.0 - self.initialHeading) + self.gyroHeadingUsed) < 30) {
                            if (data_p.getTurnAnlge() < self.BiasOfHeadingBeaconHeadig) {//BiasOfHeadingBeaconHeadig = 30
                                ///due to the case, when surveyor are in turning, beacon heading occurs
                                self.gyroHeadingUsed = self.initialHeading//Use beacon heading and gyro cumulative angle to decide end angle
                                self.initialHeading = 800 //Set beacon heading to 800
                                self.MygyroHeading = 0.0 //Set gyro cumulative angle to zero
                                self.UseBeaconHeading = false // Set
                            } else {
                                // if surveyor are in turning in color, but at same time, beacon heading occurs
                            }
                        }
                    }
                    if (self.initialHeading < 90 && self.gyroHeadingUsed > 270) {
                        //if (abs((360.0 - gyroHeadingUsed) - initialHeading) < 30) {
                        if (abs((360.0 - self.gyroHeadingUsed) + self.initialHeading) < 30) {
                            if (data_p.getTurnAnlge() < self.BiasOfHeadingBeaconHeadig) {
                                ///due to the case, when surveyor are in turning, beacon heading occurs
                                self.gyroHeadingUsed = self.initialHeading//Use beacon heading and gyro cumulative angle to decide end angle
                                self.initialHeading = 800 //Set beacon heading to 800
                                self.MygyroHeading = 0.0 //Set gyro cumulative angle to zero
                                self.UseBeaconHeading = false // Set
                            } else {
                                // if surveyor are in turning in color, but at same time, beacon heading occurs
                            }
                        }
                    } else {
                        var TempCompassAngle:Double
                        if (data_p.getCompassFilteredAngle() < 0) {
                            //if angle exceeds 180, convert it to -180 ~ 180
                            TempCompassAngle = Double(data_p.getCompassFilteredAngle() + 360)
                        } else {
                            //if angle is in the range of (0, 180), keep it
                            TempCompassAngle = Double(data_p.getCompassFilteredAngle())
                        }
                        let cbb = abs(TempCompassAngle - Double(self.initialHeading))
                        if ( cbb < Double(abs(self.MygyroHeading - self.initialHeading)) && cbb < 40.0) {
                            self.gyroHeadingUsed = self.initialHeading//Use beacon heading and gyro cumulative angle to decide end angle
                            self.initialHeading = 800 //Set beacon heading to 800
                            self.MygyroHeading = 0.0 //Set gyro cumulative angle to zero
                            self.UseBeaconHeading = false // Set
                        } else {
                            
                        }
                    }
                }
                self.StrongBeaconHeadingIndex = 0
            }
            if (self.WeekBeaconHeadingIndex == 1) {
                if (data_p.getTurnAnlge() < self.BiasOfHeadingBeaconHeadig) {
                    //if the big turn occurred in the process 6s ~ 12s before now, do following operations
                    self.gyroHeadingUsed = self.initialHeading//Use beacon heading and gyro cumulative angle to decide end angle
                    self.initialHeading = 800 //Set beacon heading to 800
                    self.MygyroHeading = 0.0 //Set gyro cumulative angle to zero
                    self.UseBeaconHeading = false // Set it to false, it's a control to use beacon heading to correct initial compass heading
                } else {
                }
                self.WeekBeaconHeadingIndex = 0
            }
            if (self.UseBeaconHeading) {
                //if in the initial stage, compass heading has big error with beacon heading, enter into self
                self.gyroHeadingUsed = self.initialHeading // Use beacon heading to correct compass heading
                self.initialHeading = 800//Set beacon heading to 800
                self.MygyroHeading = 0.0 //Set gyro cumulative angle to zero
                self.UseBeaconHeading = false // Set it to false, it's a control to use beacon heading to correct initial compass heading
            } else {
                
            }
            //   initialHeading = 800//Set beacon heading to 800
        }
        
        
        ///todo: end fusion
        ///todo: Convert end used angle to -180 ~ 180 from 0 ~ 360
        if (self.gyroHeadingUsed > 360) {
            //if exceeds 360, minus 360, keep the angle in the range of 0~360
            self.gyroHeadingUsed = self.gyroHeadingUsed - 360
        } else if (self.gyroHeadingUsed < 0) {
            // if the angle is smaller than 0, add 360, keep the angle in the range of 0~360
            self.gyroHeadingUsed = self.gyroHeadingUsed + 360
        }
        
        if (self.gyroHeadingUsed > 180) {
            //if angle exceeds 180, convert it to -180 ~ 180
            distanceHeanding = Double(gyroHeadingUsed - 360)
        } else {
            //if angle is in the range of (0, 180), keep it
            distanceHeanding = Double(gyroHeadingUsed)
        }
        self.stepNow = Double(data_p.getStepNumOwn()) // Get current step number
        self.stepUsed = stepNow - stepPre   // Calculate current used step number
        let distnace_N = calculateDistance(stepUsed, distanceHeanding, Double(stepLong))[0] //Calculate changed distance in north
        
        let distnace_S = calculateDistance(stepUsed, distanceHeanding, Double(stepLong))[1] //Calculate changed distance in east
        
        data_p.setHeading(distanceHeanding) //  Set end used heading
        //todo: adaptive
        if (distnace_N != 0 || distnace_S != 0) {
            let PDRMovedDistance = sqrt(distnace_N * distnace_N + distnace_S * distnace_S)
            self.PDRPrecisionComputed = Algorithm.CalculatePDRPrecision(self.PDRPrecisionComputed, PDRMovedDistance) //Calculate Current PDR precision
            self.PDRTotalDistance = self.PDRTotalDistance + PDRMovedDistance
            self.PDRTotalNE[0] = distnace_N
            self.PDRTotalNE[1] = distnace_S
        }
        //todo: end
        self.allDistance_N = self.allDistance_N + distnace_N // Cumulative distance in north
        self.allDistence_S = self.allDistence_S + distnace_S // Cumulative distance in east
        self.allDistance[0] = self.allDistance_N
        self.allDistance[1] = self.allDistence_S
        self.stepPre = self.stepNow //set now step number to pre-step
    }
    
    /*
     Based on the step num and heading to calcualte the moving distance
     */
    func calculateDistance(_ stepUsed:Double, _ headingUsed:Double, _ stepLong:Double)->[Double] {
        var distanceArray:[Double] = [0.0, 0.0]
        distanceArray[1] = (stepUsed * stepLong * sin(((headingUsed) / 180) * Double.pi))
        distanceArray[0] = (stepUsed * stepLong * cos(((headingUsed) / 180) * Double.pi))
        return distanceArray
    }
    func setBeaconHeadVals(_ initialHeading:Float, _ StrongBeaconHeadingIndex:Double,_ WeekBeaconHeadingIndex:Double){
        self.initialHeading = initialHeading
        self.StrongBeaconHeadingIndex = StrongBeaconHeadingIndex
        self.WeekBeaconHeadingIndex = WeekBeaconHeadingIndex
        self.DisplayedHeading = initialHeading
    }
    
    func PositionByBeacon(_ centerBeacon:Int64, _ RoadWidth:Double, _ velecity:Double) ->[Double]{
        var xy:[Double] = [0, 0] //initial return position
        let POS = BeaconCoordinates.positionFromBeacon(centerBeacon) // get beacon position
        if (POS.latitude != -1) {
            let xy0 = self.algorithm.LatLongToDouble(POS) // convert to double value
            let R = SignalRange.SignalRange(centerBeacon) // get radius
            // get corrected position
            let sqv0 = (RoadWidth / 2.0) * (RoadWidth / 2.0)
            let sqv = Double(R * R) - Double(sqv0) + Double(2.5 * velecity)
            xy[0] = xy0[0] - sqrt(sqv)
            xy[1] = (xy0[1] - RoadWidth / 2) // get corrected position
        }
        return xy
    }
    
    
    func MatchTimeLooKforPosition(_ StoredPosition:[[Double]],_ KEYTimeSize:KeyTimeSize) -> [Double] {
        let latLngPosBeacon = BeaconCoordinates.positionFromBeacon(KEYTimeSize.Key)// Get week beacon coordinates
        var result:[Double] = [0.0, 0.0, 0.0, 0.0]
        _ = 10000000.0
        if (latLngPosBeacon.latitude != -1) {
            let Beaconxy = PositionByBeacon(KEYTimeSize.Key, RoadWith, Velecity) //Corrected beacon position
            let size = StoredPosition.count
            for i in 0..<size-1 {
                let TimePosPre = StoredPosition[i]
                let TimePosNext = StoredPosition[i+1]
                if (Int64(TimePosPre[0]) <= KEYTimeSize.Time && Int64(TimePosNext[0]) >= KEYTimeSize.Time) {
                    // if the time of strong signal point is found between TimePosPre and TimePosNext
                    let RoverX = TimePosPre[1]  //Get related postion of TimePosPre
                    let RoverY = TimePosPre[2]  //Get related postion of TimePosPre
                    let deltaX = Beaconxy[0] - RoverX //Get the correction
                    let deltaY = Beaconxy[1] - RoverY //Get the correction
                    result[0] = deltaX
                    result[1] = deltaY
                    //WriteFile.writeTxtToFiles(filePath, fileNameStartTime + "delta.txt", KEYTimeSize.Key + ",deltaX:" + deltaX + ",deltaY:" + deltaY + "\n")
                    result[2] = TimePosPre[3]//step number，用探测到峰值时的PDR位置对应的步数来计算步长
                    result[3] = Double(KEYTimeSize.Key)//beacon key
                    self.PDRflag = true
                    break
                }
            }
            
        }
        self.stepNumber = result[2]
        self.key = result[3]
        //        WriteFile.writeTxtToFiles(filePath, fileNameStartTime + "stepNumber.txt", result[3] + "," + result[2] + "\n")
        return result
    }
    
    func getGpsPosList()->[LatLng]{
        return self.gpsPosList
    }
    

    
    func OptimizeStepLength(_ minor:Int64, _ stepLength:Float) ->[Float]{
        var length = stepLength
        var result:[Float] = [length, Float(self.deltaXY[2])]
        let lightid = BeaconPositioningAlgorithm.LightID(minor)
        if (minor != 0) {
            let minorID = BeaconPositioningAlgorithm.JugeSingleStrongWeak(minor)
            //BeaconList is the series of all scanned week beacons
            if (self.BeaconList.count == 0) {
                if (minorID == 1) {
                    if (self.deltaXY[2] != 0) {
                        self.BeaconList.append(Double(minor))
                        let strongSignalStepNumber = self.deltaXY[2] // Get step number
                        self.StepListForLength.append(strongSignalStepNumber)
                        self.deltaXY[2] = 0 // clear deltaXY step number
                        self.deltaXY[3] = 0 // clear dettaXY week beacon object
                    }
                }
            }
            if (self.BeaconList.count == 1) {
                //if BeaconList has one week beacon
                if (BeaconPositioningAlgorithm.LightID(Int64(self.BeaconList[0])) != lightid) {
                    //if new beacon is not the existed beacon
                    if (minorID == 1) {
                        // if the beacon is week beacon
                        if (deltaXY[2] != 0) {
                            // if step number is 0
                            self.BeaconList.append(Double(minor)) // add the new beacon to list
                            let strongSignalStepNumber = self.deltaXY[2] // get step number to list
                            self.StepListForLength.append(strongSignalStepNumber) //add step number
                            self.deltaXY[2] = 0 // clear deltaXY step number
                            self.deltaXY[3] = 0 // clear dettaXY week beacon object
                        }
                    }
                } else {
                    self.deltaXY[2] = 0 // clear deltaXY step number
                    self.deltaXY[3] = 0 // clear dettaXY week beacon object
                }
            }
            if (self.BeaconList.count == 2) {
                // if two week beacon existed in list
                if (BeaconPositioningAlgorithm.LightID(Int64(self.BeaconList[1])) != lightid) {
                    // if new beacon is different
                    if (minorID == 1) {
                        if (self.deltaXY[2] != 0) {
                            self.BeaconList.remove(at: 0)// Remove the first one
                            self.BeaconList.append(Double(minor)) // Add new beacon
                            self.StepListForLength.remove(at:0) // Remove the first one
                            let strongSignalStepNumber = self.deltaXY[2] //Add new beacon step number to list
                            self.StepListForLength.append(strongSignalStepNumber)
                            self.deltaXY[2] = 0 // clear deltaXY step number
                            self.deltaXY[3] = 0 // clear dettaXY week beacon object
                        }
                    }
                } else {
                    self.deltaXY[2] = 0// clear deltaXY step number
                    self.deltaXY[3] = 0// clear dettaXY week beacon object
                }
            }
            
            
            if (BeaconList.count >= 1) {
                self.TurnAngleList.append(self.data.getTurnAnlge()) // Once there is one week beacon, record trun angle
                var CalcaulteScale = true // Set bool value to control if calculate scale
                if (BeaconList.count == 2) {
                    //If there are two beacons in list
                    for k in 0..<self.TurnAngleList.count {
                        if (self.TurnAngleList[k] >= self.TurnAngleThreshold) {
                            // Judge there is big turn in the process
                            CalcaulteScale = false
                            // If there is big turn occured, program should not adjust step length
                            self.TurnAngleList.removeAll()
                            // Clear all turn angle list
                        }
                    }
                    if (CalcaulteScale) {
                        //If there is no big turn in the process, do it
                        // Get two beacons' coordinates
                        let POS1 = BeaconCoordinates.positionFromBeacon(Int64(self.BeaconList[0]))
                        let POS2 = BeaconCoordinates.positionFromBeacon(Int64(self.BeaconList[1]))
                        if (POS1.latitude != -1 && POS2.latitude != -1) {
                            //Calculate distance between two beacons
                            let distancePos1Pos2 = Algorithm.Distance(POS1, POS2)
                            //Get the steps
                            let step1 = Float(self.StepListForLength[0])
                            let step2 = Float(self.StepListForLength[1])
                            if (step1 != step2) {
                                //if step is not same, means the surveyor is not static
                                let lengthTemp = length
                                length = Float(distancePos1Pos2) / (step2 - step1) // Adjust step length from beacons
                                if (length > Float(self.MaxBeaconAdjustStepLenghtThreshold) || length < Float(self.MiNBeaconAdjustStepLenghtThreshold)) {
                                    length = lengthTemp //if adjusted step length exceeds the max or min thresholds, adjustment should not be used
                                }
                                self.TurnAngleList.removeAll()
                                self.BeaconList.remove(at:0)
                                self.StepListForLength.remove(at:0)
                            }
                        }
                    }
                    
                }
            }
            
        }
        result[0] = length
        return result
    }
    
    func CalculateGyroMax(_ CurrentTime_p:Int64, _ axisZAngle:Float)->Double {
        var Max:Float = 0.0
        var DeltaT:Int64
        if (self.CountTime == 0) {
            self.StartTime = CurrentTime_p// get the start time in the first time
            self.CountTime += 1
        }
        DeltaT = CurrentTime_p - self.StartTime // calculate the time bias from start time
        if (DeltaT < 100) {
            self.Angle = self.Angle + axisZAngle
        } else {
            if (self.TimeGyroAngle.count < 60) {
                self.TimeGyroAngle.append(Angle) // Record 6 values
                self.StartTime = CurrentTime_p
            } else {
                self.TimeGyroAngle.append(Angle)
                self.TimeGyroAngle.remove(at:0) //Remove the first one value
                self.StartTime = CurrentTime_p
            }
        }
        if (self.TimeGyroAngle.count == 60) {
            var arrayList = [Float]()
            for i in 0..<30{
                arrayList.append(abs(self.TimeGyroAngle[30 + i] - self.TimeGyroAngle[i])) // Calculate the bias of 3 and 0
            }
            ///Get max value of the list
            for i in 0..<29 {
                let a = abs(arrayList[i])
                if (i == 0) {
                    Max = a
                } else {
                    if (Max < a) {
                        Max = a
                    } else {
                        
                    }
                }
            }
        } else {
        }
        
        return Double(Max)
    }

    
    
    /*
     Calculate the step number based on the acc values
     */
    func stepCounting(_ lp:Float)->Double {
        self.accNow = Double(lp)
        self.stepNum = 0
    
        if (self.accNow > self.accPre) {
            if ((self.accPre < -0.7) && (self.numDown >= 3) && (self.peakPre > 0.7)) {
                if (self.numDown < Int(self.UPDATE_FREQUENCY + 1.0)) {
                    self.stepNum = 0.5
                }
                self.numDown = 0
                self.numUp = 0
                self.peakPre = self.accPre // Here peakPre is low peak
            } else if (self.accPre < -0.7) {
                if (self.accPre < self.peakPre) {
                    self.peakPre = self.accPre
                }
            } else if (self.accPre > -0.7) {
                self.numDown = self.numDown + 1
            }
            self.numUp = self.numUp + 1
            self.accPre = self.accNow
        } else if (self.accNow < self.accPre) {
            if ((self.accPre > 0.7) && (self.numUp >= 3) && (self.peakPre < -0.7)) {
                if (self.numUp < Int(self.UPDATE_FREQUENCY + 1)) {
                    self.stepNum = 0.5
                }
                self.numUp = 0
                self.numDown = 0
                self.peakPre = self.accPre
            } else if (self.accPre > 0.7) {
                if (self.accPre > self.peakPre) {
                    self.peakPre = self.accPre
                }
            } else if (self.accPre < 0.7) {
                self.numUp = self.numUp + 1
            }
            self.numDown = self.numDown + 1
            self.accPre = self.accNow
        }
        self.step = self.step + self.stepNum
        self.counter += 1
        
        return self.step
    }
    
    /*
     Basic Set and Get functions
     */
    func setStrongBeaconPosXY(_ XY:[Double]){
        self.StrongBeaconPosXY = XY
    }
    
    func setKeyTimeSize(_ keyTimeSize:KeyTimeSize){
        self.keyTimeSize = keyTimeSize
    }
    func setBeaconUsed(_ ibc:iBeacon){
        self.BeaconUsed = ibc
    }
    func setBeaconUsedRecord(_ flag:Bool){
        self.BeaconUsedRecord = flag
    }
    
    func getAlgorithm()->Algorithm{
        return self.algorithm
    }
    
    func  getLp()->Float{
        return lp
    }
    
    func setLp(_ lp:Float) {
        self.lp = lp
    }
    
    func getStep()->Double {
        return self.step
    }
    
    func setStep(_ step:Double) {
        self.step = step
    }
    
    func getMagnHeading()->Double{
        return self.magnHeading
    }
    
    func setMagnHeading(_ magnHeading:Double){
        self.magnHeading = magnHeading
    }
    
    func getMygyroHeading()->Float {
        return MygyroHeading
    }
    
    func setMygyroHeading(_ mygyroHeading:Float) {
        MygyroHeading = mygyroHeading
    }
    
    func setUserHeight(_ h:String){
        self.userHeight = h
    }
    
    func getPositionNow()->LatLng{
        return self.positionNow
    }
    
    func getCorrectedPos()->LatLng{
        return  self.CorrectedPos
    }
    
    func getKalmanFiterPos()->LatLng{
        return self.KalmanFiterPos
    }
    
    func getAllBeaconMarker()->[LatLng]{
        return self.allBeaconMarker
    }
    
    func getDisplayedHeading()->Double{
        return Double(self.DisplayedHeading)
    }
    
    func getDistanceHeanding()->Double{
        return self.distanceHeanding
    }
    
    func getCurrentTime()->Int64{
        return self.CurrentTime
    }
    
    func getmValues() ->[Float]{
        return mValues
    }
    
    func setmValues(_ mValues:[Float]) {
        self.mValues = mValues
    }
    
    func getmMatrix() ->[Float]{
        return mMatrix
    }
    
    func setmMatrix(_ mMatrix:[Float]) {
        self.mMatrix = mMatrix
    }
    
}


class SignalRange {
    static var weekBeaconRange:Float = 3 // use for float SignalRange(int xbeacon)
    static var middleBeaconRange:Float = 5 // use for float SignalRange(int xbeacon)
    static var strongBeaconRange:Float = 10 // use for float SignalRange(int xbeacon)
    
    static func SignalRange(_ xbeacon:Int64)->Float {
        var result:Float = 0.0
        let beaconminor = BeaconPositioningAlgorithm.JugeSingleStrongWeak(xbeacon)
        if (beaconminor == 1) {
            result = weekBeaconRange
        }
        if (beaconminor == 2) {
            result = strongBeaconRange
            //                result = middleBeaconRange
        }
        if (beaconminor == 3) {
            result = strongBeaconRange
        }
        return result
    }
}

class KalmanCalculate{
    static var Q_angle:Float = 1.0//0.001 // 角度数据置信度
    static var Q_gyro:Float = 3.0 //0.005 // 角速度数据置信度
    static var R_angle:Float = 1000.0 //0.5 // 方差噪声
    static var x_bias:Float = 0.0 //陀螺仪的偏差
    static var rate:Float = 0.0 //去除偏差后的角速度
    static var P_00:Float = 0.0
    static var P_01:Float = 0.0
    static var P_10:Float = 0.0
    static var P_11:Float = 0.0 //过程协方差矩阵P[2][2]
    static var angle_err:Float = 0.0 //角度偏量
    static var S:Float = 0.0 //计算的过程量
    static var K_0:Float = 0.0 //含有卡尔曼增益的另外一个函数，用于计算最优估计值
    static var K_1:Float = 0.0 //含有卡尔曼增益的函数，用于计算最优估计值的偏差
    static var x_angle:Float = 0.0
    static var x_angle_withKF:Float = 0.0
    //    static public float x_angle_withoutKF = 0.0f
    static var set_x_angle:Bool = true
    
    static func getX_angle() ->Float {
        return x_angle
    }
    
    static func setX_angle(_ x:Float) {
        x_angle = x
    }
    
    //https://robottini.altervista.org/kalman-filter-vs-complementary-filter
    static func kalmanCalculate(_ newAngle:Float, _ IntegrationAngle:Float, _ looptime:Float)->Float {//newAngle = degree,IntegrationAngle = gyroanglechange
        
        let dt = looptime //卡尔曼滤波采样频率???应该是采样时间
        
        if (dt != 0) {
            if (set_x_angle) {
                x_angle = newAngle
                set_x_angle = false
            }
            let newRate = -IntegrationAngle / dt
            x_angle += dt * (newRate - x_bias) //角速度积分得出角度，先验估计
            
            P_00 += -dt * (P_10 + P_01) + Q_angle * dt //先计算过程协方差的微分矩阵，再对dt积分
            
            P_01 += -dt * P_11
            
            P_10 += -dt * P_11
            
            P_11 += +Q_gyro * dt //先验估计误差协方差
            
            angle_err = newAngle - x_angle
            if (angle_err > 180) {
                angle_err = angle_err - 360
            }
            if (angle_err < -180) {
                angle_err = angle_err + 360
            }
            S = P_00 + R_angle //计算卡尔曼增益
            
            K_0 = P_00 / S //计算角度偏差
            
            K_1 = P_10 / S
            
            x_angle += K_0 * angle_err //给出角度最优估计值
            
            x_bias += K_1 * angle_err //更新最优估计值误差
            
            P_00 -= K_0 * P_00 //更新协方差矩阵
            
            P_01 -= K_0 * P_01
            
            P_10 -= K_1 * P_00
            
            P_11 -= K_1 * P_01
        } else {
            x_angle = newAngle
        }
        
        return x_angle
        
    } //To get the answer, you have to set 3 parameters: Q_angle, R_angle,R_gyro.
    ///Detect
    
    
}

