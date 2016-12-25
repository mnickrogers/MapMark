//
//  NRGridCircleAnimation.swift
//  NRAnimators
//
//  Created by Nicholas Rogers on 4/23/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit

enum NRGridCircleAnimationColor
{
    case `default`
    case light
    case dark
}

class NRGridCircleAnimationView: UIView
{
    //MARK: Types
    
    //MARK: Internal Variables
    internal var animationColorType : NRGridCircleAnimationColor = .light { didSet { reloadImages() } }
    internal(set) var isAnimating = false
    
    //MARK: Private Variables
    fileprivate var outterView : UIImageView!
    fileprivate var middleView : UIImageView!
    fileprivate var innerView : UIImageView!
    fileprivate var shouldAnimate = false
    
    fileprivate var currentOutterRotation : CGFloat = 0.0
    fileprivate var currentMiddleRotation : CGFloat = 0.0
    
    //MARK: Initialization
    override init(frame: CGRect)
    {
        let customFrame = CGRect(x: frame.origin.x,
                                 y: frame.origin.y,
                                 width: 30,
                                 height: 30)
        super.init(frame: customFrame)
        
        outterView = UIImageView(frame: CGRect(x: 0, y: 0, width: customFrame.size.width, height: customFrame.size.height))
        middleView = UIImageView(frame: outterView.frame)
        innerView = UIImageView(frame: outterView.frame)
        
        reloadImages()
        
        self.addSubview(outterView)
        self.addSubview(middleView)
        self.addSubview(innerView)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Private Functions
    fileprivate func reloadImages()
    {
        var type : String
        switch animationColorType
        {
        case .default:
            fallthrough
        case .light:
            type = "light"
        case .dark:
            type = "dark"
        }
        outterView.image = UIImage(named: "concentric_circle_grid_outer_\(type).png")
        middleView.image = UIImage(named: "concentric_circle_grid_middle_\(type).png")
        innerView.image = UIImage(named: "concentric_circle_grid_center_\(type).png")
        
        if animationColorType == .default
        {
            outterView.image = outterView.image?.withRenderingMode(.alwaysTemplate)
            middleView.image = middleView.image?.withRenderingMode(.alwaysTemplate)
            innerView.image = innerView.image?.withRenderingMode(.alwaysTemplate)
        }
    }
    
    fileprivate func rotateViews()
    {
        currentOutterRotation += CGFloat(M_PI_2)
        currentMiddleRotation -= CGFloat(M_2_PI)
        UIView.animate(withDuration: 0.4,
                                   animations: {
                                    self.outterView.transform = CGAffineTransform(rotationAngle: self.currentOutterRotation)
                                    self.middleView.transform = CGAffineTransform(rotationAngle: self.currentMiddleRotation)
                                    self.alpha = 1.0
            }, completion: { (done) in
                if self.shouldAnimate
                {
                    self.rotateViews()
                }
                else
                {
                    self.resetRotations()
                }
        }) 
    }
    
    fileprivate func resetRotations()
    {
        UIView.animate(withDuration: 0.4, animations: {
            self.outterView.transform = CGAffineTransform(rotationAngle: 0.0)
            self.middleView.transform = CGAffineTransform(rotationAngle: 0.0)
        })
        
        currentOutterRotation = 0.0
        currentMiddleRotation = 0.0
    }
    
    //MARK: Internal Functions
    
    internal func startAnimating()
    {
        shouldAnimate = true
        isAnimating = true
        rotateViews()
    }
    
    internal func stopAnimating()
    {
        shouldAnimate = false
        isAnimating = false
    }
    
    internal func shrinkOff(_ completion:@escaping () -> Void)
    {
        shouldAnimate = false
        isAnimating = false
        resetRotations()
        UIView.animate(withDuration: 0.1,
                                   delay: 0.4,
                                   options: UIViewAnimationOptions.curveLinear,
                                   animations: {
                                    self.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
                                    self.alpha = 0.2
            }) { (done) in
                completion()
        }
    }
    
    internal func popOff(_ completion:@escaping () -> Void)
    {
        shouldAnimate = false
        isAnimating = false
        resetRotations()
        UIView.animate(withDuration: 0.1,
                                   delay: 0.4,
                                   options: UIViewAnimationOptions.curveLinear,
                                   animations: {
                                    self.outterView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                                    self.middleView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
                                    self.alpha = 0.0
        }) { (done) in
            completion()
        }
    }
    
    //MARK: Misc.
    
}
