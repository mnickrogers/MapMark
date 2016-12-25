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
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?)
    {
        super.init(entity: entity, insertInto: context)
        
        if date_created == 0
        {
            date_created = Int64(Date().timeIntervalSince1970)
        }
        
        if pin_id == nil
        {
            pin_id = String().randomString(10, strong: false, restrictLowercase: false, permitSpaces: false)
        }
    }
}
