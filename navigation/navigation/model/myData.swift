//
//  File.swift
//  navigation
//
//  Created by 郑旭 on 2021/1/25.
//

import Foundation
import CoreLocation

class myData {
    var accX:Float
    var accY:Float
    var accZ:Float
    var rotationMatrix:[Float]
    var GPSlocation:CLLocation?
    var magneticFieldValues:[Float]
    var accelemeterValues:[Float]
    var gyroscopeValues:[Float]
    var Orientation:Float
    var stepNumOwn:Float
    var nmea:String
    var BeaconLat:Double
    var BeaconLon:Double
    var GPSGetTime:Int64
    var degree:Float
    var CompassFilteredAngle:Float
    var StartStep:Double
    var stepUsed:Double
    var Heading:Double
    var KalmanFilteredPosN:Double
    var KalmanFilteredPosE:Double
    var TurnAnlge:Double
    var GPSHeading:Double
    var GPSVelecity:Float
    var HDOP:Float
    var UpdateGPSDistance:Bool
    
    init(){
        self.accX = -1.0
        self.accY = -1.0
        self.accZ = -1.0
        self.rotationMatrix = [Float]()
        self.magneticFieldValues = [Float]()
        self.accelemeterValues = [Float]()
        self.gyroscopeValues = [Float]()
        self.Orientation = -1.0
        self.stepNumOwn = -1.0
        self.nmea = ""
        self.BeaconLat = -1.0
        self.BeaconLon = -1.0
        self.GPSGetTime = 0
        self.degree = -1.0
        self.CompassFilteredAngle = -1.0
        self.StartStep = -1.0
        self.stepUsed = -1.0
        self.Heading = -1.0
        self.KalmanFilteredPosE = -1.0
        self.KalmanFilteredPosN = -1.0
        self.TurnAnlge = -1.0
        self.GPSHeading = -1.0
        self.HDOP = -1.0
        self.GPSVelecity = -1.0
        self.UpdateGPSDistance = true
    }
    
    func getAccX() -> Float { return self.accX }
    func setAccX(_ accX:Float){
        self.accX = accX
    }
    func getAccY() -> Float{
        return self.accY
    }
    func setAccY(_ accY:Float){
        self.accY = accY
    }
    func getAccZ() -> Float{
        return self.accZ
    }
    func setAccZ(_ accZ:Float){
        self.accZ = accZ
    }
    func setRotationMatrix(_ rotationMatrix:[Float]){
        self.rotationMatrix = rotationMatrix
    }
    func getGPSlocation()->CLLocation?{
        return  self.GPSlocation
    }
    func getGPSGetTime() -> Int64{
        return self.GPSGetTime
    }
    func setGPSlocation(_ GPSlocation:CLLocation,_ time:Int64){
        self.GPSlocation = GPSlocation
        self.GPSGetTime = time
    }
    func getMagneticFieldValues() -> [Float]{
        return self.magneticFieldValues
    }
    func setMagneticFieldValues(_ magneticFieldValues: [Float]){
        self.magneticFieldValues = magneticFieldValues
    }
    func setGyroscopeValues(_ gyroscopeValues: [Float]) {
        self.gyroscopeValues = gyroscopeValues
    }
    //revised by Hilary
    func getGyroscopeValues() -> [Float]{
        return self.gyroscopeValues
    }
    func getAccelemeterValues() -> [Float]{
        return self.accelemeterValues
    }
    func setAccelemeterValues(_ accelemeterValues: [Float]){
        self.accelemeterValues = accelemeterValues
    }
    func getOrientation() -> Float{
        return self.Orientation
    }
    func setOrientation(_ Orientation:Float){
        self.Orientation = Orientation
    }
    func getStepNumOwn() -> Float{
        return self.stepNumOwn
    }
    func setStepNumOwn(_ stepNumOwn:Float){
        self.stepNumOwn = stepNumOwn
    }
    
    func setNmea(_ nema: String){
        self.nmea = nema
    }
    func setBeaconLat(_ beaconLat: Double){self.BeaconLat=beaconLat}
    func getBeaconLat()->Double{return self.BeaconLat}
    func setBeaconLon(_ beaconLon:Double){self.BeaconLon=beaconLon}
    func getBeaconLon()->Double{return self.BeaconLon}
    func getDegree()->Float {
        return self.degree
    }
    func setDegree(_ degree:Float) {
        self.degree = degree
    }
    func getCompassFilteredAngle() ->Float{
        return self.CompassFilteredAngle
    }
    
    func setCompassFilteredAngle(_ compassFilteredAngle:Float) {
        self.CompassFilteredAngle = compassFilteredAngle
    }
    
    
    func getStartStep()->Double {
        return self.StartStep
    }
    
    func setStartStep(_ startStep:Double) {
        self.StartStep = startStep
    }
    
    
    func getStepUsed() ->Double{
        return self.stepUsed
    }
    func setStepUsed(_ stepUsed:Double) {
        self.stepUsed = stepUsed
    }
    func getHeading() -> Double{
        return self.Heading
    }
    func setHeading(_ heading:Double) {
        self.Heading = heading
    }
    
    func getKalmanFilteredPosN() -> Double{
        return self.KalmanFilteredPosN
    }
    func setKalmanFilteredPosN(_ kalmanFilteredPosN:Double) {
        self.KalmanFilteredPosN = kalmanFilteredPosN
    }
    func getKalmanFilteredPosE() -> Double{
        return self.KalmanFilteredPosE
    }
    func setKalmanFilteredPosE(_ kalmanFilteredPosE:Double) {
        self.KalmanFilteredPosE = kalmanFilteredPosE
    }
    
    
    func getTurnAnlge() -> Double{
        return self.TurnAnlge
    }
    
    func setTurnAnlge(_ turnAnlge:Double) {
        self.TurnAnlge = turnAnlge
    }
    
    func getGPSHeading()->Double {
        return self.GPSHeading
    }
    
    func setGPSHeading(_ GPSHeading:Double) {
        self.GPSHeading = GPSHeading
    }
    
    func getGPSVelecity() ->Float{
        return self.GPSVelecity
    }

    
    func setGPSVelecity(_ GPSVelecity:Float) {
        self.GPSVelecity = GPSVelecity
    }
    
    
    func  getHDOP() ->Float {
        return self.HDOP
    }
    
    func setHDOP(_ HDOP:Float) {
        self.HDOP = HDOP
    }
    
    //revised by Hilary
    func getRotationMatrix()->[Float]{
        return self.rotationMatrix
    }
    
    func isUpdateGPSDistance() ->Bool{
        return self.UpdateGPSDistance
    }
    
    func setUpdateGPSDistance(_ updateGPSDistance:Bool) {
        self.UpdateGPSDistance = updateGPSDistance
    }
    
}
