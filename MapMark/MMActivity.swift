//
//  MMActivity.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/26/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit

class MMActivityIndicatorView: UIView
{
    // MARK: - Internal Types and Variables
    
    internal var titleLabel: UILabel!
    
    // MARK: - Private Types and Variables
    
    fileprivate var titleFrame: CGRect
    {
        set
        {
            self.titleFrame = newValue
        }
        get
        {
            return CGRect(x: 0, y: 5, width: 200, height: 25)
        }
    }
    fileprivate var loadingAnimator: NRGridCircleAnimationView!
    
    // MARK: - Initialization
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        let bgViewEffect = UIBlurEffect(style: .dark)
        let bgEffectView = UIVisualEffectView(effect: bgViewEffect)
        bgEffectView.frame = CGRect().zeroBoundedRect(self.frame)
        self.addSubview(bgEffectView)
        
        let topDiv = CALayer()
        topDiv.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: 0.5)
        topDiv.backgroundColor = UIColor.lightGray.cgColor
        topDiv.opacity = 0.4
        
        titleLabel = UILabel(frame: titleFrame)
        titleLabel.center = CGPoint(x: frame.size.width / 2, y: titleLabel.center.y)
        titleLabel.font = UIFont(name: MM_FONT_MEDIUM, size: 22)
        titleLabel.textAlignment = .center
        titleLabel.textColor = MM_COLOR_GREEN_DARK
        titleLabel.adjustsFontSizeToFitWidth = true
        
        loadingAnimator = NRGridCircleAnimationView(frame: CGRect.zero)
        loadingAnimator.center = CGPoint(x: frame.size.width / 2, y: (frame.size.height / 2) + 13)
        loadingAnimator.animationColorType = .default
        loadingAnimator.tintColor = MM_COLOR_GREEN_DARK
        
        self.layer.addSublayer(topDiv)
        self.addSubview(titleLabel)
        self.addSubview(loadingAnimator)
    }
    
    convenience init(inFrame: CGRect)
    {
        self.init(frame: CGRect(x: 0, y: inFrame.size.height, width: inFrame.size.width, height: 70))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Loading and unloading
    
    internal func open()
    {
        self.alpha = 0
//        self.transform = CGAffineTransformMakeScale(0.9, 0.9)
        UIView.animate(withDuration: 0.2,
                                   delay: 0,
                                   options: UIViewAnimationOptions.curveEaseOut,
                                   animations: {
//                                    self.transform = CGAffineTransformMakeScale(1, 1)
                                    self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y - self.frame.size.height, width: self.frame.size.width, height: self.frame.size.height)
                                    self.alpha = 1
            }) { (completed) in
        }
        loadingAnimator.startAnimating()
    }
    
    internal func close(_ shouldDelete: Bool = true)
    {
        loadingAnimator.stopAnimating()
        UIView.animate(withDuration: 0.2,
                                   delay: 1,
                                   options: UIViewAnimationOptions.curveEaseOut,
                                   animations: {
                                    self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y + self.frame.size.height, width: self.frame.size.width, height: self.frame.size.height)
//                                    self.transform = CGAffineTransformMakeScale(0.8, 0.8)
                                    self.alpha = 0
        }) { (completed) in
            if completed && shouldDelete
            {
                self.removeFromSuperview()
            }
        }
    }
}
