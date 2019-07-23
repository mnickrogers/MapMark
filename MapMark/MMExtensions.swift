//
//  MMExtensions.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/6/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit
import CoreData

extension Date
{
    func hour() -> Int
    {
        let components = (Calendar.current as NSCalendar).components(.hour, from: self)
        return components.hour!
    }
    
    func minute() -> Int
    {
        let components = (Calendar.current as NSCalendar).components(.minute, from: self)
        return components.minute!
    }
    
    func timeTwelveHourString() -> String
    {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    func year() -> Int
    {
        let components = (Calendar.current as NSCalendar).components(.year, from: self)
        return components.year!
    }
    
    func month() -> Int
    {
        let components = (Calendar.current as NSCalendar).components(.month, from: self)
        return components.month!
    }
    
    func day() -> Int
    {
        let components = (Calendar.current as NSCalendar).components(.day, from: self)
        return components.day!
    }
}

//extension NSFetchedResultsController
//{
//    func copyWithZone(_ zone: NSZone?) -> NSFetchRequest<NSFetchRequestResult>
//    {
//        let copy = NSFetchedResultsController(fetchRequest: self.fetchRequest,
//                                              managedObjectContext: self.managedObjectContext,
//                                              sectionNameKeyPath: self.sectionNameKeyPath,
//                                              cacheName: self.cacheName)
//        return copy
//    }
//}

extension CGRect
{
    func zeroBoundedRect(_ fromFrame: CGRect) -> CGRect
    {
        return CGRect(x: 0, y: 0, width: fromFrame.size.width, height: fromFrame.size.height)
    }
    
    func frameBeneathFrame(_ mainFrame: CGRect, beneathFrame: CGRect) -> CGRect
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
        if mutatingString.contains(",") // Needs conversion to degrees.
        {
            func getDegreesMinutesSeconds(_ string : String) -> (direction: String, degrees: Double, minutes: Double, seconds: Double)?
            {
//                let direction = string.substring(with: string.startIndex..<string.characters.index(string.startIndex, offsetBy: 1))
                let direction = string[string.startIndex..<string.index(string.startIndex, offsetBy: 1)]
//                let radians = string.substring(with: string.characters.index(string.startIndex, offsetBy: 1)..<string.endIndex)
                let radians = string[string.index(string.startIndex, offsetBy: 1)..<string.endIndex]
                
                guard let commaPos = radians.range(of: ",")
                    else { return nil }
                guard let decimalPos = radians.range(of: ".")
                    else { return nil }
                
//                let degString = radians.substring(with: radians.startIndex..<commaPos.lowerBound)
//                let minString = radians.substring(with: commaPos.upperBound..<decimalPos.lowerBound)
//                let secString = radians.substring(with: decimalPos.upperBound..<radians.endIndex)
//                let degString = radians.substring(with: radians.startIndex..<commaPos.lowerBound)
                let degString = radians[radians.startIndex..<commaPos.lowerBound]
                let minString = radians[commaPos.upperBound..<decimalPos.lowerBound]
                let secString = radians[decimalPos.upperBound..<radians.endIndex]
                
                guard let degrees = Double(degString)
                    else { return nil }
                guard let minutes = Double(minString)
                    else { return nil }
                guard let seconds = Double(secString)
                    else { return nil }
                
                return (direction: String(direction), degrees: degrees, minutes: minutes, seconds: seconds)
            }
            func convertDegreesToDecimal(_ degrees: (direction: String, degrees: Double, minutes: Double, seconds: Double)) -> Double
            {
                var decimal = degrees.degrees + (degrees.minutes / 60.0) + (degrees.seconds / 3600.0)
                
                if degrees.direction == "S" || degrees.direction == "s" || degrees.direction == "W" || degrees.direction == "w"
                {
                    decimal = -decimal
                }
                
                return decimal
            }
            
            guard let spacePos = mutatingString.range(of: " ")
                else { return nil }
            let latString = mutatingString.substring(with: mutatingString.startIndex..<spacePos.lowerBound)
            let lonString = mutatingString.substring(with: spacePos.upperBound..<mutatingString.endIndex)
            
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
            guard let spacePos = mutatingString.range(of: " ")
                else { return nil }
            
            let latString = mutatingString.substring(with: mutatingString.startIndex..<spacePos.lowerBound)
            let lonString = mutatingString.substring(with: mutatingString.index(spacePos.lowerBound, offsetBy: 1)..<mutatingString.endIndex)
            
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
    
    func randomString(_ length : Int, strong : Bool, restrictLowercase lowercase : Bool, permitSpaces : Bool) -> String
    {
        func miniRandomString(_ miniLength : Int) -> String
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
                
                let char = String(describing: UnicodeScalar(numVal))
                miniText += char
                miniText = miniText.replacingOccurrences(of: "  ", with: " ")
            }
            
            return miniText
        }
        
        var result = ""
        
        if strong
        {
            let baseStringLength = minimumRandomStringStrongLength
            assert(length >= minimumRandomStringStrongLength, "String strength set to strong, but minimum length is below strong minimum requirement.")
            
            let unixTime : String = String(Int((Date().timeIntervalSince1970)))
            let baseString = unixTime.substring(with: unixTime.index(unixTime.endIndex, offsetBy: -baseStringLength)..<unixTime.endIndex)
            
            let front = miniRandomString((length - baseStringLength) / 2)
            let end = miniRandomString((length - baseStringLength) / 2)
            
            result = front + baseString + end
            return result
        }
        
        return miniRandomString(length)
    }
}

extension Bool
{
    init(_ i: Int)
    {
        if i > 0
        {
            self = true
        }
        else
        {
            self = false
        }
    }
}
