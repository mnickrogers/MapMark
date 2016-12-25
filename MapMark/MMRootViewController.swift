//
//  MMRootViewController.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/6/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit

class MMRootViewController: ViewController
{
    // MARK: Initialization
    
    override var preferredStatusBarStyle : UIStatusBarStyle
    {
        return .lightContent
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let bagsView = MMBagsView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        self.view.addSubview(bagsView)
    }
}
