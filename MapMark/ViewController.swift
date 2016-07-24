//
//  ViewController.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/5/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit

class ViewController: UIViewController, MMBagsViewDelegate {
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle
    {
        return .LightContent
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
//        let vc = MMRootViewController()
//        self.presentViewController(vc, animated: false, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let bagsView = MMBagsView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        bagsView.delegate = self
        self.view.addSubview(bagsView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Bags View Delegate
    
    func presentCustomViewController(controller: UIViewController, animated: Bool, completion: () -> Void)
    {
        self.presentViewController(controller, animated: animated)
        {
            completion()
        }
    }
}

