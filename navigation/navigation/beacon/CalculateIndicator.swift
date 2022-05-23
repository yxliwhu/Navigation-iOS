//
//  CalculateIndicator.swift
//  navigation
//
//  Created by 郑旭 on 2021/1/26.
//

import Foundation

var rssiThreshold: Double = -88.0


/*
 Return:
 result = -1: stay away from an known weak beacon
 result = 0: not get beacon info yet
 result = 1: near to the weak beacon
 */
class CalculateIndicator {
    
    static func WeekIndicator(_ PreIndicator: Int64,_ rssiList: [Double], _ WeekBeaconRSSINumberForIndex: Int)->Int64{
        var tempRSSI_Now = [Int:Double]()
        for i in 0..<rssiList.count{
            let rssi=rssiList[i]
            tempRSSI_Now[i] = rssi
        }
        var WeekIndicator:Int64 = 0
        let dataLength = rssiList.count
        if (dataLength < WeekBeaconRSSINumberForIndex){//15
            if(!judgeIsNaN(tempRSSI_Now)){
                // judge if all rssi are zero
                WeekIndicator=1 // means near week beacon
            }else{
                WeekIndicator=0
            }
            
        }else if (dataLength == WeekBeaconRSSINumberForIndex){
            let tempIndex = judgeIsNaN(tempRSSI_Now) // means all week beacon
            if (PreIndicator == 0){
                //means no week beacon in previous state
                if(tempIndex){//tempIndex=true
                    WeekIndicator = 0 // means no week
                }else{
                    WeekIndicator = 1 // means week beacon
                }
            }else if (PreIndicator == 1){
                // means in previous state, there is week beacon
                if(tempIndex){
                    WeekIndicator = -1 // means still not near
                }else{
                    WeekIndicator = 1  // means week beacon occurs
                }
            }else if (PreIndicator == -1){
                // means leave week beacon
                if(tempIndex){
                    WeekIndicator = -1
                }else{
                    WeekIndicator = 1
                }
            }else{
                print("PreIndicator Error!")
            }
        }else{
            print("Weak Beacon Rssi list Error!")
        }
        
        return WeekIndicator
    }
    
    /*
     Return "false" when received the beacon
     Return "ture" when not received the beacon
     */
    static func judgeIsNaN(_ rssimap:[Int:Double])->Bool{
        var index=true
        for (_,v) in rssimap{
            if(v != 0.0 && v > rssiThreshold){
                index=false
                break
            }
        }
        return index
    }
    
    /*
     Return:
     result = -1: stay away from an known strong beacon
     result = 0: cannot make sure the status
     result = 1: close to the known strong beacon
     */
    static func StrongIndicator(_ minorSlope:[Int64:Double],_ StrongBeaconKeyIndicator:inout [Int64:Double],_ StrongBeaconSlopeIndexPlus: Double, _ StrongBeaconSlopeIndexMius: Double )->[Int64:Double]{
        for (k,v) in  minorSlope{
            let slope = v
            let indicator = IndicatorBySlope(slope,StrongBeaconSlopeIndexPlus,StrongBeaconSlopeIndexMius) // calculate index by strong beacon index value
            StrongBeaconKeyIndicator[k]=indicator // Construct strong indicator map
        }
        return StrongBeaconKeyIndicator
    }
    
    static func  IndicatorBySlope(_ slope:Double, _ StrongBeaconSlopeIndexPlus:Double,  _ StrongBeaconSlopeIndexMius:Double)->Double{
        var indicator = 0.0
        if(slope>StrongBeaconSlopeIndexPlus){
            indicator = 1.0 // express close to beacon
        }
        else if(slope<StrongBeaconSlopeIndexMius)
        {
            indicator = -1.0 // express leave beacon
        }
        else {
            indicator = 0.0  // stable state
        }
        return indicator
    }
}
