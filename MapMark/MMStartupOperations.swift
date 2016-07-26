//
//  MMStartupOperations.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/25/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import Foundation
import CoreLocation
import CoreData

class MMStartupOperations: NSObject, CLLocationManagerDelegate
{
    private let locationManager = CLLocationManager()
    internal func addCurrentUserLocationPin()
    {
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.requestLocation()
    }
    
    //MARK: Location methods
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        switch MMSession.sharedSession.launchState
        {
        case .SaveUserLocation:
            guard let bagEntity = NSEntityDescription.entityForName("Bag", inManagedObjectContext: MMSession.sharedSession.managedObjectContext)
                else { return }
            guard let pinEntity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: MMSession.sharedSession.managedObjectContext)
                else { return }
            
            let date = NSDate()
            let newBag = Bag(entity: bagEntity, insertIntoManagedObjectContext: MMSession.sharedSession.managedObjectContext)
            newBag.name = "Saved Locations"
            
            let newPin = Pin(entity: pinEntity, insertIntoManagedObjectContext: MMSession.sharedSession.managedObjectContext)
            newPin.name = "\(date.month())/\(date.day())/\(date.year() % 20) at \(date.timeTwelveHourString())"
            newPin.bag = newBag
            newPin.latitude = locations.last?.coordinate.latitude ?? 0
            newPin.longitude = locations.last?.coordinate.longitude ?? 0
            
            do
            {
                try MMSession.sharedSession.managedObjectContext.save()
            }
            catch let error as NSError
            {
                print("Failed to save new temporary data: \(error.localizedDescription)")
            }
            
        default:
            break
        }
        
        MMSession.sharedSession.launchState = .Normal
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError)
    {
        print("Failed to get location: \(error.localizedDescription)")
    }
}
