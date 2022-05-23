//
//  BeaconPositioningAlgorithm.swift
//  navigation
//
//  Created by 郑旭 on 2021/1/26.
//

import Foundation


struct KeyTimeSize {
    var Key:Int64
    var Time:Int64
    var Size:Int
    var returnTime:Int64
    init(){
        self.Key = -1
        self.Time = -1
        self.Size = -1
        self.returnTime = -1
    }
}

struct TimeAverageRSSI {
    var time:Int64
    var RSSI:Double
    init() {
        self.time = -1
        self.RSSI = -1
    }
}

class BeaconPositioningAlgorithm {
    //This is the other rssi-distance model algorithm
    
    /*
     This function not used in iOS version
     */
    static func rss_cal_distance_all(_ rss:Double, _ index:Double) -> Double{
        var distance = 0.0
        //Middle single beacon
        if (index == 2) {
            if (rss > -90) {
                distance = exp((rss + 75.22) / -3.853)
            }
            if (rss <= -90 && rss >= -105) {
                let abs_RSS = abs(rss)
                distance = (11 / 3) * abs_RSS - 285
            }
            
        }
        //Strong single beacon
        if (index == 3) {
            if (rss > -83) {
                distance = exp((rss + 65.86) / -4.134)
            }
            if (rss <= -83 && rss >= -105) {
                let abs_RSS = abs(rss)
                distance = (100 / 22) * abs_RSS - 327.2727
            }
            
        }
        return distance
    }
    
    /*
     The function is to judge if beacon is strong, middle or weak
     Here 1 is weak beacon and 2 is strong beacon
     */
    static func JugeSingleStrongWeak(_ id:Int64) -> Int{
        //Convert to string
        let ID = String(id)
        var result:String
        //Get the fifth number of the ID
        if (ID.count >= 10) {
            result = iBeaconClass.substring(ID,5,6)//(ID.length()-5,ID.length()-4)
        } else {
            result = "9"//9 mean it is not our beacon
        }
        guard let index = Int(result) else { return -1 }
        return index
    }
    
    /*
     Make the key simple only get "BDDDD" form "A000BCDDDD":
     B: 1 for lampost and 2 for non-lampost
     DDDD: Installing position number
     */
    static func LightID(_ id:Int64) -> Int64 {
        //Convert to string
        let ID = String(id)
        var result:String
        if (ID.count >= 10) {
            result = iBeaconClass.substring(ID,1, 5) + iBeaconClass.substring(ID,6, 10)
        } else {
            result = ID
        }
        guard let index = Int64(result) else {return -1}
        return index
    }
    
    
    static func fixedArray(_ m:Int,_ n:Int)->[[Double]]{
        return [[Double]](repeating: [Double](repeating: 0.0, count: n), count: m)
    }
    
