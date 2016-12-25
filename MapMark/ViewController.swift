//
//  ViewController.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/5/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MMBagsViewDelegate
{
    override var preferredStatusBarStyle : UIStatusBarStyle
    {
        return .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
//        let vc = MMRootViewController()
//        self.presentViewController(vc, animated: false, completion: nil)
    }
    
    var activityView: MMActivityIndicatorView?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.openLoadingView), name: NSNotification.Name(rawValue: MM_NOTIFICATION_OPEN_LOADING_VIEW), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.closeLoadingView), name: NSNotification.Name(rawValue: MM_NOTIFICATION_CLOSE_LOADING_VIEW), object: nil)
        
        let bagsView = MMBagsView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        bagsView.delegate = self
        self.view.addSubview(bagsView)
        
//        let pins = fetchPinsNearLocation(CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437), radius: 150)
//        
//        for item in pins!
//        {
//            print(item)
//        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self)
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
    
    func presentCustomViewController(_ controller: UIViewController, animated: Bool, completion: @escaping () -> Void)
    {
        self.present(controller, animated: animated)
        {
            completion()
        }
    }
}

