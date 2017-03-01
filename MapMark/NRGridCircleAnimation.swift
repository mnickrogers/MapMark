//
//  NRGridCircleAnimation.swift
//  NRAnimators
//
//  Created by Nicholas Rogers on 4/23/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit

/// Animation style.
enum NRGridCircleAnimationColor
{
    case `default`
    case light
    case dark
}

/// A gear animation used to display activity.
class NRGridCircleAnimationView: UIView
{
    //MARK: Types
    
    //MARK: Internal Variables
    
    /// The gear animation's color style.
    internal var animationColorType : NRGridCircleAnimationColor = .light { didSet { reloadImages() } }
    /// A boolean indicating whether the gear is animating or not.
    internal(set) var isAnimating = false
    
    //MARK: Private Variables
    
    /// The outer sections of the gear.
    private var outterView : UIImageView!
    // The middle sections of the gear.
    private var middleView : UIImageView!
    /// The center sections of the gear.
    private var innerView : UIImageView!
    /// A boolean indicating if the gear should animate.
    private var shouldAnimate = false
    
    /// The current rotation of the outer sections of the gear.
    private var currentOutterRotation : CGFloat = 0.0
    /// The current rotation of the middle sections of the gear.
    private var currentMiddleRotation : CGFloat = 0.0
    
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
    
    /// Reload images when display settings are updated.
    private func reloadImages()
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
    
    /// Rotate the gear. Call this view to drive the animation.
    private func rotateViews()
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
    
    /// Reset the gear to its start position. Call this when the animation has ended.
    private func resetRotations()
    {
        UIView.animate(withDuration: 0.4, animations: {
            self.outterView.transform = CGAffineTransform(rotationAngle: 0.0)
            self.middleView.transform = CGAffineTransform(rotationAngle: 0.0)
        })
        
        currentOutterRotation = 0.0
        currentMiddleRotation = 0.0
    }
    
    //MARK: Internal Functions
    
    /// Begin animating the gear.
    internal func startAnimating()
    {
        shouldAnimate = true
        isAnimating = true
        rotateViews()
    }
    
    /// Stop animating the gear.
    internal func stopAnimating()
    {
        shouldAnimate = false
        isAnimating = false
    }
    
    /// Cause the gear to stop, shrink and disappear.
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
    
    /// Cause the gear to stop, pop off and disappear.
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
}
