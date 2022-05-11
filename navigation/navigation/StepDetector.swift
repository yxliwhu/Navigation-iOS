//
//  StepDetector.swift
//  navigation
//
//  Created by 郑旭 on 2021/2/3.
//

import Foundation

class StepDetector {
    
    var Realtime:Bool
    var data:Data
    var userHeight:String
    var kalmanPositionDetector:KalmanPositionDetector
    var MygyroHeading: Float = 0.0
    
    init(_ userHeight:String,_ realtime:Bool){
        self.data = Data()
        self.userHeight = userHeight
        self.Realtime = realtime
        self.kalmanPositionDetector =  navigation.KalmanPositionDetector(&self.data,userHeight,self.Realtime)
    }
    
    func getDetector()->KalmanPositionDetector{
        return self.kalmanPositionDetector
    }
    
    func toDegrees(_ radians:Double)->Double{
        return ((radians) * (180.0 / Double.pi))
    }
    
    func onSensorChanged(_ sensorEvent:DeviceData) {
        if (Realtime) {
            self.kalmanPositionDetector.initSensorChange()
            let acc = sensorEvent.accelerometer
            data.setAccX(Float(acc!.acceleration.x))
            data.setAccY(Float(acc!.acceleration.y))
            data.setAccZ(Float(acc!.acceleration.z))
            
            let rmat = sensorEvent.motion!.attitude.rotationMatrix
            let Rotation:[Float] = [Float(rmat.m11),Float(rmat.m12),Float(rmat.m13),
                                    Float(rmat.m21),Float(rmat.m22),Float(rmat.m23),
                                    Float(rmat.m31),Float(rmat.m32),Float(rmat.m33)]
            self.data.setRotationMatrix(Rotation)
            
            //codes for step counter start****************************************
            let userAcc = sensorEvent.motion!.userAcceleration
            let za = Float(userAcc.z * 9.8)// Get the vertical accelerate
            var lp = self.kalmanPositionDetector.getLp()
            lp = za * 0.2 + lp *  0.8
            self.kalmanPositionDetector.setLp(lp)
            let step = self.kalmanPositionDetector.stepCounting(lp)
            self.kalmanPositionDetector.setStep(step)
            self.data.setStepNumOwn(Float(step))
            //codes for step counter end *****************************************
            
            let meg = sensorEvent.magnetic!.magneticField
            let megVals:[Float] = [Float(meg.x),Float(meg.y),Float(meg.z)]
            data.setMagneticFieldValues(megVals)
            
            let accVals:[Float] = [Float(acc!.acceleration.x),Float(acc!.acceleration.y),Float(acc!.acceleration.z)]
            data.setAccelemeterValues(accVals)
            
            //Get the heading info from magnetometer
            let magnHeading = self.kalmanPositionDetector.getMagnHeading
            data.setDegree(Float(magnHeading()))
            
            let gyro = sensorEvent.motion!.rotationRate
    
            let gyroVals:[Float] = [Float(gyro.x),Float(gyro.y),Float(gyro.z)]
            self.data.setGyroscopeValues(gyroVals)
            // This time step's delta rotation to be multiplied by the current rotation
            // after computing it from the gyro sample data.
            let dT = Float(MotionHelper.sampleTime) / 1000.0
            let axisRawGryo = data.getGyroscopeValues()
            var axisConvert:[Float] = [Float](repeating: 0, count: 3)//convert gyro using system matrix
            axisConvert[0] =  Float(toDegrees(Double(self.kalmanPositionDetector.getAlgorithm().toEast(axisRawGryo, data.getRotationMatrix())))) * dT//Convert to horizontal altitude
            axisConvert[1] = Float(toDegrees(Double(self.kalmanPositionDetector.getAlgorithm().toNorth(axisRawGryo, data.getRotationMatrix())))) * dT //Convert to horizontal altitude
            axisConvert[2] =  Float(toDegrees(Double(self.kalmanPositionDetector.getAlgorithm().toVertical(axisRawGryo, data.getRotationMatrix())))) * dT //Convert to horizontal altitude
            
            let axisZAngle = axisConvert[2]
            var MygyroHeading = self.kalmanPositionDetector.getMygyroHeading()
//            print(axisZAngle)
            MygyroHeading = MygyroHeading + axisZAngle //Gyro integration angle
            self.kalmanPositionDetector.setMygyroHeading(MygyroHeading)
//            self.kalmanPositionDetector.setMagnHeading(Double(MygyroHeading))
            data.setTurnAnlge(self.kalmanPositionDetector.CalculateGyroMax(self.kalmanPositionDetector.getCurrentTime(), axisZAngle)) //Calculate trun angle and set it to data
            
            var x_angle = KalmanCalculate.kalmanCalculate(data.getDegree(),axisZAngle,dT)// Kalman fiter heading got from accelerometer, magnerometer and gyroscope
            if (x_angle < 0) {
                x_angle = x_angle + 360 ///Convert to [0, 360]
            }
            x_angle = x_angle.truncatingRemainder(dividingBy: 360.0)
            KalmanCalculate.setX_angle(x_angle)
            data.setCompassFilteredAngle(x_angle) //Set filtered angle to data
        }
        
        self.getDetector().calculate()
    }
}

