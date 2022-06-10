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
    /*
     get info from JSON data
     */
    struct BeaconDataJson: Codable {
        let uuid: String
        let major: String
        let minor: String
        let lat: String
        let lon: String
        let OutdoorSiteID: String
    }
    
    func getCoordinateDirectoryFromJSON(JSONString: String)->Dictionary<String, BeaconDataJson>{
        let jsonData = JSONString.data(using: .utf8)!
        var coordinateDirectory = [String : BeaconDataJson]()
        do {
          let decoder = JSONDecoder()
          let tableData = try decoder.decode([BeaconDataJson].self, from: jsonData)
          print(tableData)
          print("Rows in array: \(tableData.count)")
            for tempBeaconDataJson in tableData {
                    let tempkey = tempBeaconDataJson.major + tempBeaconDataJson.minor
                    coordinateDirectory.updateValue(tempBeaconDataJson, forKey: tempkey)
                }
        }
        catch {
          print (error)
        }
        return coordinateDirectory
    }
    let JSONString = """
      [
      {"uuid":"CB5DF7B3-5D1F-4B3B-809A-371D9D7D9159","major":"10001","minor":"62841","lat":"22.3379","lon":"114.26272","OutdoorSiteID":"4514522048O20220421"},
      {"uuid":"CB5DF7B3-5D1F-4B3B-809A-371D9D7D9159","major":"10001","minor":"62841","lat":"22.3379","lon":"114.26272","OutdoorSiteID":"4514522048O20220421"}
      ]
      """

}


