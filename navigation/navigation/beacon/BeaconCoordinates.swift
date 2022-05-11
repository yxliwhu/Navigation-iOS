//
//  BeaconCoordinates.swift
//  navigation
//
//  Created by 郑旭 on 2021/1/25.
//

import Foundation

class BeaconCoordinates {
    static func positionFromBeacon(_ LightID:Int64) -> LatLng{
        var result:LatLng = LatLng(-1,-1)

        if(LightID==10001){result =  LatLng(22.428720526,114.209055388)}
        if(LightID==10002){result =  LatLng(22.428485659,114.209424448)}
        if(LightID==10003){result =  LatLng(22.428259811,114.209851790)}

        return  result
    }
}
