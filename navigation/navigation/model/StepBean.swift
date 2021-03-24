//
//  StepBean.swift
//  navigation
//
//  Created by 郑旭 on 2021/1/26.
//

import Foundation

class StepBean {

    var step:Double
    var CompassAngle:Float
    var Name:String
    var TurnAngle:Double
    var NowUsedAngle:Double
    var ProgramStartTimeNanoTime:Int64

    
    init(){
        self.step = -1.0
        self.CompassAngle = -1.0
        self.Name = ""
        self.TurnAngle = -1.0
        self.NowUsedAngle = -1.0
        self.ProgramStartTimeNanoTime = 0
    }

    func getStep() -> Double{
        return self.step
    }

    func setStep(_ step:Double) {
        self.step = step
    }
    func getCompassAngle()->Float {
        return self.CompassAngle
    }

    func setCompassAngle(_ CompassAngle:Float) {
        self.CompassAngle = CompassAngle
    }
    func getName() ->String{
        return self.Name
    }

    func setName(_ name:String) {
        self.Name = name
    }

    func getTurnAngle() ->Double{
        return self.TurnAngle
    }

    func setTurnAngle(_ turnAngle:Double) {
        self.TurnAngle = turnAngle
    }


    func getNowUsedAngle() ->Double{
        return self.NowUsedAngle
    }

    func setNowUsedAngle(_ nowUsedAngle:Double) {
        self.NowUsedAngle = nowUsedAngle
    }


    func getProgramStartTimeNanoTime() ->Int64{
        return self.ProgramStartTimeNanoTime
    }

    func setProgramStartTimeNanoTime(_ programStartTimeNanoTime:Int64) {
        self.ProgramStartTimeNanoTime = programStartTimeNanoTime
    }

}


