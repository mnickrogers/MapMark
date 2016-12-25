//
//  MMExporting.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/22/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit
import CoreData

class MMExporter
{
    internal func getCoreDataCSVString() -> String
    {
        let request = NSFetchRequest<NSFetchRequestResult>()
        let entity = NSEntityDescription.entity(forEntityName: "Pin", in: MMSession.sharedSession.managedObjectContext)
        let bagSort = NSSortDescriptor(key: "bag.name", ascending: true)
        let nameSort = NSSortDescriptor(key: "name", ascending: true)
        request.entity = entity
        request.sortDescriptors = [bagSort, nameSort]
        
        guard let results = try? MMSession.sharedSession.managedObjectContext.fetch(request) as? [Pin]
            else { print("Error executing CoreData fetch request for CSV conversion"); return "" }
        
        if results == nil
        {
            return ""
        }
        
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
            
            csvStr += "\(bagName),\(name),\(item.latitude),\(item.longitude),\(item.date_created),\(description)\n"
        }
        
        return csvStr
    }
    
    internal func getCoreDataCSVData() -> Data?
    {
        let string = getCoreDataCSVString()
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
        return data
    }
    
    internal func getDocumentsDirectory() -> NSString
    {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        return paths[0] as NSString
    }
}
