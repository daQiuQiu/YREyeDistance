//
//  YREyeDistanceKit.swift
//  YREyeDistance
//
//  Created by 易仁 on 2021/8/23.
//

import UIKit
import AVKit

@objc public protocol YREyeDistanceProtocol: NSObjectProtocol {
    //回调
    @objc optional func currentDistance(isAlert: Bool, currentDistance: Float)
    //无人脸
    @objc optional func noFaceDetected()
}

@available(iOS 12.0, *)
@objc public class YREyeDistanceKit: NSObject {
    
    var useARKit = false //是否使用arkit
    var detectPause = false //是否暂停检测
    var distancePause = false //是否只暂停距离检测
    var isOrientationNotiOpen = false //是否由SDK开启方向notification
    var alertDistance: Float = getAlertDistance() //警示距离 ipad 45 * iphone 30 *
    var detectFrequency = 20 //检测频率 每X帧检测一次 默认每20帧检测一次
    weak var delegate: YREyeDistanceProtocol?
    
    lazy var visionHandler: YRVisionHandler = {
        let handler = YRVisionHandler()
        
        return handler
    }()

    static let shared: YREyeDistanceKit = {
        let kit = YREyeDistanceKit()
        
        return kit
    }()
    
    fileprivate override init() {
        super.init()
        print("YREyeDistanceKit SDK init")
    }
    
    /**
     摄像头空闲，无摄像头业务使用，SDK将占用摄像头
    */
    @objc public class func startDetectWithCamera() {
        self.shared.useARKit = false
        self.shared.visionHandler.startUsingCamera()
    }
    
    /**
     摄像头在忙, 使用CGImage处理
     @param image 当前视频帧图片
     @param device 当前使用的AVCaptureDevice
    */
    @objc public class func startDetectWithoutCamera(image: CGImage, device: AVCaptureDevice) {
        self.shared.useARKit = false
        self.shared.visionHandler.startWithoutCamera(image: image, device: device)
    }
    
    /**
     摄像头在忙, 使用CMSampleBuffer处理
     @param sampleBuffer 当前视频帧
     @param device 当前使用的AVCaptureDevice
    */
    @objc public class func startDetectWithoutCamera(sampleBuffer: CMSampleBuffer, device: AVCaptureDevice) {
        self.shared.useARKit = false
        self.shared.visionHandler.startWithoutCamera(sampleBuffer: sampleBuffer, device: device)
    }
    
    /**
     摄像头在忙, 使用CVPixelBuffer处理
     @param pixelBuffer 当前视频帧
     @param device 当前使用的AVCaptureDevice
    */
    @objc public class func startDetectWithoutCamera(pixelBuffer: CVPixelBuffer, device: AVCaptureDevice) {
        self.shared.useARKit = false
        self.shared.visionHandler.startWithoutCamera(pixelBuffer: pixelBuffer, device: device)
    }
    
    /**
     停止检测
    */
    @objc public class func stopDetect() {
        self.shared.visionHandler.stopDetect()
        
        //移除监听方向
        NotificationCenter.default.removeObserver(self.shared)
    }
    
    /**
     设置delegate 用于实时获取距离
    */
    @objc public class func setDelegate(delegate: YREyeDistanceProtocol) {
        self.shared.delegate = delegate
    }
    
    /**
     是否推荐当前机型使用
    */
    @objc public class func checkSupportedModels() -> Bool {
        //可以处理一些过于老旧机型不响应，检测还是需要一部分性能的
        return true
    }
    
    /**
     修改检测频率
     
     @param frequency 每X帧检测一次 设置20 表示每20帧检测一次，默认为20
    */
    @objc public class func setDetectFrequency(frequency: Int) {
        assert(frequency > 0, "检测频率必须为正数")
        if frequency > 0 {
           self.shared.detectFrequency = frequency
        }
    }
    
    /**
     暂时隐藏提示框
     
     @param pause Bool 是否暂停 false 不暂停 true 暂停
    */
    @objc public class func pauseDetect(pause: Bool) {
        self.shared.detectPause = pause
        DispatchQueue.main.async {
            if pause == true {
                print("暂停检测")
            } else {
                print("回复检测")
            }
        }
    }
    
    /**
     指定用户年龄
     
     @param age Int 用户年龄
    */
    @objc public class func setUserAge(_ age: Int) {
        self.shared.visionHandler.setupPupilDistance(age)
    }
}
