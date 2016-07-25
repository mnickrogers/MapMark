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
    
    func frameBeneathFrame(mainFrame: CGRect, beneathFrame: CGRect) -> CGRect
    {
        return CGRect(x: beneathFrame.origin.x, y: beneathFrame.origin.y + mainFrame.size.height, width: mainFrame.size.width, height: mainFrame.size.height)
    }
}

extension String
{
    func getCoordinatesFromString() -> (longitude: Double, latitude: Double)?
    {
        var result : (longitude: Double, latitude: Double)?
        
        var mutatingString = self
        if mutatingString.containsString(",") // Needs conversion to degrees.
        {
            func getDegreesMinutesSeconds(string : String) -> (direction: String, degrees: Double, minutes: Double, seconds: Double)?
            {
                let direction = string.substringWithRange(string.startIndex..<string.startIndex.advancedBy(1))
                let radians = string.substringWithRange(string.startIndex.advancedBy(1)..<string.endIndex)
                
                guard let commaPos = radians.rangeOfString(",")
                    else { return nil }
                guard let decimalPos = radians.rangeOfString(".")
                    else { return nil }
                
                let degString = radians.substringWithRange(radians.startIndex..<commaPos.startIndex)
                let minString = radians.substringWithRange(commaPos.endIndex..<decimalPos.startIndex)
                let secString = radians.substringWithRange(decimalPos.endIndex..<radians.endIndex)
                
                guard let degrees = Double(degString)
                    else { return nil }
                guard let minutes = Double(minString)
                    else { return nil }
                guard let seconds = Double(secString)
                    else { return nil }
                
                return (direction: direction, degrees: degrees, minutes: minutes, seconds: seconds)
            }
            func convertDegreesToDecimal(degrees: (direction: String, degrees: Double, minutes: Double, seconds: Double)) -> Double
            {
                var decimal = degrees.degrees + (degrees.minutes / 60.0) + (degrees.seconds / 3600.0)
                
                if degrees.direction == "S" || degrees.direction == "s" || degrees.direction == "W" || degrees.direction == "w"
                {
                    decimal = -decimal
                }
                
                return decimal
            }
            
            guard let spacePos = mutatingString.rangeOfString(" ")
                else { return nil }
            let latString = mutatingString.substringWithRange(mutatingString.startIndex..<spacePos.startIndex)
            let lonString = mutatingString.substringWithRange(spacePos.endIndex..<mutatingString.endIndex)
            
            guard let latDMS = getDegreesMinutesSeconds(latString)
                else { return nil }
            guard let lonDMS = getDegreesMinutesSeconds(lonString)
                else { return nil }
            
            let latDegrees = convertDegreesToDecimal(latDMS)
            let lonDegrees = convertDegreesToDecimal(lonDMS)
            
            result = (latitude: latDegrees, longitude: lonDegrees)
        }
        else // Is expressed in degrees.
        {
            guard let spacePos = mutatingString.rangeOfString(" ")
                else { return nil }
            
            let latString = mutatingString.substringWithRange(mutatingString.startIndex..<spacePos.startIndex)
            let lonString = mutatingString.substringWithRange(spacePos.startIndex.advancedBy(1)..<mutatingString.endIndex)
            
            guard let lat = Double(latString)
                else { return nil }
            guard let lon = Double(lonString)
                else { return nil }
            
            result = (latitude: lat, longitude: lon)
        }
        
        return result
    }
    
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
