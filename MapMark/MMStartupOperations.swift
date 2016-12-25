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
    fileprivate let locationManager = CLLocationManager()
    internal func addCurrentUserLocationPin()
    {
        NotificationCenter.default.post(name: Notification.Name(rawValue: MM_NOTIFICATION_OPEN_LOADING_VIEW), object: nil)
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.requestLocation()
    }
    
    //MARK: Location methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        var bagNamePlaceholder: String?
        var bagIDPlaceholder: String?
        
        switch MMSession.sharedSession.launchState
        {
        case .saveUserLocation:
            bagNamePlaceholder = "My Saved Locations"
            bagIDPlaceholder = "1"
        case .saveUserParkingLocation:
            bagNamePlaceholder = "My Parking Spots"
            bagIDPlaceholder = "2"
        default:
            return
        }
        
        switch MMSession.sharedSession.launchState
        {
        case .saveUserParkingLocation:
            fallthrough
        case .saveUserLocation:
            guard let bagEntity = NSEntityDescription.entity(forEntityName: "Bag", in: MMSession.sharedSession.managedObjectContext)
                else { return }
            guard let pinEntity = NSEntityDescription.entity(forEntityName: "Pin", in: MMSession.sharedSession.managedObjectContext)
                else { return }
            guard let newBagName = bagNamePlaceholder
                else { return }
            guard let newBagID = bagIDPlaceholder
                else { return }
            
            let date = Date()
            
            let newPin = Pin(entity: pinEntity, insertInto: MMSession.sharedSession.managedObjectContext)
            newPin.name = "\(date.month())/\(date.day())/\(date.year()) at \(date.timeTwelveHourString())"
            newPin.latitude = locations.last?.coordinate.latitude ?? 0
            newPin.longitude = locations.last?.coordinate.longitude ?? 0
            
            let bagRequest = NSFetchRequest<NSFetchRequestResult>()
            let bagPredicate = NSPredicate(format: "bag_id = %@", newBagID)
            bagRequest.predicate = bagPredicate
            bagRequest.entity = bagEntity
            bagRequest.fetchLimit = 1
            
            do
            {
                let existingBag = try MMSession.sharedSession.managedObjectContext.fetch(bagRequest) as? [Bag]
                
                if let oldBag = existingBag?.first
                {
                    newPin.bag = oldBag
                    oldBag.updateLastEdited()
                }
                else
                {
                    let newBag = Bag(entity: bagEntity, insertInto: MMSession.sharedSession.managedObjectContext)
                    newBag.name = newBagName
                    newBag.bag_id = newBagID
                    newPin.bag = newBag
                }
            }
            catch let error as NSError
            {
                print(error)
            }
            
            do
            {
                try MMSession.sharedSession.managedObjectContext.save()
            }
            catch let error as NSError
            {
                print("Failed to save new temporary data: \(error.localizedDescription)")
            }
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: MM_NOTIFICATION_CLOSE_LOADING_VIEW), object: nil)
            
        default:
            break
        }
        
        MMSession.sharedSession.launchState = .normal
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Failed to get location: \(error.localizedDescription)")
    }
}
