//
//  BeaconScanService.swift
//  navigation
//
//  Created by 郑旭 on 2021/2/2.
//

import Foundation


class BeaconScanService {
    var curBeacon:iBeacon?
    var StrongHeading:Double = 800.0
    var WeekHeading:Double = 800.00
    var Turn:Double = 0.0
    var NowUsedAngle:Double = 0.0
    var step:Double = 0.0
    var CompassAngle:Float = 0.0
    var n:Int = 0
    var StrongHeadigStartTime:Int64 = 0
    var heading:Double = 800.0
    var preHeading:Double = 0.0
    var beaconAverageValues:[Int64:[TimeAverageRSSI]]
    var tempbeaconAverageValues:[Int64:[TimeAverageRSSI]]
    var BeaconEndInfo:[Int64:[TimeAverageRSSI]]
    var StrongBeacon:[Int64:[TimeAverageRSSI]]
    var NonZeroStrongMap:[Int64:[TimeAverageRSSI]]
    var minorSlope:[Int64:Double]
    var weakIndicatorMap:[Int64:[Double]]
    var StrongBeaconKeyIndicator:[Int64:Double]
    var PreIndicatorHashmap:[Int64:Int64]
    var count:Int = 0
    var PreStrongHeading:Double = 0.0
    var stepChange:Double = 0.0
    var RecordStartTime:Int64 = 0
    var returnNowGetTime:Int64 = 0
    var StoreScannedBeaconWeak:[Int64:[TimeAverageRSSI]]
    var StoreScannedBeaconStrong:[Int64:[TimeAverageRSSI]]
    var StoreTempMaxRSSIofBeacon:[Int64:TimeAverageRSSI]
    var minorNoLongerStore:[Int64]?
    var findPeak:Bool = false
    var ResultKeyTimeSize:KeyTimeSize?
    var ReceiveValueStartTime:Int64 = 0
    var WeekIndex:Bool = false
    var StrongIndex:Bool = false
    var JudgeNowUsedAngleToWrong:Bool = false
    //////////Thresthold Settings
    var WeekBeaconRSSIRemoveStrongBeacon:Double = -86.0 // Week beacon filter threshold
    var BeaconSignalDetectWindow:Int64 = 3000 // Week beacon signal detection time window
    var MinWeakBeaconRSSINumber:Int = 2 //Min detected week beacon number （for iOS, there only 1 sample for 1 second）
//    var StrongBeaconStrongestRSSINumberThreshold:Int = 20
    var BeaconNumber:Int = 10
    var StrongBeaconNumber:Int = 10
    var WeekBeaconNumber:Int = 10// Week beacon number threshold for building indicator map
    var NonZeroStrongRSSINumber:Int = 6
    var StrongBeaconSlopeIndexPlus:Double = 0.4  // strong beacon slope threshold max value
    var StrongBeaconSlopeIndexMius:Double = -0.4 // strong beacon slope threshold min value
    var WeekBeaconRSSINumberForIndex:Int = 10    // Week beacon rssi series size threshold for index calculation
    var TurnAngleThreshold:Double = 60           // Surveyor turn angle threshold
    var StartTime:Int64 = 0
    var fileName:String = ""
    var indexNow:Int = 0
    var HeadingIndex:[Double] = []
    var headingFile:URL!
    
    init(_ cb: iBeacon, _ start:Int64, _ current: Int){
        self.beaconAverageValues = [:]
        self.tempbeaconAverageValues = [:]
        self.BeaconEndInfo = [:]
        self.StrongBeacon = [:]
        self.NonZeroStrongMap = [:]
        self.StoreScannedBeaconWeak = [:]
        self.StoreScannedBeaconStrong = [:]
        self.StoreTempMaxRSSIofBeacon = [:]
        self.minorSlope = [Int64:Double]()
        self.weakIndicatorMap = [Int64:[Double]]()
        self.StrongBeaconKeyIndicator = [Int64:Double]()
        self.PreIndicatorHashmap = [Int64:Int64]()
        self.minorNoLongerStore = [Int64]()
        self.curBeacon = cb
        self.StartTime = start
        self.indexNow = current
        self.headingFile = FileUtils.urlFile("headingFile")!
    }
    
