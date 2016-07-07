//
//  MMExtensions.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/6/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit
import CoreData

extension NSFetchedResultsController
{
    func copyWithZone(zone: NSZone) -> AnyObject
    {
        let copy = NSFetchedResultsController(fetchRequest: self.fetchRequest,
                                              managedObjectContext: self.managedObjectContext,
                                              sectionNameKeyPath: self.sectionNameKeyPath,
                                              cacheName: self.cacheName)
        return copy
    }
}

extension CGRect
{
    func zeroBoundedRect(fromFrame: CGRect) -> CGRect
    {
        return CGRect(x: 0, y: 0, width: fromFrame.size.width, height: fromFrame.size.height)
    }
}

extension String
{
    var minimumRandomStringStrongLength : Int
    {
        //Do not make this longer than the number of digits in UNIX time
        return 8
    }
    
    func randomString(length : Int, strong : Bool, restrictLowercase lowercase : Bool, permitSpaces : Bool) -> String
    {
        func miniRandomString(miniLength : Int) -> String
        {
            var miniText = ""
            
            for _ in 1...miniLength
            {
                var numVal = 0
                var charType = 3
                if !lowercase
                {
                    charType = Int(arc4random_uniform(4))
                }
                
                switch charType
                {
                case 1:
                    numVal = Int(arc4random_uniform(10)) + 48
                case 2:
                    numVal = Int(arc4random_uniform(26)) + 65
                case 3:
                    numVal = Int(arc4random_uniform(26)) + 97
                default:
                    if permitSpaces
                    {
                        numVal = 32
                    }
                    else
                    {
                        numVal = 45
                    }
                }
                
                let char = String(UnicodeScalar(numVal))
                miniText += char
                miniText = miniText.stringByReplacingOccurrencesOfString("  ", withString: " ")
            }
            
            return miniText
        }
        
        var result = ""
        
        if strong
        {
            let baseStringLength = minimumRandomStringStrongLength
            assert(length >= minimumRandomStringStrongLength, "String strength set to strong, but minimum length is below strong minimum requirement.")
            
            let unixTime : String = String(Int((NSDate().timeIntervalSince1970)))
            let baseString = unixTime.substringWithRange(unixTime.endIndex.advancedBy(-baseStringLength)..<unixTime.endIndex)
            
            let front = miniRandomString((length - baseStringLength) / 2)
            let end = miniRandomString((length - baseStringLength) / 2)
            
            result = front + baseString + end
            return result
        }
        
        return miniRandomString(length)
    }
}
