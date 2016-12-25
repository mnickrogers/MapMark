//
//  MMCustomPins.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/28/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit
import MapKit

class MMMapPin: NSObject, MKAnnotation
{
    internal var pinID : String?
    internal var title: String?
    dynamic var coordinate: CLLocationCoordinate2D
    
    init(title: String?, ID: String?, coordinate: CLLocationCoordinate2D)
    {
        self.coordinate = coordinate
        self.title = title
        self.pinID = ID
        super.init()
    }
}

class MMPinDescriptionView: UIView, UITextFieldDelegate, UITextViewDelegate
{
    // MARK: - Internal Types and Variables
    
    internal var navDelegate: MMNavigationDelegate?
    
    // MARK: - Private Types and Variables
    
    private enum EditingState
    {
        case none
        case title
        case description
    }
    
    private let titleFieldTag = 2036
    private let descriptionFieldTag = 2035
    private var pinEntity: Pin?
    private var header: MMHeaderView!
    private var titleField: UITextField?
    private var descriptionField: UITextView?
    private var defaultDescriptionString = "Enter description..."
    
    // MARK: - Initialization
    
    init(frame: CGRect, pinEntity: Pin)
    {
        super.init(frame: frame)
        
        self.pinEntity = pinEntity
        
        // MARK: - Background
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = CGRect().zeroBoundedRect(self.frame)
        self.addSubview(blurEffectView)
        
        // MARK: - Header
        
        header = MMHeaderView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: 50))
        header.headerText = "Description"
        header.isTitleEditable = false
        
        // MARK: - Close button
        
        let closeButton = UIButton(type: .custom)
        closeButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        closeButton.center = CGPoint(x: 35, y: header.getHeaderLabelCenter().y)
        closeButton.setBackgroundImage(UIImage(named: "close_button_green.png"), for: UIControlState())
        closeButton.addTarget(self, action: #selector(self.closeButtonPressed), for: .touchUpInside)
        header.addSubview(closeButton)
        
        // MARK: - Title field
        
        titleField = UITextField(frame: CGRect(x: 10, y: header.frame.origin.y + header.frame.size.height + 10, width: self.frame.size.width - 10, height: 35))
        titleField?.delegate = self
        titleField?.tag = titleFieldTag
        titleField?.font = UIFont(name: MM_FONT_MEDIUM, size: 22)
        titleField?.textColor = MM_COLOR_ORANGE_TEXT
        titleField?.placeholder = "Title"
        titleField?.backgroundColor = UIColor.clear
        titleField?.keyboardAppearance = .dark
        titleField?.text = self.pinEntity?.name
        titleField?.autocapitalizationType = .words
        
        // MARK: - Divider
        
        let topDiv = CALayer()
        topDiv.frame = CGRect(x: 0, y: titleField!.frame.origin.y + titleField!.frame.size.height + 10, width: frame.size.width, height: 0.4)
        topDiv.backgroundColor = UIColor.lightGray.cgColor
        topDiv.opacity = 0.5
        
        // MARK: - Description field
        
        descriptionField = UITextView(frame: CGRect(x: titleField!.frame.origin.x, y: topDiv.frame.origin.y + topDiv.frame.size.height + 10, width: self.frame.size.width - 20, height: self.frame.size.height - self.frame.origin.y))
        descriptionField?.delegate = self
        descriptionField?.tag = descriptionFieldTag
        descriptionField?.font = UIFont(name: MM_FONT_REGULAR, size: 17)
        descriptionField?.textColor = MM_COLOR_ORANGE_TEXT
        descriptionField?.text = self.pinEntity?.pin_description
        descriptionField?.backgroundColor = UIColor.clear
        descriptionField?.keyboardAppearance = .dark
        descriptionField?.text = self.pinEntity?.pin_description ?? defaultDescriptionString
        
        self.layer.addSublayer(topDiv)
        self.addSubview(header)
        self.addSubview(titleField!)
        self.addSubview(descriptionField!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Close button
    
    func closeButtonPressed()
    {
        titleField?.resignFirstResponder()
        descriptionField?.resignFirstResponder()
        pinEntity?.name = titleField?.text
        
        if pinEntity?.pin_description == defaultDescriptionString
        {
            pinEntity?.pin_description = nil
        }
        else
        {
            pinEntity?.pin_description = descriptionField?.text
        }
        
        do
        {
            try MMSession.sharedSession.managedObjectContext.save()
        }
        catch let error as NSError
        {
            print("Error saving changes from description view: \(error.localizedDescription)")
        }
        navDelegate?.navigationDelegateViewClosed(self)
    }
}