    func ClearWeekBeacon() {
        self.beaconAverageValues.removeAll()
        self.weakIndicatorMap.removeAll()
    }
    
    func ClearStrongBeacon() {
        self.StrongBeacon.removeAll()
        self.NonZeroStrongMap.removeAll()
        self.StrongBeaconKeyIndicator.removeAll()
        self.minorSlope.removeAll()
    }
    
    /*
     Get average rssi value of each beacon for every second
     This function is not useful for the iOS program beacuse the update frequency is 1Hz
     Warning: a lot zero value -> fixed
     */
    func updateAverageValues(_ beaconScanStartTime:Int64) {
        if (self.beaconAverageValues.count == 0) {
            for (k,v) in self.tempbeaconAverageValues {
                let rssiUsed = calculateAverage(v)
                UsedputBeaconAverageValues(k, beaconScanStartTime, rssiUsed)
            }
        } else {
            if (self.tempbeaconAverageValues.count == 0) {
                let beaconAverageValuesClone = beaconAverageValues
                for (k,_) in  beaconAverageValuesClone {
                    let rssiUsed:Double = 0.0
                    UsedputBeaconAverageValues(k, beaconScanStartTime, rssiUsed)
                }
            } else {
                var AverageValues1:[Int64:[TimeAverageRSSI]] = [:]
                var AverageValues2:[Int64:[TimeAverageRSSI]] = [:]
                var AverageValues3:[Int64:[TimeAverageRSSI]] = [:]
                for (k,v) in self.beaconAverageValues {
                    if let _ = self.tempbeaconAverageValues[k] {
                        AverageValues2[k] = tempbeaconAverageValues[k]
                    } else {
                        AverageValues3[k] = v
                    }
                }
                
                for (k,v) in self.tempbeaconAverageValues{
                    if let _ = beaconAverageValues[k] {
                    } else {
                        AverageValues1[k] = v
                        
                    }
                }
                for (k,v) in AverageValues1 {
                    // Temp have, average not have
                    let rssiUsed = calculateAverage(v)
                    UsedputBeaconAverageValues(k, beaconScanStartTime, rssiUsed)
                }
                for (k,v) in AverageValues2 {
                    // Temp have, average have
                    let rssiUsed = calculateAverage(v)
                    UsedputBeaconAverageValues(k, beaconScanStartTime, rssiUsed)
                }
                for (k,_) in AverageValues3 {
                    //Temp not have, average has
                    let rssiUsed = 0.0
                    UsedputBeaconAverageValues(k, beaconScanStartTime, rssiUsed)
                    
                }
            }
        }
        self.tempbeaconAverageValues.removeAll()
    }
    
    /*
     Not meaningful for iOS program, because the count is always equal to 1
     */
    func calculateAverage(_ list:[TimeAverageRSSI])->Double {
        let count = list.count
        var sumValue:Double = 0.0
        let RSSIlist = list
        for i in 0..<count {
            let Value = RSSIlist[i].RSSI
            sumValue += Value
        }
        
        return Algorithm.formatDouble(sumValue / Double(count))
    }
    
    /*
     “beaconAverageValues” is the input of the algorithm
     */
    func UsedputBeaconAverageValues(_ key:Int64, _ beaconScanStartTime:Int64, _ rssi:Double) {//和下面函数的区别在于这里的RSSI是平均值
        var list:[TimeAverageRSSI] = []
        var timeAverageRSSI:TimeAverageRSSI = TimeAverageRSSI()
        timeAverageRSSI.time = beaconScanStartTime
        timeAverageRSSI.RSSI = rssi
        if let _ = self.beaconAverageValues[key] {
            list = self.beaconAverageValues[key]!
            list.append(timeAverageRSSI)
        } else {
            list.append(timeAverageRSSI)
        }
        self.beaconAverageValues[key] =  list //update beaconAverageValue series
        let tempSize = beaconAverageValues[key]!.count
        if (tempSize > BeaconNumber) {//list里最多存15个平均RSSI值
            //Store average rssi numbers
            self.beaconAverageValues[key]!.remove(at:0)
        } else {
            // nothing
        }
    }
    
