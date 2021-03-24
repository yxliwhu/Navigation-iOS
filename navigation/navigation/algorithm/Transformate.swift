//
//  Transformate.swift
//  navigation
//
//  Created by 郑旭 on 2021/1/25.
//

import Foundation


class GeoData {
    var phi:Double
    var flam:Double
    
    init() {
        self.phi = 0
        self.flam = 0
    }
    
    func getPhi()->Double {
        return self.phi
    }
    
    func getFlam() ->Double{
        return self.flam
    }
    
    func setPhi(_ input:Double) {
        self.phi = input
    }
    
    func setFlam(_ input:Double) {
        self.flam = input
    }
}

// Just for holding the return value from function "Transform"
// For holding Grid coordinates data (HK1980 Grid)

class GridData {
    var  n:Double
    var  e:Double
    
    init() {
        self.n = 0
        self.e = 0
    }
    
    func getN() ->Double{
        return self.n
    }
    
    func getE() ->Double{
        return self.e
    }
    
    func setN(_ input:Double) {
        self.n = input
    }
    
    func setE(_ input:Double) {
        self.e = input
    }
}

// Just for holding the return value from "Transform"
// For holding Radius Data

class RadiusData {
    var rho:Double
    var rmu:Double
    
    init() {
        self.rho = 0
        self.rmu = 0
    }
}


// !!! CODE: Do transformation between three systems:  WGS84, Hayford, HKGrid

class Transform {
    var pi:Double
    
    init() {
        self.pi = 3.14159265359
    }
    
    /**COBVERT HK1980 GRID COORDINATES TO CEOGETIC COORDINTES
     *
     * @param IG: 1 FOR HAYFORD SPHEROID, 2 FOR WGS84 SPHEROID
     * @param X: NORTHING (HK1980 DATAM)
     * @param Y: EASTING RETURN (HK1980 DATAM)
     * @param PHI: LATITUDE
     * @param FLAM: LONGITUDE
     * @return
     */
    func  HKGEO(_ IG:Double, _ X: Double, _ Y:Double)->GeoData {
        var RAD, PHI0, FLAM0:Double
        var a, b, C, D:Double
        var WX, WY, AA, BB, DPHI:Double
        var PHIF, DPH, SM, CR:Double
        var TPHI, TPHI2, TPHI4, TPHI6:Double
        var TT, TT2, TT3, TT4:Double
        var DUE, DX, CPHI1, CPHI2:Double
        var CPHI3, CPHI4, CLAM1, CLAM2:Double
        var CLAM3, CLAM4, DY, DX2:Double
        var RHO, RMU:Double
        var FLAM:Double
        var PHI:Double
        
        let Result = GeoData()
        var RadiusResult = RadiusData()
        
        RAD = pi / 180
        
        var TX = X
        var TY = Y
        if (IG == 1) {
            PHI0 = (22 + 18.00 / 60.00 + 43.68 / 3600.00) * RAD
            FLAM0 = (114 +  10.00 / 60.00 + 42.8 / 3600.00) * RAD
        } else {
            PHI0 = (22 + 18.00 / 60 + 38.17 / 3600.00) * RAD
            FLAM0 = (114 + 10.00 / 60 + 51.65 / 3600.00) * RAD
            
            // --- TRANSFORM HK 1980 GRID TO WGS84 GRID
            a = 1.0000001619
            b = 0.000027858
            C = 23.098979
            D = -23.149125
            WX = a * TX - b * TY + C
            WY = b * TX + a * TY + D
            TX = WX
            TY = WY
        }
        
        // --- REMOVE FALSE GRID ORIGIN COORDINATES
        
        DX = TX - 819069.8
        DY = TY - 836694.05
        
        // --- COMPUTE PROVISIONAL PHIF (APPROXIMATE)
        AA = 6.853561524
        BB = 110736.3925
        let sptmp = sqrt(DX * AA * 4 + pow(BB, 2)) - BB
        DPHI = (sptmp * 0.5 / AA) * RAD
        PHIF = PHI0 + DPHI
        DPH = 0
        
        // --- EVALUATE PHIF, ITERATE UNTIL CR IS NEAR ZERO
        repeat{
            PHIF = PHIF + DPH
            SM = SMER(IG, PHI0, PHIF)
            CR = DX - SM
            RadiusResult = RADIUS(IG, PHIF)
            RHO = RadiusResult.rho
            RMU = RadiusResult.rmu
            DPH = CR / RHO
        } while (abs(CR) >= 0.00001)
        
        // --- COMPUTE RADII
        RadiusResult = RADIUS(IG, PHIF)
        RHO = RadiusResult.rho
        RMU = RadiusResult.rmu
        TPHI = tan(PHIF)
        TPHI2 = TPHI * TPHI
        TPHI4 = TPHI2 * TPHI2
        TPHI6 = TPHI2 * TPHI4
        TT = RMU / RHO
        TT2 = pow(TT, 2)
        TT3 = pow(TT, 3)
        TT4 = pow(TT, 4)
        
        // --- COMPUTE LATITUDE
        DUE = DY
        DX = DUE / RMU
        DX2 = DX * DX
        CPHI1 = DUE / RHO * DX * TPHI / 2
        CPHI2 = CPHI1 / 12.0 * DX2 * (9 * TT * (1 - TPHI2) - 4 * TT2 + 12 * TPHI2)
        let cdd = (8 * TT4 * (11 - 24 * TPHI2) - 12 * TT3 * (21 - 71 * TPHI2) + 15 * TT2 * (15 - 98 * TPHI2 + 15 * TPHI4) + 180 * TT * (5 * TPHI2 - 3 * TPHI4) + 360 * TPHI4)
        CPHI3 = CPHI1 / 360.0 * DX2 * DX2 * cdd
        CPHI4 = CPHI1 / 20160 * DX2 * DX2 * DX2 * (1385 + 3633 * TPHI2 + 4095 * TPHI4 + 1575 * TPHI2 * TPHI4)
        PHI = PHIF - CPHI1 + CPHI2 - CPHI3 + CPHI4
        
        // --- COMPUTE LONGITUDE
        CLAM1 = DX / cos(PHIF)
        CLAM2 = CLAM1 * DX2 / 6 * (TT + 2 * TPHI2)
        CLAM3 = CLAM1 * DX2 * DX2 / 120 * (TT2 * (9 - 68 * TPHI2) - 4 * TT3 * (1 - 6 * TPHI2) + 72 * TT * TPHI2 + 24 * TPHI4)
        CLAM4 = CLAM1 * DX2 * DX2 * DX2 / 5040 * (61 + 662 * TPHI2 + 1320 * TPHI4 + 720 * TPHI2 * TPHI4)
        FLAM = FLAM0 + CLAM1 - CLAM2 + CLAM3 - CLAM4
        
        // --- CONVERT TO DECIMAL DEGREES
        PHI = PHI / RAD
        FLAM = FLAM / RAD
        
        Result.setPhi(PHI)
        Result.setFlam(FLAM)
        return Result
    }
    /**
     * CONVERT GEODETIC COORDINTES TO HK METRIC GRID COORDINATES
     * @param IG: 1 FOR HAYFORD SPHEROID, 2 FOR WG282 SPHEROID
     * @param PHI: LATITUDE IN DECIMAL DEGREES
     * @param FLAM: LONGITUDE IN DECIMAL DEGREES
     * @param X : NORTHING (HK 1980 METRIC DATAM)
     * @param Y : EASTING (HK 1980 METRIC DATAM)
     * @return
     */
    
