//
//  MMSession.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/7/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

class MMSession
{
    internal static let sharedSession = MMSession()
    
    internal var managedObjectContext : NSManagedObjectContext!
    
    init()
    {
        guard let delegate = UIApplication.sharedApplication().delegate as? AppDelegate
            else { return }
        managedObjectContext = delegate.managedObjectContext
    }
}
