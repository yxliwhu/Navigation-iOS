//
//  LatLng.swift
//  navigation
//
//  Created by 郑旭 on 2021/1/25.
//

import Foundation
class LatLng {
    var mVersionCode:Int
    var latitude:Double
    var longitude:Double

    init(_ var2:Double, _ var4:Double) {
        self.mVersionCode = 1
        if (-180.0 <= var4 && var4 < 180.0) {
            self.longitude = var4
        } else {
            self.longitude = ((var4 - 180.0).truncatingRemainder(dividingBy:360.0)  + 360.0).truncatingRemainder(dividingBy: 360.0) - 180.0
        }
        self.latitude = max(-90.0, min(90.0, var2))
    }

    func getVersionCode() -> Int {
        return self.mVersionCode
    }

    func toString() -> String {
        let var1:String = self.latitude.description
        let var3:String = self.longitude.description
        let res = "lat/lng:(" + var1 + "," + var3 + ")"
        return res
    }
    
    func equals(_ obj:LatLng)->Bool{
        if (self.latitude == obj.latitude && self.longitude == obj.longitude){
            return true
        }
        return false
    }
}
