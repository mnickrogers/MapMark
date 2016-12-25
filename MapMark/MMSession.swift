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

enum MMLaunchState
{
    case normal
    case saveUserLocation
    case saveUserParkingLocation
}

class MMSession
{
    internal static let sharedSession = MMSession()
    internal lazy var startOps: MMStartupOperations? =
    {
        return MMStartupOperations()
    }()
    
    internal var managedObjectContext: NSManagedObjectContext!
    internal var launchState: MMLaunchState = .normal
    
    init()
    {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate
            else { return }
        managedObjectContext = delegate.managedObjectContext
    }
}
