//
//  UseCameraViewController.swift
// 
//
//  Created by nigel on 2020/6/12.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import YREyeDistance

class UseCameraViewController: UIViewController, YREyeDistanceProtocol {

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

        // Do any additional setup after loading the view.
        self.view.backgroundColor = .darkGray
        
        self.view.addSubview(self.backBtn)
        self.backBtn.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(self.view.snp.bottom).offset(-100)
            make.size.equalTo(CGSize(width: 100, height: 50))
        }
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 12.0, *) {
            YREyeDistanceKit.setDetectFrequency(frequency: 50)
            YREyeDistanceKit.setDelegate(delegate: self)
            YREyeDistanceKit.startDetectWithCamera()
        } else {
            // Fallback on earlier versions
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if #available(iOS 12.0, *) {
            YREyeDistanceKit.stopDetect()
        } else {
            // Fallback on earlier versions
        }
    }
    
    func currentDistance(isAlert: Bool, currentDistance: Float) {
        print("useCam delegate 距离 = \(currentDistance) ")
    }
    
    @objc func back() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait]
    }
    
    

}