    func GEOHK(_ IG:Int, _ PHI:Double, _ FLAM:Double) -> GridData{
        var RAD, PHI0, FLAM0, RPHI:Double
        var RLAM, SM0, SM1, CJ:Double
        var TPHI, TPHI2, TPHI4, TPHI6:Double
        var TT, TT2, TT3, TT4:Double
        var XF, X1, X2, X3, X4:Double
        var YF, Y1, Y2, Y3:Double
        var WX, WY, a, b, C, D:Double
        var RHO, RMU:Double
        var X, Y:Double
        var Result =  GridData()
        var RadiusResult = RadiusData()
        
        RAD = pi/180.00
        
        // --- CONVERT PROJECTION ORIGIN TO RADIANS
        if (IG == 1) {
            PHI0 = ( 22 +  18 / 60 + 43.68 /  3600) * RAD
            FLAM0 = ( 114 +  10 / 60 + 42.8 /  3600) * RAD
        } else {
            PHI0 = ( 22 +  18 / 60 + 38.17 /  3600) * RAD
            FLAM0 = ( 114 +  10 / 60 + 51.65 /  3600) * RAD
        }
        
        // --- CONVERT LATITUDE AND LONGITUDE TO RADIANS
        
        RPHI = PHI * RAD
        RLAM = FLAM * RAD
        
        // --- COMPUTE MERIDIAN ARCS
        SM0 = SMER(Double(IG), 0, PHI0)
        SM1 = SMER(Double(IG), 0, RPHI)
        
        // --- COMPUTE RADII
        RadiusResult = RADIUS(Double(IG), RPHI)
        RHO = RadiusResult.rho
        RMU = RadiusResult.rmu
        
        // --- COMPUTE CJ (IN RADIANS)
        CJ = (RLAM - FLAM0) * cos(RPHI)
        TPHI = tan(RPHI)
        TPHI2 = TPHI * TPHI
        TPHI4 = TPHI2 * TPHI2
        TPHI6 = TPHI2 * TPHI4
        TT = RMU / RHO
        TT2 = pow(TT, 2)
        TT3 = pow(TT, 3)
        TT4 = pow(TT, 4)
        
        // --- COMPUTE NORTHING
        XF = SM1 - SM0
        X1 = RMU / 2 * pow(CJ, 2) * TPHI
        X2 = X1 / 12 * pow(CJ, 2) * (4 * TT2 + TT - TPHI2)
        X3 = X2
            / 30
            * pow(CJ, 2)
            * (8 * TT4 * (11 - 24 * TPHI2) - 28 * TT3 * (1 - 6 * TPHI2)
                + TT2 * (1 - 32 * TPHI2) - 2 * TT * TPHI2 + TPHI4)
        X4 = X3 / 56 * pow(CJ, 2)
            * (1385 - 3111 * TPHI2 + 543 * TPHI4 - TPHI6)
        X = XF + X1 + X2 + X3 + X4 + 819069.8
        
        // --- COMPUTE EASTING
        YF = RMU * CJ
        Y1 = YF / 6 * pow(CJ, 2)
        Y2 = Y1 / 20 * pow(CJ, 2)
        Y3 = Y2 / 42 * pow(CJ, 2)
        Y1 = Y1 * (TT - TPHI2)
        Y2 = Y2 * (4 * TT3 * (1 - 6 * TPHI2) + TT2 * (1 + 8 * TPHI2) - TT * 2
                    * TPHI2 + TPHI4)
        Y3 = Y3 * (61 - 479 * TPHI2 + 179 * TPHI4 - TPHI6)
        Y = YF + Y1 + Y2 + Y3 + 836694.05
        
        if (IG == 2) {
            WX = X
            WY = Y
            
            // --- TRANSFROM WGS84 GRID TO HK 1980 GRID
            a = 0.9999998373
            b = -0.000027858
            C = -23.098331
            D = 23.149765
            X = a * WX - b * WY + C
            Y = b * WX + a * WY + D
        }
        
        Result.setN(X)
        Result.setE(Y)
        return Result
        
    } // --- GEOHK
    /**
     * COMPUTE MERIDIAN ARC
     * @param IG: 1 FOR HAYFORD SPHEROID, 2 FOR WG282 SPHEROID
     * @param PHI0: LATITUDE OF ORIGIN
     * @param PHIF: LATITUDE OF PROJECTION TO CENTRAL MERIDIAN
     * @param SMER: MERIDIAN ARC
     * @return
     */
    
