//
//  KalmanFilterFunction.swift
//  navigation
//
//  Created by 郑旭 on 2021/1/25.
//

import Foundation

class KalmanFilterFunction {
    func  Predict(_ X_k_1:Matrix, _ A: Matrix, _ P_k_1:Matrix, _ Q:Matrix) -> (Matrix,Matrix)? {
        //Matrix Pre_X = (A.times(X_k_1)).plus(B.times(U_k))
        do{
            let Pre_X = try (A.times(paramMatrix: X_k_1))
            let Pre_P = try ((A.times(paramMatrix: P_k_1)).times(paramMatrix: A.transpose())).plus(paramMatrix: Q)
            let result = (Pre_X,Pre_P)
            return  result
        }catch{
            print(error)
        }
        return nil
    }
    
    func  Total_d(_ X_k_1:Matrix, _ A:Matrix, _ P_k_1:Matrix, _ Q:Matrix, _ R:Matrix, _ C:Matrix, _ I:Matrix, _ Y_k:Matrix, _ Ed: inout Matrix, _ Edready:Bool) -> (Matrix,Matrix,Matrix)? {
        
        do{
            let Pre_X = try (A.times(paramMatrix:X_k_1))
            let Pre_P = try ((A.times(paramMatrix:P_k_1)).times(paramMatrix:A.transpose())).plus(paramMatrix:Q)
            
            let e = try Y_k.minus(paramMatrix:C.times(paramMatrix:Pre_X))
            let dk = try e.times(paramMatrix:e.transpose())
            Ed = try (Ed.plus(paramMatrix:dk)).times(paramDouble:0.01)
            if(Edready){
                Ed = try Ed.minus(paramMatrix: C.times(paramMatrix:Pre_P).times(paramMatrix: C.transpose()))
                R.set(paramInt1: 0,paramInt2: 0, paramDouble: Ed.get(paramInt1: 0,paramInt2: 0))
                R.set(paramInt1: 1,paramInt2: 1, paramDouble: Ed.get(paramInt1: 1,paramInt2: 1))
                R.set(paramInt1: 2,paramInt2: 2, paramDouble: Ed.get(paramInt1: 2,paramInt2: 2))
            }
            
            let K_k = try (Pre_P.times(paramMatrix: C.transpose())).times(paramMatrix: (((C.times(paramMatrix: Pre_P)).times(paramMatrix: C.transpose())).plus(paramMatrix: R)).inverse())
            let Update_X = try Pre_X.plus(paramMatrix: K_k.times(paramMatrix: e))
            let Update_P = try (I.minus(paramMatrix: K_k.times(paramMatrix: C))).times(paramMatrix: Pre_P)
            
            let filterResult = (Update_X, Update_P, dk)
            return filterResult
        }catch{
            print(error)
        }
        
        return nil
    }
    
    func Update(_ R: Matrix, _ C:Matrix,_ I:Matrix, _ Y_k:Matrix, _ result:(Matrix,Matrix))->(Matrix,Matrix)? {
        let Pre_X = result.0
        let Pre_P = result.1
        var Update_X=Pre_X
        var Update_P=Pre_P
        var filterResult = (Update_X,Update_P)
        let index=0 // hillday 这值写死了，switch有啥意思呢？？？
        do{
            switch (index) {
            case 0:
                let K_k = try (Pre_P.times(paramMatrix: C.transpose())).times(paramMatrix: (((C.times(paramMatrix: Pre_P)).times(paramMatrix: C.transpose())).plus(paramMatrix: R)).inverse())
                Update_X = try Pre_X.plus(paramMatrix: K_k.times(paramMatrix: Y_k.minus(paramMatrix: C.times(paramMatrix: Pre_X))))
                if(abs(Update_X.get(paramInt1: 3,paramInt2: 0))>3){
                    _ = 0
                }
                //Traditional P
                //                Update_P = (I.minus(K_k.times(C))).times(Pre_P)
                Update_P = try (I.minus(paramMatrix: K_k.times(paramMatrix: C))).times(paramMatrix: Pre_P).times(paramMatrix: (I.minus(paramMatrix: K_k.times(paramMatrix: C))).transpose()).plus(paramMatrix: K_k.times(paramMatrix: R).times(paramMatrix: K_k.transpose()))
                filterResult = (Update_X, Update_P)
                break
                
            case 1:
                // Get from paper
                let K_k = try (Pre_P.times(paramMatrix: C.transpose())).times(paramMatrix: (((C.times(paramMatrix: Pre_P)).times(paramMatrix: C.transpose())).plus(paramMatrix: R)).inverse())
                Update_X = try Pre_X.plus(paramMatrix: K_k.times(paramMatrix: Y_k.minus(paramMatrix: C.times(paramMatrix: Pre_X))))
                Update_P = try ((I.minus(paramMatrix: K_k.times(paramMatrix: C))).times(paramMatrix: Pre_P)).times(paramMatrix: ((I.minus(paramMatrix: K_k.times(paramMatrix: C)))).transpose()).plus(
                    paramMatrix: (K_k.times(paramMatrix: R)).times(paramMatrix: K_k.transpose()))
                filterResult = (Update_X, Update_P)
                break
                
            case 2:
                //UD decomposition
                let choleskyDecomposition = CholeskyDecomposition(paramMatrix: Pre_P)
                /// Is the matrix symmetric and positive definite
                if (choleskyDecomposition.isSPD()) {
                    let LD = LULT_Decomposition(Pre_P)
                    if (LD != nil) {
                        let U = LD!.0
                        let D = LD!.1
                        let UDupdatedXP = UpdateDecompositionUD_KP(U, D, C, R, Pre_X, Y_k)
                        Update_X = UDupdatedXP!.0
                        Update_P = UDupdatedXP!.1
                        filterResult = (Update_X, Update_P)
                    }
                   
                    break
                }
                
            case 3:
                ////SVD Decomosition
                let singularValueDecomposition = SingularValueDecomposition(paramMatrix: Pre_P)
                let U = singularValueDecomposition.getU()
                let S = singularValueDecomposition.getS()
                let V = singularValueDecomposition.getV()
                // P=USVt
                let UDupdatedXP = UpdateDecompositionSVD_KP(U, S, V, C, R, Pre_X, Y_k)
                Update_X = UDupdatedXP!.0
                Update_P = UDupdatedXP!.1
                filterResult = (Update_X, Update_P)
                break
                
            default:
                break
                
                
            }
            return filterResult
        }catch{
            print(error)
        }
        
        return filterResult
    }
    
