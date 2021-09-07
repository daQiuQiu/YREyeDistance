//
//  NoCameraViewController.swift
//
//
//  Created by nigel on 2020/6/12.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import YREyeDistance
import AVKit
import SnapKit
import AVFoundation

class NoCameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, YREyeDistanceProtocol {
    var previewLayer: AVCaptureVideoPreviewLayer?
    var cameraView = UIView()
    let captureSession = AVCaptureSession()
    var input: AVCaptureDeviceInput?
    
    lazy var backBtn: UIButton = {
        let btn = UIButton()
        btn.frame = CGRect(x: 0, y: 0, width: 100, height: 50)
        btn.setTitle("返回", for: .normal)
        btn.backgroundColor = .darkText
        btn.addTarget(self, action: #selector(back), for: .touchUpInside)
        
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .gray
        self.cameraView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        self.cameraView.center = self.view.center
        self.cameraView.backgroundColor = .black
        
        self.view.addSubview(self.cameraView)
        self.view.addSubview(self.backBtn)
        self.backBtn.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(self.view.snp.bottom).offset(-100)
            make.size.equalTo(CGSize(width: 100, height: 50))
        }
        self.cameraView.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view)
            make.top.equalTo(self.view)
            make.size.equalTo(CGSize(width: 300, height: 300))
        }
        if #available(iOS 12.0, *) {
            YREyeDistanceKit.setDelegate(delegate: self)
            self.setupVideoCapture()
        } else {
            // Fallback on earlier versions
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
        if #available(iOS 12.0, *) {
            YREyeDistanceKit.stopDetect()
            
        } else {
            // Fallback on earlier versions
        }
    }
    
    @objc func back() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func setupVideoCapture() {
        let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        try? device?.lockForConfiguration()
        self.input = try? AVCaptureDeviceInput(device: device!)
        captureSession.addInput(input!)
        captureSession.sessionPreset = .medium
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//        self.previewLayer?.connection?.videoOrientation = .landscapeRight
        self.previewLayer?.frame = CGRect(x: 0, y: 0, width: self.cameraView.frame.width, height: self.cameraView.frame.height)
        //        self.previewLayer?.contentsGravity = .resizeAspectFit
        self.previewLayer?.videoGravity = .resizeAspectFill
        
        self.cameraView.layer.addSublayer(self.previewLayer!)
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        captureSession.addOutput(output)
        captureSession.startRunning()
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let device = self.input?.device else {return}
        if #available(iOS 12.0, *) {
            YREyeDistanceKit.startDetectWithoutCamera(sampleBuffer: sampleBuffer, device: device)
        } else {
            // Fallback on earlier versions
        }
    }
    
    //delegate
    func currentDistance(isAlert: Bool, currentDistance: Float) {
        print("delegate 收到警告 = \(isAlert) 距离 = \(currentDistance)")
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.all]
    }
    
    
}
