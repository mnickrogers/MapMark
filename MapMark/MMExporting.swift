//
//  MMExporting.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/22/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit
import CoreData

/// A class for handling exporting this application's CoreData model.
class MMExporter
{
    /// Convert this application's CoreData model into a string representing CSV data.
    internal func getCoreDataCSVString() -> String
    {
        // Create the request for fetching pins.
        let request = NSFetchRequest<NSFetchRequestResult>()
        let entity = NSEntityDescription.entity(forEntityName: "Pin", in: MMSession.sharedSession.managedObjectContext)
        let bagSort = NSSortDescriptor(key: "bag.name", ascending: true)
        let nameSort = NSSortDescriptor(key: "name", ascending: true)
        request.entity = entity
        request.sortDescriptors = [bagSort, nameSort]
        
        // Execute the fetch for all pins this user has saved.
        guard let results = try? MMSession.sharedSession.managedObjectContext.fetch(request) as? [Pin]
            else { print("Error executing CoreData fetch request for CSV conversion"); return "" }
        
        if results == nil
        {
            return ""
        }
        
        // The string that will represent a CSV file.
        var csvStr = "BAG_NAME,PIN_NAME,LATITUDE,LONGITUDE,DATE_ADDED,DESCRIPTION\n"
        
        let _ = results!.map
        {
            item in
            let name = item.name ?? "untitled"
            let description = item.pin_description ?? ""
            var bagName = ""
            if let bag = item.bag as? Bag
            {
                if let bName = bag.name
                {
                    bagName = bName
                }
            }
            
            // Append each new pin's data to the CSV string.
            csvStr += "\(bagName),\(name),\(item.latitude),\(item.longitude),\(item.date_created),\(description)\n"
        }
        
        return csvStr
    }
    
    /// Convert this application's CoreData model into data holding a CSV string.
    internal func getCoreDataCSVData() -> Data?
    {
        let string = getCoreDataCSVString()
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
        return data
    }
    
    /// Get the document directory for this user's application.
    internal func getDocumentsDirectory() -> NSString
    {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        return paths[0] as NSString
    }
}
