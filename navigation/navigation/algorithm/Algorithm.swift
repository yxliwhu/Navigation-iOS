//
//  Algorithm.swift
//  navigation
//
//  Created by 郑旭 on 2021/1/25.
//

import Foundation

class Algorithm
{
    var transform:Transform
    
    init(){
        self.transform = Transform()
    }
    /*
     Function to calculate the accleration in Z direction
     */
//    func zValueOfAcceleration(_ userAcc: CMAcceleration) -> Float{
//        var za:Float
//        za = us
//        return za
//    }
//
    func LatLongToDouble(_ position:LatLng) -> [Double]{
        let Lat = position.latitude
        let Long = position.longitude
        let Grid = transform.GEOHK(2,Lat,Long)
        let result:[Double] = [Grid.getN(),Grid.getE()]
        return result
    }
    
    ///****The function is to convert BLH to local grid coordinates
    func DoubleToLatLong(_ floatPosition: [Double]) -> LatLng{
        let Geo = self.transform.HKGEO(2,floatPosition[0],floatPosition[1])
        let result = LatLng(Geo.getPhi(),Geo.getFlam())
        
        return result
    }
    
    static func Distance(_ A:LatLng, _ B:LatLng) -> Double{
        let algorithm = Algorithm()
        let Axy=algorithm.LatLongToDouble(A)
        let Bxy=algorithm.LatLongToDouble(B)
        let distance=sqrt((Axy[0]-Bxy[0])*(Axy[0]-Bxy[0])+(Axy[1]-Bxy[1])*(Axy[1]-Bxy[1]))
        return  distance
        
    }
    
    /**
     * Calculate elvation by temperature and pressure
     *
     **/
    static func CalculateHeightByTP(_ Temp:Double, _ Pressure:Double) -> Double{
        let P0=1013.25
        return ((pow((P0/Pressure),1.0/5.257)-1)*(Temp+273.15))/0.0065
    }
    
    static func CalculateHeightByTP(_ Pressure:Double)->Double{
        let P0=1013.25
        return 44330*(1-(pow((Pressure/P0),1.0/5.255)))
    }
    
    
    static func formatDouble(_ d:Double) -> Double{
        let result = String(format:"%.1f", d)
        let hi = (result as NSString).doubleValue
        return hi
        
    }
    
    static func Slope(_ x:[Double], _ y:[Double]) -> Double{
        let simpleRegression = SimpleRegression(true)
        let size = x.count
        for i in 0..<size {
            simpleRegression.addData(x[i], y[i])
        }
        return simpleRegression.getSlope()
    }
    
    func toEast(_ data:[Float], _ rotation: [Float])->Float{
        var accE:Float
        accE=rotation[0]*data[0]+rotation[1]*data[1]+rotation[2]*data[2]
        return accE
    }
    func toNorth(_ data:[Float], _ rotation: [Float])->Float{
        var accN: Float
        accN=rotation[3]*data[0]+rotation[4]*data[1]+rotation[5]*data[2]
        return accN
    }
    func toVertical(_ data:[Float], _ rotation: [Float]) -> Float{
        var accU:Float
        accU=rotation[6]*data[0] + rotation[7] * data[1] + rotation[8] * data[2]
        return accU
    }
    static func StepChange(_ StepList: inout [Double],_ step:[Double] ) ->Double{
        var StepChnage = 0.0
        if (StepList.count > 0) {
            let ftv = StepList[0]
            
            if (StepList.count == 1){
                StepList.append(ftv) // add the the step number of 0 to 1
            }
            else {
                StepList[1] = ftv //Set the step number of 0 to 1
            }
            
        }
        StepList.insert(contentsOf: step,at: 0)
        if (StepList.count > 1) {
            if (!StepList.isEmpty) {
                StepChnage = StepList[0] - StepList[1] // changed step number
                print("step == " + StepChnage.description)
            }
        }
        if (StepList.count >= 2) {
            StepList.remove(at:2) // remove the third value
        }
        return StepChnage
    }
    
    static func AngleConvert(_ angle: inout Double) -> Double{
        var result:Double
        if (angle>360){
            angle = angle-360
        }else if (angle<0){
            angle = angle+360
        }
        if (angle > 180) {
            result = angle - 360
        } else{
            result = angle
        }
        return result
    }
    
    static func StepLenghtAdjustmentByChenMethod(_ H: Float,_ SF: Float) -> Float{
        let a = 0.371
        let b = 0.227
        let c = 1.0
        var SL:Float
        let v0 = a * (Double(H) - 1.75)
        let v1 = (Double(b) * (Double(SF)-1.79) * Double(H))/1.75
        let stm = 0.7 + v0 + v1
        SL = Float(stm * c) // The method is got from the paper of professor Ruizhi Chen
        return SL
    }
    static func MoveToWeekBeaconPosition(_ BeaconUsed:iBeacon, _ DistanceNow:[Double], _ allDistancePast: inout [Double], _ positionNow: inout LatLng, _ positionPast: inout LatLng ) {
        let tempLightID = BeaconPositioningAlgorithm.LightID(BeaconUsed.minor)
        positionNow = BeaconCoordinates.positionFromBeacon(tempLightID)
        allDistancePast[0] = DistanceNow[0]
        allDistancePast[1] = DistanceNow[1]
        positionPast = positionNow
        print("move to weak beacon position")
    }
    
    static func CalculatePDRPrecision(_ PDRPrecision:Double,_ DeltaDistance:Double)->Double{
        let resultPrecsion:Double
        let a=1.0
        let b=0.0
        let xa = abs(DeltaDistance) * a
        resultPrecsion = xa + b + PDRPrecision
        return resultPrecsion
    }
}