    /*
     Calculate the position of the used based on the distances from strong beacon
     Return:  strong beacon X, Y and Covariance_X, Covariance_Y
     */
    static func CalculatePositionByDistance(_ KeyDistance:[Int64:[Double]]) -> [Double]{
        let countThreshold = 30
        let size = KeyDistance.count
        let algorithm = Algorithm()
        var distances = [Double](repeating: 0.0, count: size)
        var BeaconKey = [Int64](repeating: 0, count: size)
        var ininitialCoord:[Double] = [1000, 1000]
        var Count2 = 0
        _ = 0
        var e_current = 0.0
        var e_new = 0.0
        var lamda = 0.08
        var corrX = 0.0
        var corrY = 0.0
        var update = true
        var unitVar = 0.0
        var VarX = 0.0
        var VarY = 0.0
        var Count1 = 0
        
        var VarCovar:Matrix
        var selected_A_Matrix = Matrix(paramInt1: size,paramInt2: 2)
        var selected_x_Matrix = Matrix(paramInt1: size,paramInt2: 1)
        var selected_L_Matrix = Matrix(paramInt1: size,paramInt2: 1)
        var selected_Hessian = Matrix(paramInt1: 2,paramInt2: 2)
        let Hessian_Matrix = Matrix(paramInt1: 2,paramInt2: 2)
        var L_Matrix = Matrix(paramInt1: size,paramInt2: 1)
        let A_Matrix = Matrix(paramInt1: size,paramInt2: 2)
        let Weighted_Atran_Matrix = Matrix(paramInt1: 2,paramInt2: size)
        var residual:Matrix
        var residual_tran:Matrix
        do {
            for (k,v) in KeyDistance {
                distances[Count1] = v[0]
                let tempLightID = BeaconPositioningAlgorithm.LightID(k)
                BeaconKey[Count1] = tempLightID

                ininitialCoord[0] = (ininitialCoord[0] + v[1]) // add all beacon coordinate north
                ininitialCoord[1] = (ininitialCoord[1] + v[2]) // add all beacon coordinate east
                Count1 = Count1 + 1
            }

            ininitialCoord[0] = ininitialCoord[0] / Double(Count1) // improve initail coordinate accuracy
            ininitialCoord[1] = ininitialCoord[1] / Double(Count1) // improve initail coordinate accuracy

            ///Set distance observation matrix
            let distanceMatrix = Matrix(paramInt1: size,paramInt2: 1)
            for i in 0..<size {
                distanceMatrix.set(paramInt1: i, paramInt2: 0, paramDouble: distances[i]) // create a distance matrix
            }
            
            ///create Weight matrix
            let weightMatrix = Matrix(paramInt1: size,paramInt2: size)
            for i in 0..<size {
                for j in 0..<size {
                    if (i == j) {
                        // set weight matrix by by each beacon distance
                        weightMatrix.set(paramInt1: i, paramInt2: j, paramDouble: 1 / pow(distances[i], 2))
                    } else {
                        //set other elements to zero
                        weightMatrix.set(paramInt1: i, paramInt2: j, paramDouble: 0)
                    }
                }
            }
            
            ///Set beacon coordinate matrix
            let beaconMatrix = Matrix(paramInt1: size,paramInt2: 2)
            for i in 0..<size {
                let tempLightID = BeaconPositioningAlgorithm.LightID(BeaconKey[i])
                let BeaconLatLon = BeaconCoordinates.positionFromBeacon(tempLightID)
                let xy = algorithm.LatLongToDouble(BeaconLatLon)
                for j in 0..<2{
                    // set ROW = Beacon Size, Column =2, beacon coordinate matrix
                    beaconMatrix.set(paramInt1: i, paramInt2: j, paramDouble: xy[j])
                }
            }
            
            ///Set initial coordinate matrix
            let approxCoord = Matrix(paramInt1: 2,paramInt2: 1)
            let cc = ininitialCoord.count
            for k in 0..<cc {
                approxCoord.set(paramInt1: k, paramInt2: 0, paramDouble: ininitialCoord[k])
            }
            
            while (Count2 < countThreshold) {
                /// update times
                if (update) {
                    ///Calculate approximate distance matrix
                    let approxDistanceMatrix = Matrix(paramInt1: size,paramInt2: 1)
                    for i in 0..<size {
                        let beaconX = beaconMatrix.get(paramInt1: i, paramInt2: 0)
                        let beaconY = beaconMatrix.get(paramInt1: i, paramInt2: 1)
                        let approxX = approxCoord.get(paramInt1: 0, paramInt2: 0)
                        let approxY = approxCoord.get(paramInt1: 1, paramInt2: 0)
                        //calculate approximate distance from these values
                        approxDistanceMatrix.set(paramInt1: i, paramInt2: 0, paramDouble: sqrt(pow(beaconX - approxX, 2) + pow(beaconY - approxY, 2)))
                    }
                    // set L matrix, got from model calculated distance minus approximate distance
                    L_Matrix = try distanceMatrix.minus(paramMatrix: approxDistanceMatrix)
                    if (Count2 == 0) {
                        var dotProduct = [Double](repeating: 0.0, count: size)
                        for i in 0..<size {
                            dotProduct[i] = L_Matrix.get(paramInt1: i, paramInt2: 0) * L_Matrix.get(paramInt1: i, paramInt2: 0)
                            // e_current = e_current + dotProduct[i] * dotProduct[i]
                            e_current = e_current + dotProduct[i]
                        }
                    }
                    ///Set MATRIX A
                    for i in 0..<size {
                        for j in 0..<2 {
                            // (app_X-beaconX)/app_distance, linear equation coefficient
                            A_Matrix.set(paramInt1: i, paramInt2: j, paramDouble: (approxCoord.get(paramInt1: j, paramInt2: 0) - beaconMatrix.get(paramInt1: i, paramInt2: j)) / approxDistanceMatrix.get(paramInt1: i, paramInt2: 0))
                        }
                    }
                    let A_Matrix_tran = A_Matrix.transpose()
                    
                    ////Set weight matrix
                    var WeightedResult = fixedArray(2,size)
                    // rows from m1
                    for i in 0..<2 {
                        for j in 0..<size {     // columns from m2
                            for k in 0..<size { // columns from m1
                                WeightedResult[i][j] += A_Matrix_tran.get(paramInt1: i, paramInt2: k) * weightMatrix.get(paramInt1: k, paramInt2: j) ///AT*P
                            }
                        }
                    }
                    for i in 0..<2 {
                        for j in 0..<size {
                            Weighted_Atran_Matrix.set(paramInt1: i, paramInt2: j, paramDouble: WeightedResult[i][j])
                        }
                    }
                    
                    ////Set Hessian matrix
                    var Result = fixedArray(2,2)
                    for i in 0..<2 {         // rows from m1
                        for j in 0..<2 {     // columns from m2
                            for k in 0..<size { // columns from m1
                                Result[i][j] += Weighted_Atran_Matrix.get(paramInt1: i, paramInt2: k) * A_Matrix.get(paramInt1: k, paramInt2: j) ///AT*P*A
                            }
                        }
                    }
                    for i in 0..<2 {
                        for j in 0..<2 {
                            Hessian_Matrix.set(paramInt1: i, paramInt2: j, paramDouble: Result[i][j])
                        }
                    }
                }
                ////Set Hessian matrix
                let lamda_identity_Matrix = Matrix(paramInt1: 2,paramInt2: 2)
                for i in 0..<2 {
                    for j in 0..<2 {
                        if (i == j) {
                            lamda_identity_Matrix.set(paramInt1: i, paramInt2: j, paramDouble: lamda * 1.0)
                        } else {
                            lamda_identity_Matrix.set(paramInt1: i, paramInt2: j, paramDouble: 0)
                        }
                    }
                }
                let Hessian_lamda_Matrix = try Hessian_Matrix.plus(paramMatrix: lamda_identity_Matrix) ///Lamada + ATPA
                
                let Hessian_lamda_inv = try Hessian_lamda_Matrix.inverse()/// (Lamada + ATPA) inverse
                
                ///set Atran_mul_L matrix
                let Atran_mul_L = Matrix(paramInt1: 2,paramInt2: 1)
                var Result2 = fixedArray(2, 1)
                for i in 0..<2 {         // rows from m1
                    for j in 0..<1 {     // columns from m2
                        for k in 0..<size { // columns from m1
                            Result2[i][j] += Weighted_Atran_Matrix.get(paramInt1: i, paramInt2: k) * L_Matrix.get(paramInt1: k, paramInt2: j) ///ATPL
                        }
                    }
                }
                for i in 0..<2 {
                    for j in 0..<1 {
                        Atran_mul_L.set(paramInt1: i, paramInt2: j, paramDouble: Result2[i][j])
                    }
                }
                
                ///set x_Matrix
                let x_Matrix = Matrix(paramInt1: 2,paramInt2: 1)
                var Result3 = fixedArray(2, 1)
                for i in 0..<2 {         // rows from m1
                    for j in 0..<1 {     // columns from m2
                        for k in 0..<2 { // columns from m1
                            Result3[i][j] += Hessian_lamda_inv.get(paramInt1: i, paramInt2: k) * Atran_mul_L.get(paramInt1: k, paramInt2: j) ///Inverse( Lamada + ATPA ) * ATPL
                        }
                    }
                }
                for i in 0..<2 {
                    for j in 0..<1 {
                        x_Matrix.set(paramInt1: i, paramInt2: j, paramDouble: Result3[i][j]) //dx, dy
                    }
                }
                // approx_X +dx, approx_Y+dy
                let lamda_corr_para = try approxCoord.plus(paramMatrix: x_Matrix)
                ///set x_Matrix
                let Dist_lamda = Matrix(paramInt1: size, paramInt2: 1)
                for i in 0..<size {
                    let beaconX = beaconMatrix.get(paramInt1: i, paramInt2: 0)
                    let beaconY = beaconMatrix.get(paramInt1: i, paramInt2: 1)
                    // calculated coordinate of surveyor
                    let X_lamda = lamda_corr_para.get(paramInt1: 0, paramInt2: 0)
                    // calculated  coordinate of surveyor
                    let Y_lamda = lamda_corr_para.get(paramInt1: 1, paramInt2: 0)
                    // Update new distance
                    Dist_lamda.set(paramInt1: i, paramInt2: 0, paramDouble: sqrt(pow(beaconX - X_lamda, 2) + pow(beaconY - Y_lamda, 2)))
                }
                // Update L matrix, distance error
                let L_Matrix_lamda = try distanceMatrix.minus(paramMatrix: Dist_lamda)
                
                var dotProduct = [Double](repeating: 0.0, count: size)
                e_new = 0
                for i in 0..<size{
                    // Update new distance square error
                    dotProduct[i] = L_Matrix_lamda.get(paramInt1: i, paramInt2: 0) * L_Matrix_lamda.get(paramInt1: i, paramInt2: 0)
                    e_new = e_new + dotProduct[i]
                }
                if (e_new < e_current) {
                    // if new distance square error is smaller than previous one
                    lamda = lamda / 10.0 // reduce lamda value
                    approxCoord.set(paramInt1: 0, paramInt2: 0, paramDouble: lamda_corr_para.get(paramInt1: 0, paramInt2: 0)) // update approximate coordinates
                    approxCoord.set(paramInt1: 1, paramInt2: 0, paramDouble: lamda_corr_para.get(paramInt1: 1, paramInt2: 0)) // update approximate coordinates
                    e_current = e_new //upate distance square error
                    corrX = lamda_corr_para.get(paramInt1: 0, paramInt2: 0)
                    corrY = lamda_corr_para.get(paramInt1: 1, paramInt2: 0)
                    selected_A_Matrix = A_Matrix
                    selected_x_Matrix = x_Matrix
                    selected_L_Matrix = L_Matrix_lamda
                    selected_Hessian = Hessian_Matrix
                    update = true
                } else {
                    lamda = lamda * 10 // set larger lamda value to update again
                    update = false
                }
                Count2 = Count2 + 1
                
                if (Count2 == (countThreshold - 1)) {
                    //Calculate error VTPV in last time
                    let A_mul_x = Matrix(paramInt1: size, paramInt2: 1)
                    var Ax = fixedArray(size, 1)
                    for i in 0..<size {         // rows from m1
                        for j in 0..<1 {     // columns from m2
                            for k in 0..<2 { // columns from m1
                                Ax[i][j] += selected_A_Matrix.get(paramInt1: i, paramInt2: k) * selected_x_Matrix.get(paramInt1: k, paramInt2: j) // A*x
                            }
                        }
                    }
                    
                    for i in 0..<size {
                        for j in 0..<1 {
                            A_mul_x.set(paramInt1: i, paramInt2: j, paramDouble: Ax[i][j])
                        }
                    }
                    residual = try A_mul_x.minus(paramMatrix: selected_L_Matrix) //V= AX-L
                    residual_tran = residual.transpose() //(deltaX) T
                    let residualtran_mul_Weight = Matrix(paramInt1: 1,paramInt2: size)
                    var VTP = fixedArray(1, size)
                    for i in 0..<1 {         // rows from m1
                        for j in 0..<size {     // columns from m2
                            for k in 0..<size{ // columns from m1
                                VTP[i][j] += residual_tran.get(paramInt1: i, paramInt2: k) * weightMatrix.get(paramInt1: k, paramInt2: j)//VTP
                            }
                        }
                    }
                    
                    for i in 0..<1 {
                        for j in 0..<size{
                            residualtran_mul_Weight.set(paramInt1: i, paramInt2: j, paramDouble: VTP[i][j]) //VTP
                        }
                    }
                    let sumOfSquareOfResidual = Matrix(paramInt1: 1,paramInt2: 1)
                    var VTPV = fixedArray(1, 1)
                    for i in 0..<1 {         // rows from m1
                        for j in 0..<1 {     // columns from m2
                            for k in 0..<size { // columns from m1
                                VTPV[i][j] += residualtran_mul_Weight.get(paramInt1: i, paramInt2: k) * residual.get(paramInt1: k, paramInt2: j) //VTPV
                            }
                        }
                    }
                    for i in 0..<1 {
                        for j in 0..<1 {
                            sumOfSquareOfResidual.set(paramInt1: i, paramInt2: j, paramDouble: VTPV[i][j]) //VTPV
                        }
                    }
                    
                    unitVar = sumOfSquareOfResidual.get(paramInt1: 0, paramInt2: 0) / Double((size - 2)) //(VTPV/r)
                    
                    VarCovar = try (selected_Hessian.inverse()).times(paramDouble: unitVar) //selected_Hessian is VAR = UnitVar* N.inverse, N=ATPA
                    VarX = VarCovar.get(paramInt1: 0, paramInt2: 0) // Variation of X
                    VarY = VarCovar.get(paramInt1: 1, paramInt2: 1) // Variation of Y
                    
                }
            }
        } catch{
            print(error)
        }
        let resVal:[Double] = [corrX, corrY, sqrt(VarX), sqrt(VarY)]
        return resVal //Return strong beacon X, Y and Covariance
    }
    
