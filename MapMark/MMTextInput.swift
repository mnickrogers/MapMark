//
//  MMTextInput.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/6/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit

protocol MMTextInputViewDelegate
{
    func textInputViewReturned(_ inputView : MMTextInputView, field : UITextField, string : String?)
}

class MMTextInputView: UIView, UITextFieldDelegate
{
    // MARK: Internal Variables
    internal var delegate : MMTextInputViewDelegate?
    internal(set) var textField : UITextField!
    
    // MARK: Initialization
    override init(frame: CGRect)
    {
        super.init(frame: frame)
    }
    
    init(frame: CGRect, backgroundType: UIBlurEffectStyle = UIBlurEffectStyle.light)
    {
        super.init(frame: frame)
        
        backgroundColor = UIColor.clear
        
        let blurEffect = UIBlurEffect(style: backgroundType)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = CGRect().zeroBoundedRect(self.frame)
        addSubview(blurEffectView)
        let height : CGFloat = self.frame.size.height == 0 ? 35 : self.frame.size.height
        textField = UITextField(frame: CGRect(x: 15, y: self.frame.size.height - height, width: self.frame.size.width - 15, height: height))
        textField.font = UIFont(name: MM_FONT_REGULAR, size: 22)
        textField.textAlignment = .left
        textField.textColor = MM_COLOR_BLUE_TEXT
        textField.delegate = self
        textField.autocapitalizationType = .words
        textField.returnKeyType = .done
        textField.keyboardAppearance = .dark
        textField.isUserInteractionEnabled = true
        textField.becomeFirstResponder()
        self.addSubview(textField)
    }
    
    convenience init(frame: CGRect, animated: Bool, backgroundType: UIBlurEffectStyle = UIBlurEffectStyle.light)
    {
        self.init(frame: frame, backgroundType: backgroundType)
        
        if animated
        {
            let startFrame = self.frame
            self.alpha = 0
            self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y - self.frame.size.height, width: self.frame.size.width, height: self.frame.size.height)
            UIView.animate(withDuration: 0.25,
                                       delay: 0,
                                       options: UIViewAnimationOptions.curveEaseOut,
                                       animations: {
                                        self.alpha = 1
                                        self.frame = startFrame
                },
                                       completion: { (completed) in
            })
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal func animateViewOff(_ completion:@escaping (_ completed: Bool, _ view : UIView) -> Void)
    {
        UIView.animate(withDuration: 0.25,
                                   delay: 0,
                                   options: UIViewAnimationOptions.curveEaseOut,
                                   animations: {
                                    self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y - self.frame.size.height, width: self.frame.size.width, height: self.frame.size.height)
                                    self.alpha = 0
                                    
            }) { (completed) in
                completion(completed, self)
        }
    }
    
    // MARK: Text Field Delegates
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        delegate?.textInputViewReturned(self, field: textField, string: textField.text)
        return true
    }
}
