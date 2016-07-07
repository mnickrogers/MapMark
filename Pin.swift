//
//  Pin.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/6/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import Foundation
import CoreData


class Pin: NSManagedObject
{
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?)
    {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        if date_created == 0
        {
            date_created = Int64(NSDate().timeIntervalSince1970)
        }
    }
}
