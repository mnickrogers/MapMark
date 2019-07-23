//
//  MMStartScreenViewController.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/22/19.
//  Copyright © 2019 Nicholas Rogers. All rights reserved.
//

import UIKit

class MMStartScreenViewController: UIViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.black
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        MMSession.sharedSession.safeAreaInsets = self.view.safeAreaInsets
        
        let vc = ViewController()
        
        let _ = Timer.scheduledTimer(withTimeInterval: 0.5,
                                     repeats: false) { (timer) in
                                        self.present(vc,
                                                     animated: true,
                                                     completion: {
                                        })
        }
    }
}