    /*
     Put all scaned beacons to "tempbeaconAverageValues"
     */
    func UsedputtempBeaconAverageValues(_ key:Int64, _ beaconScanStartTime:Int64, _ rssi:Double) {
        var list:[TimeAverageRSSI] = []
        var timeAverageRSSI:TimeAverageRSSI = TimeAverageRSSI()
        timeAverageRSSI.time = beaconScanStartTime
        timeAverageRSSI.RSSI = rssi
        if let _ = self.tempbeaconAverageValues[key] {
            list = self.tempbeaconAverageValues[key]!
            list.append(timeAverageRSSI)
        } else {
            list.append(timeAverageRSSI)
        }
        self.tempbeaconAverageValues[key] = list
    }
    
    /*
     Filter Strong beacon info from "beaconAverageValues" and store to "StrongBeacon"
     */
    func BuildStrongBeaconMap() {
        for (k,v) in self.beaconAverageValues {
            if (BeaconPositioningAlgorithm.JugeSingleStrongWeak(k) == 2 || BeaconPositioningAlgorithm.JugeSingleStrongWeak(k) == 3) {
                self.StrongBeacon[k] = v
            }
        }
    }
    
    func UpdateBeaconValues(_ BeaconMap: inout [Int64:[TimeAverageRSSI]], _ key:Int64, _ Time:Int64, _ rssi:Double, _ remove:Bool) {
        var list:[TimeAverageRSSI] = []
        var timeAverageRSSI = TimeAverageRSSI()
        timeAverageRSSI.time = Time
        timeAverageRSSI.RSSI = rssi
        if let _ = BeaconMap[key] {
            list = BeaconMap[key]!
            list.append(timeAverageRSSI)
        } else {
            list.append(timeAverageRSSI)
        }
        BeaconMap[key] = list
        if (remove) {
            let tempSize = BeaconMap[key]!.count
            if (tempSize > StrongBeaconNumber) {
                BeaconMap[key]!.remove(at:0)
            } else {
                // nothing
            }
        }
    }
    
    /*
     Filter non zero value from strong beacon, here zero values are from sampling missing
     */
    func GetNonZeroMap(_ beaconMap:[Int64:[TimeAverageRSSI]]) {
        self.NonZeroStrongMap.removeAll()
        for (k,v) in beaconMap {
            let size = v.count
            for i in 0..<size {
                if (v[i].RSSI != 0) {
                    let rssi = v[i].RSSI
                    let time = v[i].time
                    let Key = k
                    UpdateBeaconValues(&self.NonZeroStrongMap, Key, time, rssi, true)
                }
            }
        }
        
    }
    
    /*
     Calcualte Rssi change slope of Strong Beacon
     */
    func CalculateSlope(_ NonZeroStrongMap:[Int64:[TimeAverageRSSI]], _ rawbeaconMap:[Int64:[TimeAverageRSSI]]) {
        for (k,v) in rawbeaconMap {
            
            if (v.count == self.StrongBeaconNumber) {
                if (self.NonZeroStrongMap[k] != nil && self.NonZeroStrongMap[k]!.count >= self.NonZeroStrongRSSINumber) {//把RSSI=0的值去掉NonZeroStrongRSSINumber = 8
                    var rssi:[Double] = []
                    var time:[Double] = []
                    let list = NonZeroStrongMap[k]
                    let size = list!.count
                    for i in 0..<size {
                        rssi.append(list![i].RSSI)
                        let t_time = Double(Double((list![i].time - list![0].time)) / 1000.0)
                        time.append(t_time) //time difference, convert to x
                    }
                    
                    //todo: exclude outliers
                    var rssi_sum:Double = 0.0
                    var rssi_ave:Double = 0.0
                    var rssi_sig2:Double = 0.0
                    var rssi_sig:Double = 0.0
                    for i in 0..<size {
                        rssi_sum = rssi_sum + rssi[i]
                    }
                    rssi_ave = rssi_sum / Double(size)//求均值
                    for i in 0..<size {
                        rssi_sig2 = rssi_sig2 + pow((rssi[i] - rssi_ave), 2)
                    }
                    rssi_sig = sqrt(rssi_sig2)//求方差
                    
                    for i in stride(from: size - 1, through: 0, by: -1){
                        if (rssi[i] > (rssi_ave - 1.96 * rssi_sig / (sqrt(Double(size)))) && rssi[i] < (rssi_ave + 1.96 * rssi_sig / (sqrt(Double(size))))) {
                            
                        } else {
                            // int a = 0
                            rssi.remove(at:i)
                            time.remove(at:i)
                        }
                    }
                    
                    let result = Algorithm.Slope(time, rssi)
                    minorSlope[k] = result
                } else {
                    
                }
            } else {
            }
        }
        
    }
    
