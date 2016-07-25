//
//  MMHeaderView.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/6/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit

protocol MMHeaderViewDelegate
{
    func headerViewTextChanged(string : String?)
}

class MMHeaderView: UIView, UITextFieldDelegate
{
    // MARK: Internal Types and Variables
    
    internal var delegate : MMHeaderViewDelegate?
    internal var headerText : String?
    {
        set
        {
            headerLabel.text = newValue
            self.resizeHeaderLabel()
        }
        get
        {
            return headerLabel.text
        }
    }
    internal var isTitleEditable: Bool
    {
        set
        {
            self.headerLabel.userInteractionEnabled = newValue
        }
        get
        {
            return self.headerLabel.userInteractionEnabled
        }
    }
    
    // MARK: Private Types and Variables
    
    private var headerLabel : UITextField!
    
    // MARK: Initialization
    
    override init(frame: CGRect)
    {
        super.init(frame: CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: 75))
        
        backgroundColor = UIColor.clearColor()
        let blurEffect = UIBlurEffect(style: .Dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.frame
        self.addSubview(blurEffectView)
        
        headerLabel = UITextField(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
        headerLabel.delegate = self
        headerLabel.font = UIFont(name: MM_FONT_MEDIUM, size: 32)
        headerLabel.textColor = MM_COLOR_GREEN_LIGHT
        headerLabel.textAlignment = .Center
        headerLabel.sizeToFit()
        headerLabel.userInteractionEnabled = true
        headerLabel.keyboardType = .Default
        headerLabel.keyboardAppearance = .Dark
        headerLabel.returnKeyType = .Done
        self.addSubview(headerLabel)
        
        let bottomDiv = CALayer()
        bottomDiv.frame = CGRect(x: 0, y: self.frame.size.height - 0.5, width: self.frame.size.width, height: 0.5)
        bottomDiv.backgroundColor = MM_COLOR_GREEN_DIV.CGColor
        self.layer.addSublayer(bottomDiv)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal func getHeaderLabelCenter() -> CGPoint
    {
        return CGPoint(x: self.center.x, y: self.center.y + 7)
    }
    
    private func resizeHeaderLabel()
    {
        headerLabel.sizeToFit()
        if headerLabel.frame.size.width > self.frame.size.width * 0.7
        {
            headerLabel.frame = CGRect(x: headerLabel.frame.origin.x, y: headerLabel.frame.origin.y, width: self.frame.size.width * 0.7, height: headerLabel.frame.size.height)
            headerLabel.adjustsFontSizeToFitWidth = true
        }
        else
        {
            headerLabel.adjustsFontSizeToFitWidth = false
        }
        headerLabel.center = getHeaderLabelCenter()
    }
    
    // MARK: Text Field Delegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        delegate?.headerViewTextChanged(textField.text)
        self.resizeHeaderLabel()
        return true
    }
}
