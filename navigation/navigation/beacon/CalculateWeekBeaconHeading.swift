//
//  CalculateWeekBeaconHeading.swift
//  navigation
//
//  Created by 郑旭 on 2021/1/26.
//
/*
 Using Week Beacon infomation to calculation the heading information
 */

import Foundation

 class CalculateWeekBeaconHeading {
    var filePath:String
    var HeadingInfo:String
    var preTimeUsed:Int64
    var lightIndictorList:[String]
    
    init(){
        self.filePath = ""
        self.HeadingInfo = "WeekHeadingInfo"
        self.preTimeUsed = 0
        self.lightIndictorList = [String]()
    }

    func CalculateHeadingByIndicator(_ Starttime: Int64,_ fileName: String,_ IndicatorMap:[Int64:[Double]]) -> Double{
        var Heading = 800.0
        let tempClonedIndicatorMap = IndicatorMap
        var tempKeyIndicator = [Int64:[Double]]()
        // Step1： Get info about weak beacon from the Indicator map
        for(k,v) in  tempClonedIndicatorMap {
            if((BeaconPositioningAlgorithm.JugeSingleStrongWeak(k) == 1)){
                tempKeyIndicator[k] = v
            }else{}
        }
        let ClonedIndicatorMap = tempKeyIndicator
        //Step2： Calculate each light's indicator value
        var KeyIndicator = [Int64:Double]()
        for(k,_) in ClonedIndicatorMap{
            ///todo:put key and indicator in KeyIndicator   把weak的NowIndex取出
            let vv = ClonedIndicatorMap[k]![2]
            KeyIndicator[k] = vv // get now indicator and put key and now indicator to
        }
        //todo: Calculate light indicator
        var LightIndicator = [Int64:Double]()
        for(k,v) in KeyIndicator {
            ///todo:put light ID and Indicator in LightIndicator
            let LightID = BeaconPositioningAlgorithm.LightID(k) // Get light id by beacon id
            if(!LightIndicator.isEmpty){
                //todo: means there is a indicator value for this light
                if(LightIndicator[LightID] != nil){
                    // indicator got from existed map
                    let ExistedLightIndicator = LightIndicator[LightID]
                    let NowIndicator = v // now indicator value
                    // calculate this light's indicator value, get the sum
                    let Indicator = (Double(ExistedLightIndicator!) + NowIndicator)
                    //set the indicator value to light
                    LightIndicator[LightID] = Indicator
                    let time = iBeaconClass.getNowMillis()
                    let recordTime = Int64((time - Starttime)/1000)
                    let rline = String(time)+","+String(LightID)+","+String(Indicator)+","+String(recordTime)
                    self.lightIndictorList.append(rline)
                }
                else{
                    LightIndicator[LightID] = v// put current value to the map
                    let time = iBeaconClass.getNowMillis()
                    let recordTime = Int64((time-Starttime)/1000)
                    let rline = String(time)+","+String(LightID)+","+String(v)+","+String(recordTime)
                    self.lightIndictorList.append(rline)
                }
            }
            else{
                LightIndicator[LightID] = v//put current value to the map
                let time = iBeaconClass.getNowMillis()
                let recordTime = Int64((time-Starttime)/1000)
                //todo write 18
                let rline = String(time)+","+String(LightID)+","+String(v)+","+String(recordTime)
                self.lightIndictorList.append(rline)
            }
        }
        let nowtimeUsed = iBeaconClass.getNowMillis()
        if ((nowtimeUsed-preTimeUsed) >= 1000){
            self.preTimeUsed = nowtimeUsed
            self.lightIndictorList.removeAll()
        }
        // LiFinish: sth should to do for -3--+3
        //todo: Step3, filter LightIndicator map
        var MinusIndicator = [Int64:Double]()
        var PlusIndicator = [Int64:Double]()
        for(k,v) in  LightIndicator{
            if(v == 0){
                // do nothing due to program could not judge close or leave beacon
            }
            else if(v < 0 && v > -4){//远离weak beacon和灯柱
                // put all -1 in this map, use 4 is due to indicator value is in the range (-2,2)
                MinusIndicator[k] = -1.0
            }
            else if(v > 0 && v < 4){//靠近strong beacon和灯珠
                // put all 1 in this map, use 4 is due to indicator value is in the range (-2,2)
                PlusIndicator[k] = 1.0
            }else{
                
            }
            
        }
        //todo: Step4, search from street heading library and create azimuth count statistical list
        var AzimuthCount = [Double:Int]()
        for(k,_) in MinusIndicator {//远离weak beacon和灯柱
            //HeadingResult存放得出的正在靠近的灯柱ID和方位角
            // Searched heading from heading library using its light id
            let HeadingResult = HeadingLibrary.StreetHeading(k)
            if (HeadingResult.count != 0) {
                var azimuth = 0.0
                for (k,v) in HeadingResult {
                    //Searched light should contains two light id values
                    if (PlusIndicator[k] != nil) {
                        azimuth = v// use searched azimuth
                        if (AzimuthCount.count == 0) {
                            AzimuthCount[azimuth] =  1 //if AzimuthCount map is null, add azimuth directly
                        } else {
                            let AzimuthCountTemp = AzimuthCount
                            for (k,v) in AzimuthCountTemp {
                                if (k == azimuth) {
                                    var count = v // get current azimuth's count
                                    count = count + 1;
                                    AzimuthCount[k] = count //means the azimuth appear again
                                } else {
                                    AzimuthCount[azimuth] = 1 //add the map, appear fist time
                                }
                            }
                        }
                    } else {
                        
                    }
                }
            } else {
                //two lightID result is error
            }
        }
        //todo: Step5, sort the count and get the end azimuth
        if(AzimuthCount.count != 0){
            if (AzimuthCount.count == 1){
                // means there is one azimuth
                for (k,_) in AzimuthCount {
                    Heading = k
                }
            }else{
               
                let AzimuthVals = [Int](AzimuthCount.values)
                // so the map sorted value is from a to z
                let MaxCount = AzimuthVals.max()// get the last one's value
                var countmax = 0
                for (k,v) in AzimuthCount {
                    //Look for the related azimuth using its count value
                    if(v == MaxCount) {
                        countmax = countmax + 1
                        Heading = k // get the value's key, so program get the heading
                    }else{
                        //not find max ID
                    }
                }
                if (countmax>1){
                    Heading = 800  // if the max count number is more than 1, means program can't judge the heading
                    countmax = 0
                }
                else if(countmax == 1){
                    
                }else{
                }
            }
        }
       
        return Heading
    }
    
    func arrayListToString(_ list:[String]) -> String{
        var stringUsed = ""
        for i in 0..<list.count{
            if(stringUsed == ""){
                stringUsed = list[i] + "\n"
            }
            else {
                stringUsed = stringUsed + list[i] + "\n"
            }
        }
        return stringUsed
    }

}
