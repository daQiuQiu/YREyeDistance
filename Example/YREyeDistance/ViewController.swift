//
//  ViewController.swift
//  YREyeDistance
//
//  Created by yiren on 08/23/2021.
//  Copyright (c) 2021 yiren. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    lazy var vnBtn: UIButton = {
        let btn = UIButton()
        btn.layer.cornerRadius = 24
        btn.setTitle("sdk无法占用摄像头", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18)
        btn.layer.borderColor = UIColor.white.cgColor
        btn.layer.borderWidth = 1.0
        btn.addTarget(self, action: #selector(detectWithoutCamera), for: .touchUpInside)
        btn.titleLabel?.textColor = .white
        
        return btn
    }()
    
    lazy var arBtn: UIButton = {
        let btn = UIButton()
        btn.layer.cornerRadius = 24
        btn.setTitle("sdk占用摄像头", for: .normal)
        btn.layer.borderColor = UIColor.white.cgColor
        btn.layer.borderWidth = 1.0
        btn.titleLabel?.font = .systemFont(ofSize: 18)
        btn.titleLabel?.textColor = .white
        btn.addTarget(self, action: #selector(detectWithCamera), for: .touchUpInside)
        return btn
    }()
    
    lazy var photoBtn: UIButton = {
        let btn = UIButton()
        btn.layer.cornerRadius = 24
        btn.setTitle("拍照", for: .normal)
        btn.layer.borderColor = UIColor.white.cgColor
        btn.layer.borderWidth = 1.0
        btn.titleLabel?.font = .systemFont(ofSize: 18)
        btn.titleLabel?.textColor = .white
//        btn.addTarget(self, action: #selector(goToPhoto), for: .touchUpInside)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        self.view.backgroundColor = .darkGray
        // Do any additional setup after loading the view.
        
        self.view.addSubview(self.vnBtn)
        self.view.addSubview(self.arBtn)
        
        setupUI()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupUI()
    }
    
    func setupUI () {
        self.arBtn.frame = CGRect(x: 0, y: 0, width: 200, height: 60)
        self.vnBtn.frame = CGRect(x: 0, y: 0, width: 200, height: 60)
        self.photoBtn.frame = CGRect(x: 0, y: 0, width: 200, height: 60)
        self.arBtn.center = CGPoint(x: self.view.center.x, y: self.view.center.y + 100)
        self.vnBtn.center = CGPoint(x: self.view.center.x, y: self.view.center.y - 100)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    @objc func detectWithoutCamera() {
        let vc = NoCameraViewController()
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc func detectWithCamera() {
        let vc = UseCameraViewController()
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: 方向控制
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.all]
    }

}