    /*
     Calculate the Indicator of Week Beacon
     */
    func CalculateWeekBeaconIndicator() {
        
        BeaconEndInfo = beaconAverageValues
        
        //Todo: Use record all scanned beacons to calculate heading
        if (BeaconEndInfo.count > 0) {
            for (k,v) in BeaconEndInfo {
                if (v.count != 0) {
                    var CloneTimeRSSI:[TimeAverageRSSI] = []
                    var PreIndicator:Int64 = 0
                    var NowIndicator:Int64 = 0
                    if (PreIndicatorHashmap.count > 0 && PreIndicatorHashmap[k] != nil) {
                        PreIndicator = PreIndicatorHashmap[k]!
                    } else {
                        PreIndicator = 0
                    }
                    CloneTimeRSSI = BeaconEndInfo[k]!
                    // When the number less than 15, the operation only for week beacon
                    
                    if (v.count > 0 && v.count < WeekBeaconNumber) {
                        if (BeaconPositioningAlgorithm.JugeSingleStrongWeak(k) == 1) {
                            let size = CloneTimeRSSI.count
                            var RSSI:[Double] = []
                            for i in 0..<size {
                                RSSI.append(CloneTimeRSSI[i].RSSI)
                            }
                            //NowIndicator获得现在weak beacon的indicator值，0/1/-1
                            NowIndicator = CalculateIndicator.WeekIndicator(PreIndicator, RSSI, WeekBeaconRSSINumberForIndex) // Construct week indicator map by week beacon  //WeekBeaconRSSINumberForIndex = 15
                            /*let time = iBeaconClass.getNowMillis()
                             let recordIndex = (time - StartTime) / 1000
                             indictorList.add(time + "," + vo.getKey() + "," + String.valueOf(NowIndicator) + "," + recordIndex)*/
                            
                        } else {
                            // nothing
                        }
                    } else if (v.count == WeekBeaconNumber) {
                        //todo: judge if the beacon is week, and then use the received 15 RSSI values to get indicator
                        if (BeaconPositioningAlgorithm.JugeSingleStrongWeak(k) == 1) {
                            let size = CloneTimeRSSI.count//size==15
                            var RSSI:[Double] = []
                            for i in 0..<size {
                                RSSI.append(CloneTimeRSSI[i].RSSI)
                            }
                            NowIndicator = CalculateIndicator.WeekIndicator(PreIndicator, RSSI, WeekBeaconRSSINumberForIndex)
                            /*long time = System.currentTimeMillis()
                             long recordIndex = (time - StartTime) / 1000
                             //todo write 14
                             indictorList.add(time + "," + vo.getKey() + "," + String.valueOf(NowIndicator) + "," + recordIndex)*/
                        }
                        //todo: judge if the beacon is middle or strong, and then use the received 15 RSSI values to get indicator
                        else {
                        }
                        //add by Li Start
                    } else if (v.count == 0) {
                        //LogFF.i("Beacon signal list no value")
                    } else {
                        //LogFF.i("Beacon signal list more than 15")
                    }
                    //add by Li End
                    
                    //todo:add Time, PreIndicator, NowIndicator,X, Y for each beacon in a HashMap:IndicatorMap, the key is beacon ID
                    if (BeaconPositioningAlgorithm.JugeSingleStrongWeak(k) == 1) {
                        var TimeIndicatorArrayList:[Double] = []
                        TimeIndicatorArrayList.append(Double(iBeaconClass.getNowMillis()))
                        TimeIndicatorArrayList.append(Double(PreIndicator))
                        TimeIndicatorArrayList.append(Double(NowIndicator))
                        //  Log.w("IndicatorMap", "" + vo.getKey() + "," + NowIndicator)
                        weakIndicatorMap[k] = TimeIndicatorArrayList
                        //todo:set pre-Indicator value
                        PreIndicatorHashmap[k] =  NowIndicator
                        //todo: clear the current device's 15 RSSI value, ready for next device
                    }
                }
            }
        }
    }
    
