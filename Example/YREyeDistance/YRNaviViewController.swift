//
//  YRNaviViewController.swift
//
//
//  Created by nigel on 2020/6/12.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit

class EPNaviViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override var shouldAutorotate: Bool {
        if let vc = self.topViewController {
            return vc.shouldAutorotate
        }else {
            return false
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let vc = self.topViewController {
            return vc.supportedInterfaceOrientations
        }else {
            return .all
        }
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        if let vc = self.topViewController {
            return vc.preferredInterfaceOrientationForPresentation
        }else {
            return .unknown
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if let vc = self.topViewController {
            return vc.preferredStatusBarStyle
        }else {
            return .default
        }
        
    }

}
