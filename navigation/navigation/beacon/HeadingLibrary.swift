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
        [10001.0, 10002.0, 124.38034472384486],
        [10002.0, 10003.0, 119.60445074600491],
        [10002.0, 10001.0, 304.38034472384487],
        [10003.0, 10002.0, 299.60445074600489],
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
