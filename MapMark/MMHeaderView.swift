//
//  MMHeaderView.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/6/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit

/// Delegate for handling changes from a header view.
protocol MMHeaderViewDelegate
{
    func headerViewTextChanged(_ string : String?)
}

/// View for displaying a default header view.
class MMHeaderView: UIView, UITextFieldDelegate
{
    // MARK: Internal Types and Variables
    
    /// Delegate for handling changes from this header view.
    internal var delegate : MMHeaderViewDelegate?
    /// The text for this header.
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
    /// Bool for determining if this header text is editable. Set this to false for most uses.
    internal var isTitleEditable: Bool
    {
        set
        {
            self.headerLabel.isUserInteractionEnabled = newValue
        }
        get
        {
            return self.headerLabel.isUserInteractionEnabled
        }
    }
    
    // MARK: Private Types and Variables
    
    /// The label for this header.
    private var headerLabel : UITextField!
    
    // MARK: Initialization
    
    override init(frame: CGRect)
    {
        super.init(frame: CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: 75))
        
        // Add a blur effect to the header.
        backgroundColor = UIColor.clear
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.frame
        self.addSubview(blurEffectView)
        
        // Set up the header label.
        headerLabel = UITextField(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
        headerLabel.delegate = self
        headerLabel.font = UIFont(name: MM_FONT_MEDIUM, size: 32)
        headerLabel.textColor = MM_COLOR_GREEN_LIGHT
        headerLabel.textAlignment = .center
        headerLabel.sizeToFit()
        headerLabel.isUserInteractionEnabled = true
        headerLabel.keyboardType = .default
        headerLabel.keyboardAppearance = .dark
        headerLabel.returnKeyType = .done
        self.addSubview(headerLabel)
        
        // Add a divider to the bottom of the header view.
        let bottomDiv = CALayer()
        bottomDiv.frame = CGRect(x: 0, y: self.frame.size.height - 0.5, width: self.frame.size.width, height: 0.5)
        bottomDiv.backgroundColor = MM_COLOR_GREEN_DIV.cgColor
        self.layer.addSublayer(bottomDiv)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Get the center for this header's label.
    internal func getHeaderLabelCenter() -> CGPoint
    {
        return CGPoint(x: self.center.x, y: self.center.y + 7)
    }
    
    /// Keeps the label's font size and the label's frame adjusted to the text.
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        delegate?.headerViewTextChanged(textField.text)
        self.resizeHeaderLabel()
        return true
    }
}
