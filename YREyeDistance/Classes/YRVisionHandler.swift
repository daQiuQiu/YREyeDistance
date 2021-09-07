//
//  YRVisionHandler.swift
//  YRVisionHandler
//
//  Created by 易仁 on 2021/8/23.
//

import UIKit
import Vision
import AVKit


@available(iOS 12.0, *)
class YRVisionHandler: NSObject {
    
    lazy var cameraView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        view.frame = CGRect(x: -310, y: -543, width: 300, height: 533)
        return view
    }()
    
    var fovFactor:Float = 0 //视角系数
    var eyeDistance: Float = 0 //双眼像素距离
    var clap: CGRect = CGRect.zero //原始分辨率
    var fLength: Float = 31 //默认32  30-32
    var realEyeDistance: Float = 63 //默认双眼距离 mm
    var upScale: Float = 0
    var frequencyCount = 0
    
    //video source
    var captureQueue: DispatchQueue?
    var currentOutput: AVCaptureVideoDataOutput?
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    //status
    var currentOrientation: AVCaptureVideoOrientation? //视频方向
    var useCamera = false //sdk是否占用摄像头
    var stop = false //是否已停止
    
    //指定用户年龄
    func setupPupilDistance(_ age: Int) {
        self.realEyeDistance = getPupilDistance(age)
    }
    
    //设置preview
    func setupPreview() {
        DispatchQueue.main.async {
            self.stop = false
            if self.useCamera {
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession!)
                //            self.previewLayer = AVCaptureVideoPreviewLayer()
            } else {
                self.previewLayer = AVCaptureVideoPreviewLayer()
            }
            self.previewLayer?.frame = CGRect(x: 0, y: 0, width: self.cameraView.frame.width, height: self.cameraView.frame.height)
            self.previewLayer?.videoGravity = .resizeAspect
            self.cameraView.layer.addSublayer(self.previewLayer!)
            
            UIApplication.shared.keyWindow?.rootViewController?.view.addSubview(self.cameraView)

        }
    }
    
    //sdk不占用摄像头 CGImage
    func startWithoutCamera(image: CGImage, device: AVCaptureDevice) {
        if self.fovFactor == 0 {
            self.setupPreview()
            self.processFOV(device: device)
        }
        self.startVisionRequest(image: image)
    }
    
    //sdk不占用摄像头 CMSampleBuffer
    func startWithoutCamera(sampleBuffer: CMSampleBuffer, device: AVCaptureDevice) {
        if self.fovFactor == 0 {
            self.setupPreview()
            self.processFOV(device: device)
        }
        guard let buffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)else {
            return
        }
        self.startVisionRequest(pixelBuffer: buffer)
    }
    
    //sdk不占用摄像头 pixelBuffer
    func startWithoutCamera(pixelBuffer: CVPixelBuffer, device: AVCaptureDevice) {
        if self.fovFactor == 0 {
            self.setupPreview()
            self.processFOV(device: device)
        }
        
        self.startVisionRequest(pixelBuffer: pixelBuffer)
    }
    
    //sdk占用摄像头
    func startUsingCamera() {
        if !checkCameraPermission() {
            return
        }
        
        self.useCamera = true
        self.captureSession = AVCaptureSession()
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {return}
        let input = try? AVCaptureDeviceInput(device: device)
        captureSession?.addInput(input!)
        self.setupPreview()
        self.currentOutput = AVCaptureVideoDataOutput()
        guard let output = self.currentOutput else {return}
        self.captureQueue = DispatchQueue(label: "YRVideoQueue")
        output.setSampleBufferDelegate(self, queue: self.captureQueue)
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        captureSession?.addOutput(output)
        self.processFOV(device: device)
        //启动
        captureSession?.startRunning()
    }
    
    //停止检测
    func stopDetect() {
        self.cameraView.removeFromSuperview()
        if useCamera {
            currentOutput?.setSampleBufferDelegate(nil, queue: nil)
            captureQueue?.async { [weak self] in
                self?.captureSession?.stopRunning()
            }
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                self.captureQueue = nil
                self.captureSession = nil
            }
            self.useCamera = false
        } else {
            DispatchQueue.main.async {
                if self.previewLayer?.superlayer != nil {
                    self.previewLayer?.removeFromSuperlayer()
                }
            }
        }
        self.stop = true
        self.currentOrientation = nil
        self.fovFactor = 0
        self.upScale = 0
        self.frequencyCount = 0
    }
    
    //发起vision请求 使用cgimage
    func startVisionRequest(image: CGImage) {
        if YREyeDistanceKit.shared.detectPause {
            return
        }
        
        let handler = VNImageRequestHandler(cgImage: image, orientation: .downMirrored, options: [:])
        let faceRequest = VNDetectFaceLandmarksRequest.init { [weak self] (vnRequest, _) in
            //            print("提取成功 = \(vnRequest.results)")
            if let result = vnRequest.results as? [VNFaceObservation] {
                self?.processLandmarks(faces: result)
            } else {
                
            }
        }
        faceRequest.preferBackgroundProcessing = true
        try? handler.perform([faceRequest])
    }
    
    //发起vision请求
    func startVisionRequest(pixelBuffer: CVPixelBuffer) {
        if YREyeDistanceKit.shared.detectPause {
            return
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .downMirrored, options: [:])
        let faceRequest = VNDetectFaceLandmarksRequest.init { [weak self] (vnRequest, _) in
            //            print("提取成功 = \(vnRequest.results)")
            if let result = vnRequest.results as? [VNFaceObservation] {
                self?.processLandmarks(faces: result)
            } else {
                
            }
        }
        faceRequest.preferBackgroundProcessing = true
        
        try? handler.perform([faceRequest])
    }
    
    //计算距离
    func processLandmarks(faces: [VNFaceObservation]) {
        if faces.count == 0 {
            print("NO FACE")
            if YREyeDistanceKit.shared.delegate != nil {
                YREyeDistanceKit.shared.delegate?.noFaceDetected?()
            }
            return
        }
        
        guard let preview = self.previewLayer else {return}
        //默认第一张脸
        let firstFace = faces[0]
        
        var faceBoxOnscreen = preview.layerRectConverted(fromMetadataOutputRect: firstFace.boundingBox)
        
        if !useCamera {
            faceBoxOnscreen = CGRect(x: preview.frame.width * firstFace.boundingBox.origin.y, y: preview.frame.height * firstFace.boundingBox.origin.x, width: preview.frame.width * firstFace.boundingBox.size.height, height: preview.frame.height * firstFace.boundingBox.size.width)
        }

        let x = faceBoxOnscreen.origin.x
        let y = faceBoxOnscreen.origin.y
        let w = faceBoxOnscreen.size.width
        let h = faceBoxOnscreen.size.height
        
        //左眼球
        if let leftPupil = firstFace.landmarks?.leftPupil {
            
            //右眼球
            if let rightPupil = firstFace.landmarks?.rightPupil {
                
                guard let leftEyePoint = leftPupil.normalizedPoints.first else { return }
                guard let rightEyePoint = rightPupil.normalizedPoints.first else { return }
                
                let leftX = leftEyePoint.y * h + x
                let rightX = rightEyePoint.y * h + x
                
                let leftY = leftEyePoint.x * w + y
                let rightY = rightEyePoint.x * w + y
                
                self.eyeDistance = sqrtf(powf(Float(leftX - rightX), 2) + powf(Float(leftY - rightY), 2))
            }
        }
        
        //偏转处理
        var distanceAngle: Float = 0
        var distance: Float = 0
        if UIDevice.current.orientation.isLandscape {
            distance = (1.0 + self.realEyeDistance * Float(self.previewLayer!.frame.width) / 24 / (self.eyeDistance)) * self.fLength / 10.0 * self.fovFactor
        } else {
            distance = (1.0 + self.realEyeDistance * Float(self.previewLayer!.frame.height) / 36 / (self.eyeDistance)) * self.fLength / 10.0 * self.fovFactor
        }
        if abs(firstFace.yaw!.floatValue) < 2.0 && abs(firstFace.yaw!.floatValue) > 0 {
            //                self.eyeDistance = self.eyeDistance / 0.707
            distanceAngle = (1.0 + self.realEyeDistance * Float(self.previewLayer!.frame.width) / 24 / (self.eyeDistance / 0.707)) * self.fLength / 10.0 * self.fovFactor
        }
        
        if self.stop { //已停止检测
            return
        }
        
        DispatchQueue.main.async {
            if distance < YREyeDistanceKit.shared.alertDistance && distance > 10.0 {
                print("距离警告")
                if YREyeDistanceKit.shared.delegate != nil {
                    YREyeDistanceKit.shared.delegate?.currentDistance?(isAlert: true, currentDistance: distance)
                }
            } else {
                if YREyeDistanceKit.shared.delegate != nil {
                    YREyeDistanceKit.shared.delegate?.currentDistance?(isAlert: false, currentDistance: distance)
                }
            }
        }
    }
    
    func processFOV(device: AVCaptureDevice) {
        let currentFOV = device.activeFormat.videoFieldOfView
        if let basicFov = device.formats.last?.videoFieldOfView {
            self.fovFactor = currentFOV / basicFov
            print("最小fov = \(basicFov) 当前 = \(currentFOV) fovFactor = \(self.fovFactor) upScale = \(self.upScale)")
        }
        self.upScale = Float(device.activeFormat.videoZoomFactorUpscaleThreshold)
    }
}

@available(iOS 12.0, *)
extension YRVisionHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        print("vision frame count = \(self.frequencyCount)")
        if self.frequencyCount >= YREyeDistanceKit.shared.detectFrequency {
            self.frequencyCount = 0
            guard let buffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)else {
                return
            }
            self.startVisionRequest(pixelBuffer: buffer)
        } else {
            self.frequencyCount += 1
        }
    }
    
    //权限
    func checkCameraPermission() -> Bool {
        let mediaType = AVMediaType.video
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: mediaType)
        switch authorizationStatus {
        case .notDetermined:  //用户尚未做出选择
            AVCaptureDevice.requestAccess(for: .video) { (success) in
                
                if success {
                    DispatchQueue.main.async {
                        self.startUsingCamera()
                    }
                } else {
                    
                }
            }
            return false
        case .authorized:  //已授权
            return true
        case .denied:  //用户拒绝
            print("权限拒绝")
            
            return false
        case .restricted:  //家长控制
            return false
        }
    }
}