    func LULT_Decomposition(_ P:Matrix)->(Matrix,Matrix)? {
        let row=P.getRowDimension()
        let column=P.getColumnDimension()
        var d = [[Double]]()
        var l = [[Double]]()
        for i in 0..<row {
            for j in 0..<column{
                d[i-1][j-1]=0
                l[i-1][j-1]=0
            }
        }
        for i in 0..<row{
            for j in 0..<column{
                if (i == j) {
                    if (i == 1) {
                        d[i - 1][j - 1] = P.get(paramInt1: 0, paramInt2: 0)
                    } else {
                        d[i - 1][j - 1] = CalculateDjj(P,d,l,j)
                    }
                    l[i - 1][j - 1] = 1
                }
                if(i<j){
                    d[i - 1][j - 1] = 0
                    l[i - 1][j - 1] = 0
                }
                
                if(i>j){
                    d[i - 1][j - 1] = 0
                    l[i - 1][j - 1] = CalculateLij(P,d,l,i,j)
                }
                
            }
        }
        do{
            let D = try Matrix(paramArrayOfDouble:d)
            let L = try Matrix(paramArrayOfDouble:l)
            let Result = (D,L)
            return Result
        }catch{
            print(error)
        }
        
        return nil
    }
    
    func CalculateDjj(_ P:Matrix,_ d:[[Double]],_ l:[[Double]], _ j:Int)->Double{
        var result_d=0.0
        let a_jj=P.get(paramInt1: j-1,paramInt2: j-1)
        var sum=0.0
        let size = j-1
        for k in 1..<size{
            sum=sum+l[j-1][k-1]*l[j-1][k-1]*d[k-1][k-1]
        }
        result_d=a_jj-sum
        return result_d
    }
    func CalculateLij(_ P:Matrix,_ d:[[Double]],_ l:[[Double]],_ i:Int, _ j:Int)->Double{
        var result_l = 0.0
        let a_ij=P.get(paramInt1: i-1,paramInt2: j-1)
        var sum = 0.0
        let size = j-1
        for k in 1..<size{
            sum=sum+l[i-1][k-1]*d[k-1][k-1]*l[j-1][k-1]
        }
        result_l=(a_ij-sum)*(1/d[j-1][j-1])
        return result_l
    }
    
    func UpdateDecompositionUD_KP(_ U:Matrix,_ D:Matrix,_ C:Matrix,_ R:Matrix,_ X_K_1:Matrix,_ Z:Matrix)->(Matrix,Matrix)? {
        do{
            let F = try(D.times(paramMatrix: U.transpose())).times(paramMatrix: C.transpose())
            let G = try U.times(paramMatrix: F)
            let S=try (C.times(paramMatrix: G)).plus(paramMatrix: R)
            let K = try G.times(paramMatrix: S.inverse())
            let X_K = try X_K_1.plus(paramMatrix: K.times(paramMatrix: Z.minus(paramMatrix: C.times(paramMatrix: X_K_1))))
            let P_K = try(U.times(paramMatrix: D.minus(paramMatrix: (F.times(paramMatrix: S.inverse())).times(paramMatrix: F.transpose())))).times(paramMatrix: U.transpose())
            let result=(X_K,P_K)
            return result
        }catch{
            print(error)
        }
        
        return nil
    }
    func UpdateDecompositionSVD_KP(_ U:Matrix,_ S:Matrix,_ V:Matrix,_ C:Matrix,_ R:Matrix,_ X_K_1:Matrix,_ Z:Matrix)->(Matrix,Matrix)? {
        do{
            let F = try (S.times(paramMatrix: V.transpose())).times(paramMatrix: C.transpose())
            let G = try U.times(paramMatrix: F)
            let S1 = try (C.times(paramMatrix: G)).plus(paramMatrix: R)
            let K = try G.times(paramMatrix: S1.inverse())
            let X_K = try X_K_1.plus(paramMatrix: K.times(paramMatrix: Z.minus(paramMatrix: C.times(paramMatrix: X_K_1))))
            let P_K = try U.times(paramMatrix: S.minus(paramMatrix: (F.times(paramMatrix: S1.inverse())).times(paramMatrix: C).times(paramMatrix: U).times(paramMatrix: S))).times(paramMatrix: V.transpose())
            let result = (X_K,P_K)
            return result
        }catch{
            print(error)
        }
        
        return nil
    }
}
