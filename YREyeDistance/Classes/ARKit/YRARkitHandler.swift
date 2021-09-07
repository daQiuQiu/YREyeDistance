//
//  YRARkitHandler.swift
//  YRARkitHandler
//
//  Created by 易仁 on 2021/8/23.
//

import UIKit
import ARKit

@available(iOS 12.0, *)
class YRARkitHandler: NSObject {
    var faceNode = SCNNode()
    var leftEye = SCNNode()
    var rightEye = SCNNode()
    var frequencyCount = 0
    
    lazy var sceneView: ARSCNView = {
        let view = ARSCNView()
        view.frame = CGRect(x: -300, y: -600, width: 300, height: 600)
        view.isHidden = false
        return view
    }()
    
    func stopDetect() {
        self.sceneView.session.pause()
        self.sceneView.removeFromSuperview()
        self.frequencyCount = 0
    }
    
    //开始检测
    func startDetect() {
        //设备不支持
        if !checkARSupport() {
            return
        }
        
        if !checkCameraPermission() {
            print("无相机权限")
            return
        }
        
        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = true
        
        UIApplication.shared.keyWindow?.rootViewController?.view.addSubview(self.sceneView)
        
        self.sceneView.delegate = self
        self.sceneView.showsStatistics = true
        self.sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        
        setupEyeNode()
    }
    
    func setupEyeNode() {
        let eyeGeometry = SCNSphere(radius: 0.005)
        eyeGeometry.materials.first?.diffuse.contents = UIColor.green
        eyeGeometry.materials.first?.transparency = 1.0
        
        let node = SCNNode()
        node.geometry = eyeGeometry
        node.eulerAngles.x = -.pi / 2
        node.position.z = 0.1
        
        leftEye = node.clone()
        rightEye = node.clone()
    }
    
    func trackDistance() {
        DispatchQueue.main.async {

            let leftEyeDistanceFromCamera = self.leftEye.worldPosition - SCNVector3Zero
            let rightEyeDistanceFromCamera = self.rightEye.worldPosition - SCNVector3Zero

            //计算左右平均距离
            let averageDistance = (leftEyeDistanceFromCamera.length() + rightEyeDistanceFromCamera.length()) / 2
            
            let averageDistanceCM = averageDistance * 100
            
            DispatchQueue.main.async {
                if averageDistanceCM < YREyeDistanceKit.shared.alertDistance && averageDistance > 10.0 {
                    if YREyeDistanceKit.shared.delegate != nil {
                        YREyeDistanceKit.shared.delegate?.currentDistance?(isAlert: true, currentDistance: averageDistanceCM)
                    }
                    
                }else {
                    if YREyeDistanceKit.shared.delegate != nil {
                        YREyeDistanceKit.shared.delegate?.currentDistance?(isAlert: false, currentDistance: averageDistanceCM)
                    }
                }
            }
            
        }
    }
    
    //检测是否支持ARKit
    func checkARSupport() -> Bool {
        return ARFaceTrackingConfiguration.isSupported
    }
    
    //权限
    func checkCameraPermission() -> Bool{
        let mediaType = AVMediaType.video
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: mediaType)
        switch authorizationStatus {
        case .notDetermined:  //用户尚未做出选择
            AVCaptureDevice.requestAccess(for: .video) { (success) in
                
                if success {
                    DispatchQueue.main.async {
                        self.startDetect()
                    }
                }else {
                    
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

@available(iOS 12.0, *)
extension YRARkitHandler: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        //setup node eye and face
        self.faceNode = node
        
        guard let device = self.sceneView.device else { return }
        let faceGeo = ARSCNFaceGeometry(device: device)
        self.faceNode.geometry = faceGeo
//        self.faceNode.geometry?.firstMaterial?.fillMode = .lines
        self.faceNode.addChildNode(self.leftEye)
        self.faceNode.addChildNode(self.rightEye)
        self.faceNode.transform = node.transform
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if YREyeDistanceKit.shared.detectPause {
            return
        }
        if self.frequencyCount >= YREyeDistanceKit.shared.detectFrequency {
            self.frequencyCount = 0
            self.faceNode.transform = node.transform
            self.faceNode.geometry?.materials.first?.diffuse.contents = UIColor.yellow
            //update node
            guard let faceAnchor = anchor as? ARFaceAnchor else {
                print("NO FACE")
                return
            }
            
            if let faceGeo = node.geometry as? ARSCNFaceGeometry {
                faceGeo.update(from: faceAnchor.geometry)
            }
            leftEye.simdTransform = faceAnchor.leftEyeTransform
            rightEye.simdTransform = faceAnchor.rightEyeTransform
            //获取距离
            trackDistance()
        }else {
            self.frequencyCount += 1
        }
    }
}

extension SCNVector3{

    ///The Length Of Vector
    func length() -> Float { return sqrtf(x * x + y * y + z * z) }

    ///Subtract Two SCNVector3's
    static func - (l: SCNVector3, r: SCNVector3) -> SCNVector3 { return SCNVector3Make(l.x - r.x, l.y - r.y, l.z - r.z) }
}
