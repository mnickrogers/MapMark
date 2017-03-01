//
//  ViewController.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/5/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit
import MapKit

/*------------------------------------------------------*/
/* 
 "Pins" are collected into "bags." Users can move pins
 into bags. Pins have editable descriptions. A view for
 a single bag can route paths through all its pins, take
 entries for new pins based on latitude and longitude
 coordinates and take entries for new pins based on the 
 map.
                                                        */
/*------------------------------------------------------*/

class ViewController: UIViewController, MMBagsViewDelegate
{
    /// Set the preferred status bar color to be light.
    override var preferredStatusBarStyle : UIStatusBarStyle
    {
        return .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
    }
    
    /// Activity indicator for loading animation at bottom of home screen.
    var activityView: MMActivityIndicatorView?
    
    // Override viewDidLoad for main setup.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*----------------------------------------------*/
        /*
         The loading view displays at the bottom of the 
         screen and is used typically to handle actions
         from the 3D touch controls on the home screen.
                                                        */
        /*----------------------------------------------*/
        NotificationCenter.default.addObserver(self, selector: #selector(self.openLoadingView), name: NSNotification.Name(rawValue: MM_NOTIFICATION_OPEN_LOADING_VIEW), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.closeLoadingView), name: NSNotification.Name(rawValue: MM_NOTIFICATION_CLOSE_LOADING_VIEW), object: nil)
        
        // View for displaying the main bags.
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
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Open the loading view at the screen's bottom.
    func openLoadingView()
    {
        // Load the activity indicator if there are start-up operations to perform.
        activityView = MMActivityIndicatorView(inFrame: self.view.frame)
        activityView!.titleLabel.text = "Loading Location"
        self.view.addSubview(activityView!)
        activityView?.open()
    }
    
    /// Close the loading view at the screen's bottom.
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

