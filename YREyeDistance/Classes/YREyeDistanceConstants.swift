//
//  YREyeDistanceConstants.swift
//  YREyeDistanceConstants
//
//  Created by 易仁 on 2021/8/23.
//

import Foundation

//pad判断
func isPad() -> Bool {
    return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
}

//Constants
public let kScreenHeight = UIScreen.main.bounds.size.height
public let kScreenWidth = UIScreen.main.bounds.size.width
public let kWidthRate = !isPad() ? UIScreen.main.bounds.size.width / 375.0 : kPadWidthRate
public let kHeightRate = !isPad() ? UIScreen.main.bounds.size.height / 667.0 : kPadHeightRate
public let kHoriWidthRate = !isPad() ? UIScreen.main.bounds.size.height / 375.0 : kPadHoriWidthRate
public let kHoriHeightRate = !isPad() ? UIScreen.main.bounds.size.width / 667.0 : kPadHoriHeightRate

//pad
public let kPadWidthRate = UIScreen.main.bounds.size.width / 768.0
public let kPadHeightRate = UIScreen.main.bounds.size.height / 1024.0
public let kPadHoriWidthRate = UIScreen.main.bounds.size.height / 768.0
public let kPadHoriHeightRate = UIScreen.main.bounds.size.width / 1024.0

public let isIphoneX = kScreenHeight >= 812 ? true : false
public let isHoriIphoneX = kScreenWidth >= 812 ? true : false

//get date
func getDate() -> String {
    let date = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let dateStr = formatter.string(from: date)
    
    return dateStr
}

// 获取对应年龄的瞳距
func getPupilDistance(_ age: Int) -> Float {
    if age < 4 && age > 0 { //0 - 4
        return 45
    } else if age >= 4 && age <= 7 { // 4 - 7
        return 50
    } else if age >= 8 && age <= 11 {// 8 - 11
        return 56
    } else if age >= 12 && age <= 16 {//12 - 16
        return 59
    } else if age > 16 { // > 17
        return 63
    }
    
    return 63 //默认值
}

//警示距离
func getAlertDistance() -> Float {
    if isPad() {
        if UIApplication.shared.statusBarOrientation.isLandscape {
            return 45 * Float(kHoriWidthRate)
        } else {
            return 45 * Float(kWidthRate)
        }
    } else {
        if UIApplication.shared.statusBarOrientation.isLandscape {
            return 30 * Float(kHoriWidthRate)
        } else {
            return 30 * Float(kWidthRate)
        }
    }
}