    func SMER(_ IG:Double, _ PHI0:Double, _ PHIF:Double) -> Double{
        var AXISM, FLAT, ECC:Double
        var a, b, C, D, DP0:Double
        var DP2:Double
        var DP4, DP6:Double
        var SMER:Double
        
        if (IG == 1) {
            AXISM = 6378388.00
            FLAT = 1.00 / 297.00
        } else {
            AXISM = 6378137.00
            FLAT = 1.00 / 298.2572235634
        }
        
        ECC = 2 * FLAT - pow(FLAT, 2)
        ECC = sqrt(ECC)
        a = 1 + 3/4 * pow(ECC, 2) + 45/64 * pow(ECC, 4) + 175/256 * pow(ECC, 6)
        b = 3/4 * pow(ECC, 2) + 15/16 * pow(ECC, 4) + 525/512 * pow(ECC, 6)
        C = 15/64 * pow(ECC, 4) + 105/256 * pow(ECC, 6)
        D = 35/512 * pow(ECC, 6)
        DP0 = PHIF - PHI0
        DP2 = sin(2 * PHIF) - sin(2 * PHI0)
        DP4 = sin(4 * PHIF) - sin(4 * PHI0)
        DP6 = sin(6 * PHIF) - sin(6 * PHI0)
        SMER = AXISM * (1 - pow(ECC, 2))
        SMER = SMER * (a * DP0 - b * DP2 / 2 + C * DP4 / 4 - D * DP6 / 6)
        
        return SMER
    } // --- SMER
    
    /**
     * COMPUTE RADII OF CURVATURE OF A GIVEN LATITUDE
     * @param IG: 1 FOR HAYFORD SPHEROID, 2 FOR WG282 SPHEROID
     * @param PHI: LATITUDE
     * @param RHO : RADIUS OF MERIDIAN
     * @param PMU : RADIUS OF PRIME VERTICAL
     * @return
     */
    func RADIUS(_ IG:Double, _ PHI: Double)->RadiusData {
        var AXISM, FLAT, ECC:Double
        var FAC:Double
        var RHO, RMU:Double
        
        let RadiusResult = RadiusData()
        
        if (IG == 1) {
            AXISM = 6378388.00
            FLAT = 1.00 / 297.00
        } else {
            AXISM = 6378137
            FLAT = 1.00 / 298.2572235634
        }
        ECC = 2 * FLAT - pow(FLAT, 2)
        FAC = 1 - ECC * (pow(sin(PHI), 2))
        RHO = AXISM * (1 - ECC) / pow(FAC, 1.5)
        RMU = AXISM / sqrt(FAC)
        
        RadiusResult.rho = RHO
        RadiusResult.rmu = RMU
        return RadiusResult
    } // --- Radius
    
}