    /*
     Check the paramters please (sometimes the distance value is negative)
     */
    static func CalculateDistanceByRSSI(_ Key:Int64, _ RSSI:Double) -> Double{
        let Beaconminor = BeaconPositioningAlgorithm.JugeSingleStrongWeak(Key)
        var a = 1.0
        var b = 1.0
        var c = 1.0
        if (Beaconminor == 3) {
            a = -211.97091652
            b = 157.74093691
            c = -0.00491896
        } else if (Beaconminor == 2) {
            a = -211.97091652
            b = 157.74093691
            c = -0.00491896
//            a = -23.74820488
//            b = 3.27895321
//            c = -0.03064923
        }
        let distance = a + b * (exp(c * RSSI))
        return distance
    }
    
    /*
     Function: Using strong beacon rssi records to calculated distances
     */
    static func CalculateDistanceMapByStrongBeacon(_ ibeacon:iBeacon, _ StoreBeaconSerise:[Int64:[TimeAverageRSSI]]) ->[Int64:[Double]] {
        
        // Get all strong beacon records from all records (maybe the filter is not necessary considering having done in last stage)
        var StrongBeaconSerise = [Int64:[Double]]()
        if (StoreBeaconSerise.count >= 3) {
            for (key,value) in StoreBeaconSerise {
                let Beaconminor = BeaconPositioningAlgorithm.JugeSingleStrongWeak(key)
                if (Beaconminor == 2 || Beaconminor == 3) {
                    let list = value
                    var arrayList = [Double]()
                    if (!list.isEmpty) {
                        for _ in 0..<list.count {
                            let a = list[0].RSSI
                            arrayList.append(a)
                        }
                        StrongBeaconSerise[key] = arrayList// Get a strong beacon RSSI series
                    }
                }
            }
        }
        
        // Get the stronger strong beacon is used in every smartlamp considering every lamppost have two strong beacon
        let StrongBeaconSeriseClone = StrongBeaconSerise
        var StrongBeaconOfLightSerise = [Int64:[Double]]()
        
        for (k,v) in StrongBeaconSeriseClone {
            let list = v
            var LightIDAndStrongKey=[Int64:Int64]()
            let thisLightID = BeaconPositioningAlgorithm.LightID(k)
            if (LightIDAndStrongKey[thisLightID] != nil) {
                //Light上已存有的一个strong beacon的minor值
                let oldStrongBeaconKey = LightIDAndStrongKey[thisLightID]
                let thisRssiAverage = CalculateAve(list)
                if(StrongBeaconOfLightSerise[oldStrongBeaconKey!] != nil){
                    let oldRssiAverage = CalculateAve(StrongBeaconOfLightSerise[oldStrongBeaconKey!]!)
                    if (thisRssiAverage > oldRssiAverage) {
                        StrongBeaconOfLightSerise.removeValue(forKey:oldStrongBeaconKey!)
                        StrongBeaconOfLightSerise[k] = list
                    }
                }
            } else {
                StrongBeaconOfLightSerise[k] = list
                LightIDAndStrongKey[thisLightID]  = k
            }
        }
        // Calculate distances based on Rssi value of strong beacons
        var KeyDistance = [Int64:[Double]]()
        if (StrongBeaconOfLightSerise.count >= 3) {
            //if strong smartlamps are more than 3
            var RSSIMean = 0.0
            for (k,v) in StrongBeaconOfLightSerise {
                let arrayList = v
                var sum = 0.0
                for i in 0..<arrayList.count {
                    sum = sum + arrayList[i]
                }
                //Calculate average signal value of strong beacons
                RSSIMean = sum / Double(arrayList.count)
                var DistanceXY = [Double]()
                let distance = CalculateDistanceByRSSI(k, RSSIMean)
                let tempLightID = BeaconPositioningAlgorithm.LightID(k)
                let BL = BeaconCoordinates.positionFromBeacon(tempLightID)
                var xy:[Double] = [0, 0]
                if (BL.latitude != -1 && BL.longitude != -1) {
                    let algorithm = Algorithm()
                    xy = algorithm.LatLongToDouble(BL)//Covert to plane coordinates
                    DistanceXY.append(distance)
                    DistanceXY.append(xy[0])
                    DistanceXY.append(xy[1])
                    KeyDistance[k] = DistanceXY
                }
            }
        }
        
        return KeyDistance
    }
    
    static func CalculateAve(_ list:[Double]) ->Double {//???
        let count = list.count
        var sumValue = 0.0
        //ArrayList<PostBeaconScan.TimeAverageRSSI> RSSIlist = list
        for i in 0..<count {
            let Value = list[i]//???
            //double Value = list.get(i)
            sumValue += Value
        }
        return Algorithm.formatDouble(sumValue / Double(count))
    }
}