    func OutputStrongBeaconHeading() {
        if (PreStrongHeading != StrongHeading) {
            n = 0 // first time appear of the this heading
        }
        if (n == 0) {
            StrongHeadigStartTime = Int64(self.indexNow) //get this heading first appear time
            heading = StrongHeading // set to heading
            StrongIndex = true
            n += 1
            PreStrongHeading = StrongHeading //set current strong heading to previous strong heading
            /*writeFile.writeTxtToFilesWithEnter(filePath, fileName + "StrongBeaconUpdateDirection.txt", "StrongBeacon," + StrongHeading + ",n," + n + ",Index," + indexNow + "\n")*/
        } else {
            if (indexNow >= StrongHeadigStartTime) {
                StrongHeadigStartTime = Int64(indexNow) // reset start time
                heading = StrongHeading // give the strong heading to heading
                StrongIndex = true
                PreStrongHeading = StrongHeading // give current strong heading to previous value
                n += 1
                /*writeFile.writeTxtToFilesWithEnter(filePath, fileName + "StrongBeaconUpdateDirection.txt", "StrongBeacon," + StrongHeading + ",n," + n + ",Index," + indexNow + "\n")*/
            } else if (indexNow < StrongHeadigStartTime) {//不会执行到！！！！
                /*writeFile.writeTxtToFilesWithEnter(filePath, fileName + "StrongBeaconUpdateDirection.txt", "StrongBeacon," + StrongHeading + ",n," + n + ",Index," + indexNow + "\n")*/
            }
        }
    }
    
    // Test codes start *******************************************************************
    
    func recordScanningData(_ heading: Double, _ index: String){
        var wsContent = [String]()
        wsContent.append(String(heading))
        wsContent.append(index)
        FileUtils.writeStrings(self.headingFile, wsContent)
    }
    // Test codes end *********************************************************************
    func MergeHeadingANDClearData() {
        if (weakIndicatorMap.count >= 2) {//至少存储了两个weak beacon的信息
            let calculateWeekBeaconHeading = CalculateWeekBeaconHeading()
            WeekHeading = calculateWeekBeaconHeading.CalculateHeadingByIndicator(StartTime, fileName, weakIndicatorMap)
            recordScanningData(WeekHeading, ";  from Weak Beacon")
        }
        if (StrongBeaconKeyIndicator.count >= 2) {
            let calculateStrongBeaconHeading = CalculateStrongBeaconHeading()
            StrongHeading = calculateStrongBeaconHeading.MergeIndicatorToHeading(StartTime, fileName, StrongBeaconKeyIndicator)
            recordScanningData(StrongHeading, ";  from Strong Beacon")
        }
//        let WeekHeadingRecord = WeekHeading
        if (WeekHeading != 800) {
            heading = WeekHeading
            /*String outPutString = heading + "strongHeading," + StrongHeading + ",WeekHeading," + WeekHeadingRecord + ",Time," + indexNow + "\n"
             writeFile.writeTxtToFilesWithEnter(filePath, fileName + "EndHeading.txt", outPutString)*/
            WeekHeading = 800
            ClearStrongBeacon()
            ClearWeekBeacon()
            StrongHeading = 800
            WeekIndex = true
        } else {
            if (StrongHeading != 800) {
                OutputStrongBeaconHeading()
                /*String outPutString = heading + "strongHeading," + StrongHeading + ",WeekHeading," + WeekHeadingRecord + ",Time," + indexNow + "\n"
                 writeFile.writeTxtToFilesWithEnter(filePath, fileName + "EndHeading.txt", outPutString)*/
                StrongHeading = 800
                if (BeaconPositioningAlgorithm.JugeSingleStrongWeak(curBeacon!.minor) == 1) {//once enter weak beacon area, begin to clear strong beacon
                    ClearStrongBeacon() // clear raw strong data, invioid to construct same strong heading again
                }
                
            } else {
            }
        }
        if (Turn >= TurnAngleThreshold) {//60
            //if turn appeared
            ClearStrongBeacon() // clear all raw of constructing strong beacon heading data series
            ClearWeekBeacon()  // clear all raw of constructing week beacon heading data series
            Turn = 0
            n = 100// Turn occurred, for test
            heading = 800//set heading to 800, once big turn occured
            WeekIndex = false
            StrongIndex = false
        }
    }
    
