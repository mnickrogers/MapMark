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
    
    var activityView: MMActivityIndicatorView?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.openLoadingView), name: MM_NOTIFICATION_OPEN_LOADING_VIEW, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.closeLoadingView), name: MM_NOTIFICATION_CLOSE_LOADING_VIEW, object: nil)
        
        let bagsView = MMBagsView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        bagsView.delegate = self
        self.view.addSubview(bagsView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func openLoadingView()
    {
        activityView = MMActivityIndicatorView(inFrame: self.view.frame)
        activityView!.titleLabel.text = "Loading Location"
        self.view.addSubview(activityView!)
        activityView?.open()
    }
    
    func closeLoadingView()
    {
        activityView?.close()
        activityView = nil
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

