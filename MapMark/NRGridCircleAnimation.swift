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
    case Default
    case Light
    case Dark
}

class NRGridCircleAnimationView: UIView
{
    //MARK: Types
    
    //MARK: Internal Variables
    internal var animationColorType : NRGridCircleAnimationColor = .Light { didSet { reloadImages() } }
    internal(set) var isAnimating = false
    
    //MARK: Private Variables
    private var outterView : UIImageView!
    private var middleView : UIImageView!
    private var innerView : UIImageView!
    private var shouldAnimate = false
    
    private var currentOutterRotation : CGFloat = 0.0
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
    private func reloadImages()
    {
        var type : String
        switch animationColorType
        {
        case .Default:
            fallthrough
        case .Light:
            type = "light"
        case .Dark:
            type = "dark"
        }
        outterView.image = UIImage(named: "concentric_circle_grid_outer_\(type).png")
        middleView.image = UIImage(named: "concentric_circle_grid_middle_\(type).png")
        innerView.image = UIImage(named: "concentric_circle_grid_center_\(type).png")
        
        if animationColorType == .Default
        {
            outterView.image = outterView.image?.imageWithRenderingMode(.AlwaysTemplate)
            middleView.image = middleView.image?.imageWithRenderingMode(.AlwaysTemplate)
            innerView.image = innerView.image?.imageWithRenderingMode(.AlwaysTemplate)
        }
    }
    
    private func rotateViews()
    {
        currentOutterRotation += CGFloat(M_PI_2)
        currentMiddleRotation -= CGFloat(M_2_PI)
        UIView.animateWithDuration(0.4,
                                   animations: {
                                    self.outterView.transform = CGAffineTransformMakeRotation(self.currentOutterRotation)
                                    self.middleView.transform = CGAffineTransformMakeRotation(self.currentMiddleRotation)
                                    self.alpha = 1.0
            }) { (let done) in
                if self.shouldAnimate
                {
                    self.rotateViews()
                }
                else
                {
                    self.resetRotations()
                }
        }
    }
    
    private func resetRotations()
    {
        UIView.animateWithDuration(0.4)
        {
            self.outterView.transform = CGAffineTransformMakeRotation(0.0)
            self.middleView.transform = CGAffineTransformMakeRotation(0.0)
        }
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
    
    internal func shrinkOff(completion:() -> Void)
    {
        shouldAnimate = false
        isAnimating = false
        resetRotations()
        UIView.animateWithDuration(0.1,
                                   delay: 0.4,
                                   options: UIViewAnimationOptions.CurveLinear,
                                   animations: {
                                    self.transform = CGAffineTransformMakeScale(0.3, 0.3)
                                    self.alpha = 0.2
            }) { (let done) in
                completion()
        }
    }
    
    internal func popOff(completion:() -> Void)
    {
        shouldAnimate = false
        isAnimating = false
        resetRotations()
        UIView.animateWithDuration(0.1,
                                   delay: 0.4,
                                   options: UIViewAnimationOptions.CurveLinear,
                                   animations: {
                                    self.outterView.transform = CGAffineTransformMakeScale(1.2, 1.2)
                                    self.middleView.transform = CGAffineTransformMakeScale(0.3, 0.3)
                                    self.alpha = 0.0
        }) { (let done) in
            completion()
        }
    }
    
    //MARK: Misc.
    
}
