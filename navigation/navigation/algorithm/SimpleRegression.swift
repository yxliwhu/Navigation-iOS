//
//  SimpleRegression.swift
//  navigation
//
//  Created by 郑旭 on 2021/1/25.
//

import Foundation

class SimpleRegression {
    private var sumX:Double
    private var sumXX:Double
    private var sumY:Double
    private var sumYY:Double
    private var sumXY:Double
    private var n:Int64
    private var xbar:Double
    private var ybar:Double
    private var hasIntercept:Bool


    init(_ includeIntercept:Bool) {
        self.sumX = 0.0
        self.sumXX = 0.0
        self.sumY = 0.0
        self.sumYY = 0.0
        self.sumXY = 0.0
        self.n = 0
        self.xbar = 0.0
        self.ybar = 0.0
        self.hasIntercept = includeIntercept
    }

    func addData(_ x:Double, _ y:Double) {
        if (self.n == 0) {
            self.xbar = x
            self.ybar = y
        } else if (self.hasIntercept) {
            let fact1 = 1.0 + Double(self.n)
            let fact2 = Double(self.n) / (1.0 + Double(self.n))
            let dx = x - self.xbar
            let dy = y - self.ybar
            self.sumXX += dx * dx * fact2
            self.sumYY += dy * dy * fact2
            self.sumXY += dx * dy * fact2
            self.xbar += dx / fact1
            self.ybar += dy / fact1
        }

        if (!self.hasIntercept) {
            self.sumXX += x * x
            self.sumYY += y * y
            self.sumXY += x * y
        }

        self.sumX += x
        self.sumY += y
        self.n = self.n + 1
    }

    func getSlope()->Double {
        if (self.n < 2) {
            return 0.0 / 0.0
        } else {
            return abs(self.sumXX) < 4.9E-323 ? 0.0 / 0.0 : self.sumXY / self.sumXX
        }
    }
}