    func JugeIFOutputHeading() {
        if (heading != 800) {
            if (NowUsedAngle < 0) {
                NowUsedAngle = NowUsedAngle + 360
            }
            var DeltaAngleBias:Double = 0.0
            if (NowUsedAngle > 270 && heading < 90) {
                //DeltaAngleBias=abs((360.0-NowUsedAngle)-heading)
                DeltaAngleBias = abs((360.0 - NowUsedAngle) + heading)
            } else if (NowUsedAngle < 90 && heading > 270) {
                //DeltaAngleBias = abs((360.0 - heading) - NowUsedAngle)
                DeltaAngleBias = abs((360.0 - heading) + NowUsedAngle)
            } else {
                DeltaAngleBias = abs(NowUsedAngle - heading)
            }
            
            if (WeekIndex) {//如果NowUsedAngle給的方向與weak beacon相反，就認爲NowUsedAngle是錯的
                if (DeltaAngleBias > 60) {
                    if (abs(NowUsedAngle - heading) > 90 && abs(Double(CompassAngle) - heading) < 60) {
                        
                    } else {
                        /*WriteFile.writeTxtToFiles(filePath, fileName + "RemovedHeading.txt", "Heading," + heading + ",CellPhoneHeading," + NowUsedAngle + "\n")*/
                        heading = 800
                        ClearStrongBeacon()
                        WeekIndex = false
                        StrongIndex = false
                    }
                }
            }
            if (StrongIndex) {
                if (DeltaAngleBias > 60) {
                    if (abs(NowUsedAngle - heading) > 90 && abs(Double(CompassAngle) - heading) < 40) {
                        if (preHeading != heading) {//判断是否和前一次的heading一致(通过两次判断才确定)
                            JudgeNowUsedAngleToWrong = false
                            preHeading = heading
                        }
                        if (JudgeNowUsedAngleToWrong) {
                            
                        } else {
                            /*WriteFile.writeTxtToFiles(filePath, fileName + "RemovedHeading.txt", "Heading," + heading + ",CellPhoneHeading," + NowUsedAngle + "\n")*/
                            JudgeNowUsedAngleToWrong = true
                            heading = 800
                            ClearStrongBeacon()
                            WeekIndex = false
                            StrongIndex = false
                        }
                    } else {
                        ////filter the error heading, in opposite direction
                        /*WriteFile.writeTxtToFiles(filePath, fileName + "RemovedHeading.txt", "Heading," + heading + ",CellPhoneHeading," + NowUsedAngle + "\n")*/
                        JudgeNowUsedAngleToWrong = false
                        heading = 800
                        ClearStrongBeacon()
                        WeekIndex = false
                        StrongIndex = false
                    }
                }
            }
        }
    }
//    var foronce: Bool = true
    func SendHeadingToActivity() {
        JugeIFOutputHeading()/// Judge if beacon heading is the pedestrian heading by compass heading
        
        if (heading != 800) {
            /*WriteFile.writeTxtToFiles(filePath, fileName + "HeadingService.txt", String.valueOf(heading) + ",index," + indexNow + "\n")*/
            var StrongIndexValue:Double = 0.0
            var WeekIndexValue:Double = 0.0
            if (StrongIndex) {
                StrongIndexValue = 1.0
            } else {
                StrongIndexValue = 0.0
            }
            if (WeekIndex) {
                WeekIndexValue = 1.0
            } else {
                WeekIndexValue = 0.0
            }
            self.HeadingIndex = [0.0,0.0,0.0]
            self.HeadingIndex[0] = heading
            self.HeadingIndex[1] = StrongIndexValue
            self.HeadingIndex[2] = WeekIndexValue
            heading = 800
            WeekIndex = false
            StrongIndex = false
        }
    }
    
