//
//  HeadingLibrary.swift
//  navigation
//
//  Created by 郑旭 on 2021/1/26.
//

import Foundation

class HeadingLibrary {
    static var onePair:Bool = false
    static var StreetHeadingLib:[[Double]] = [
        [23450001.0, 23450002.0, 194.0],
        [23450002.0, 23450001.0, 14.0],

        //HKSTP
                    [24650002.0,24680008.0,127.6190519],//12-8
                    [24680008.0,24650002.0,307.6190519],//8-12
                    [24680008.0,24680006.0,121.5084846],//8-6
                    [24680006.0,24680008.0,301.5084846],//6-8
                    [24650003.0,24680009.0,126.7911073],//13-9
                    [24680009.0,24650003.0,306.7911073],//9-13
                    [24680007.0,24680009.0,305.5763494],//7-9**

        //            {24650002.0,24650006.0,127.6190519},//12-8
        //            {24650006.0,24650002.0,307.6190519},//8-12
        //            {24650006.0,24680006.0,121.5084846},//8-6
        //            {24680006.0,24650006.0,301.5084846},//6-8
        //            {24650003.0,24650007.0,126.7911073},//13-9
        //            {24650007.0,24650003.0,306.7911073},//9-13
        ////            {24650007.0,24680007.0,117.5763494},//9-7
        //            {24680007.0,24650007.0,305.5763494},//7-9**

                    [24650005.0,24650003.0,132.033623562378],//15-13
                    [24650003.0,24650005.0,312.033623562378],//13-15
                    [24650004.0,24650002.0,126.399667449934],//14-12
                    [24650002.0,24650004.0,306.399667449934],//12-14
                    [24680002.0,24680001.0,127.4516763],//2-1
                    [24680001.0,24680002.0,307.4516763],//1-2
                    [24680003.0,24680004.0,307.4516763],//3-4**
        //            {24650003.0,24650001.0,116.763689287095},//13-11
        //            {24650001.0,24650003.0,296.763689287095},//13-11
        //            {24650008.0,24650001.0,225.22896884},//10-11
        //            {24650001.0,24650008.0,45.22896884},//11-10
    ]

    static func StreetHeading(_ key:Int64) ->[Int64:Double] {
        let Key = Double(key) * 1.0
        var HeadingResult = [Int64:Double]()

        let row = StreetHeadingLib.count
        for i in 0..<row {
            if (abs(StreetHeadingLib[i][0] - Key) < 0.5) {
                let NearKey = StreetHeadingLib[i][1]//正在靠近的灯柱ID
                let Azimuth = StreetHeadingLib[i][2]
                let tempKey = Int64(NearKey)
                HeadingResult[tempKey] = Azimuth
            }

        }
        return HeadingResult
    }
    static func findBeacon(_ weakHeading:Double) ->[Double]{
        let heading = weakHeading

        let row = StreetHeadingLib.count
        var beaconMinor = [Double](repeating: 0.0, count: 2)
        for i in 0..<row {
            if (abs(StreetHeadingLib[i][2] - heading) < 0.00005) {
                beaconMinor[0] = StreetHeadingLib[i][0]//
                beaconMinor[1] = StreetHeadingLib[i][1]
                break
            }
        }
        return beaconMinor
    }
}
