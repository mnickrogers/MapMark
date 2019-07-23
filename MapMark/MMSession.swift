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

/// Launch state options.
enum MMLaunchState
{
    /// No special commands at launch.
    case normal
    /// Save user location Quick Action selected.
    case saveUserLocation
    /// Save user location as current car location Quick Action selected.
    case saveUserParkingLocation
}

/// The main session object. Handles start-up operations from Quick Actions and holds a global ManagedObjectContext from the app's delegate.
class MMSession
{
    /// Main session.
    internal static let sharedSession = MMSession()
    /// Start-up operations created by home screen Quick Actions.
    internal lazy var startOps: MMStartupOperations? =
    {
        return MMStartupOperations()
    }()
    
    /// Main managed object context.
    internal var managedObjectContext: NSManagedObjectContext!
    /// State at launch - used to capture information from the home screen's Quick Actions. Mainly used by the MMStartupOperations class.
    internal var launchState: MMLaunchState = .normal
    
    /// Object representing the safe areas of this device (fixed at launch because rotation is disallowed).
    internal var safeAreaInsets = UIEdgeInsets()
    
    init()
    {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate
            else { return }
        managedObjectContext = delegate.managedObjectContext
    }
}