    // Get the peak of the RSSI series if the beacon is weak Beacon
    func StoreSignalPeakDetection(_ scannedBeacon:iBeacon, _ NowTime:Int64) {
        if (BeaconPositioningAlgorithm.JugeSingleStrongWeak(scannedBeacon.minor) == 1) {//1 is weak beacon; 2 is strong beacon
            if (!(minorNoLongerStore!.contains(scannedBeacon.minor))) {
                // When "scannedBeacon" is weak beacon and it not in "minorNoLongerStore", it will be added to "StoreScannedBeacon"
                UpdateExistedBeaconSeries(scannedBeacon, NowTime, &StoreScannedBeaconWeak)
                for (k,v) in StoreScannedBeaconWeak {
                    var list:[TimeAverageRSSI] = []
                    // Only when the info is in "BeaconSignalDetectWindow", they are stored to the "StoreScannedBeacon"
                    for i in 0..<v.count {
                        if (NowTime - v[i].time <= BeaconSignalDetectWindow) {
                            list.append(v[i])
                        }
                    }
                    StoreScannedBeaconWeak[k] = list
                }
                // When the recorded number is larger than "MinWeakBeaconRSSINumber", store the max rssi of each weak beacon to "StoreTempMaxRSSIofBeacon"
                for (k,v) in StoreScannedBeaconWeak {
                    if (v.count >= MinWeakBeaconRSSINumber) {//MinWeakBeaconRSSINumber = 3: Make sure every second have recorded the weak beacon
                        let timeAverageRSSIResult = GetDatafromExistedBeaconSeriesForWeek(k, StoreScannedBeaconWeak)///actually its the max rssi
                        if let _ = StoreTempMaxRSSIofBeacon[k] {
                            if (timeAverageRSSIResult.RSSI > WeekBeaconRSSIRemoveStrongBeacon && timeAverageRSSIResult.RSSI >= StoreTempMaxRSSIofBeacon[k]!.RSSI) {
                                StoreTempMaxRSSIofBeacon[k] = timeAverageRSSIResult
                            }
                        } else {
                            if (timeAverageRSSIResult.RSSI > WeekBeaconRSSIRemoveStrongBeacon) {
                                StoreTempMaxRSSIofBeacon[k]  = timeAverageRSSIResult
                            }
                        }
                    }
                }
            }
        }else if (BeaconPositioningAlgorithm.JugeSingleStrongWeak(scannedBeacon.minor) == 2){
            UpdateExistedBeaconSeries(scannedBeacon, NowTime, &StoreScannedBeaconStrong)
            for (k,v) in StoreScannedBeaconStrong {
                var list:[TimeAverageRSSI] = []
                // Only when the info is in "BeaconSignalDetectWindow", they are stored to the "StoreScannedBeacon"
                for i in 0..<v.count {
                    if (NowTime - v[i].time <= BeaconSignalDetectWindow) {
                        list.append(v[i])
                    }
                }
                StoreScannedBeaconStrong[k] = list
            }
            
        }else{
        print("Warning: index is not correct!!")
        }
    }
    /*
     1.Using 5 seconds to make sure the peak is true
     2.Using Weak beacon for the localization
     */
    func SignalPeak(_ NowTime:Int64) {
        var keyTimeSize = KeyTimeSize()
        var rssiMax:Double = -200.0
        var keyValue:Int64 = 0
        for (k,_) in StoreScannedBeaconWeak {
            if (StoreTempMaxRSSIofBeacon.count != 0) {
                if let _ = StoreTempMaxRSSIofBeacon[k]{
                    if (NowTime - StoreTempMaxRSSIofBeacon[k]!.time > 5000) {
                        let rssi = StoreTempMaxRSSIofBeacon[k]!.RSSI
                        if (rssi > rssiMax) {
                            rssiMax = rssi
                            keyValue = k
                        }
                    }
                    
                }
            }
        }
        if (keyValue != 0 && rssiMax > self.WeekBeaconRSSIRemoveStrongBeacon) {
            // Localization by weak beacon
            let keyLightID = BeaconPositioningAlgorithm.LightID(keyValue)
            // Store the ID of weak beacon to avoid re-localization
            if (minorNoLongerStore!.contains(keyLightID)) {
            } else {
                minorNoLongerStore!.append(keyLightID)
                keyTimeSize.Time = StoreTempMaxRSSIofBeacon[keyValue]!.time
                keyTimeSize.Key = keyValue
                keyTimeSize.Size = 0//用不到这个值
                keyTimeSize.returnTime = NowTime
                findPeak = true
            }
            StoreScannedBeaconWeak.removeAll()
            StoreTempMaxRSSIofBeacon.removeAll()
        }
        if (findPeak) {
            ResultKeyTimeSize = keyTimeSize
            findPeak = false
        } else {
            ResultKeyTimeSize = nil
        }
    }
    
