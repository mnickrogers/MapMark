//
//  Bag.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/6/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import Foundation
import CoreData


class Bag: NSManagedObject
{
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?)
    {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        if date_created == 0
        {
            date_created = Int64(NSDate().timeIntervalSince1970)
        }
        
        if last_edited == 0
        {
            updateLastEdited()
        }
        
        if bag_id == nil
        {
            bag_id = String().randomString(10, strong: false, restrictLowercase: false, permitSpaces: false)
        }
    }
    
    internal func updateLastEdited()
    {
        last_edited = Int64(NSDate().timeIntervalSince1970)
    }
}