    /*
     The function to store the scaned "weak" beacons :
     key is the "minor" (major+minor) of the beacon
     context is the "timeAverageRSSI": time; rssi
     */
    func UpdateExistedBeaconSeries(_ scannedBeacon:iBeacon, _ time:Int64, _ StoreScannedBeacon:inout [Int64:[TimeAverageRSSI]]) {
        var list:[TimeAverageRSSI] = []
        var timeAverageRSSI =  TimeAverageRSSI()
        timeAverageRSSI.time = time
        timeAverageRSSI.RSSI = Double(scannedBeacon.rssi)
        if let _ = StoreScannedBeacon[scannedBeacon.minor] {
            list = StoreScannedBeacon[scannedBeacon.minor]!
            // if contains current beacon, get previous value, add new value to list and reset it to StoreScannedBeacon
            list.append(timeAverageRSSI)//add current scanned beacon
        } else {
            list.append(timeAverageRSSI) //add current scanned
        }
        StoreScannedBeacon[scannedBeacon.minor] = list // put it to scannedBeacon
    }
    
    func GetDatafromExistedBeaconSeriesForWeek(_ Key:Int64, _ StoreScannedBeacon:[Int64:[TimeAverageRSSI]]) -> TimeAverageRSSI{
        var list:[TimeAverageRSSI] = []
        list = StoreScannedBeacon[Key]! // get all list values
        var timeAverageRSSI = TimeAverageRSSI()
        let length = list.count
        for i in 0..<length {
            if (i == 0) {
                timeAverageRSSI = list[i]
            } else {
                if (timeAverageRSSI.RSSI < list[i].RSSI) {
                    timeAverageRSSI = list[i] //get max rssi value
                } else {
                }
            }
            // WriteFile.writeTxtToFilesWithEnter(filePath,fileName+"MAXRSSI.txt",Key+","+timeAverageRSSI.RSSI+","+list.get(i).RSSI)
        }
        //WriteFile.writeTxtToFilesWithEnter(filePath,fileName+"MAXRSSI.txt","//////////////////////////////////////////////////")
        return timeAverageRSSI
    }
    
    /*
     Assist function to print time
     */
    func printTime(){
        let date = Date()
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "yyy-MM-dd' at 'HH:mm:ss.SSS"
        let strNowTime = timeFormatter.string(from: date) as String
        print(strNowTime)
    }
    
}








