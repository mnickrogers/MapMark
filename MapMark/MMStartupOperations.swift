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

/// Class for handling Quick Actions from the home screen. Currently supports saving current location in two different forms: normal pins and cars' location.
class MMStartupOperations: NSObject, CLLocationManagerDelegate
{
    /// Manager for this session's location.
    private let locationManager = CLLocationManager()
    
    /// Add a pin for this user's current location.
    internal func addCurrentUserLocationPin()
    {
        NotificationCenter.default.post(name: Notification.Name(rawValue: MM_NOTIFICATION_OPEN_LOADING_VIEW), object: nil)
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.requestLocation()
    }
    
    //MARK: Location methods
    
    // When the location manager returns a location, perform the currect action depending on the launch state.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        /*                          
         Add a new pin. The type and save location depends on the Quick Action selected. If the 
         selected action is "saveUserLocation," then save the pin to the bag with an ID of "1,"
         which is permanently the saved locations bag. If the selected action is 
         "saveUserParkingLocation," then save it to the parking spots bag, which has a ID of 
         "2." New bags will be created if the respective bags do not exist.
                                                                                                */
        var bagNamePlaceholder: String?
        var bagIDPlaceholder: String?
        
        // Determine the name and the ID of the bag depending on the Quick Action.
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
            // Since the process for saving a pin is the same and only the ID and name differ, use the same process for saving a parking location or saving just the user's current location.
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
            
            // Get current date for the new pin.
            let date = Date()
            
            // Insert a new pin with the appropriate information.
            let newPin = Pin(entity: pinEntity, insertInto: MMSession.sharedSession.managedObjectContext)
            newPin.name = "\(date.month())/\(date.day())/\(date.year()) at \(date.timeTwelveHourString())"
            newPin.latitude = locations.last?.coordinate.latitude ?? 0
            newPin.longitude = locations.last?.coordinate.longitude ?? 0
            
            // Determine if the correct bag already exists. If it does, just add the pin to it, else create it, then add the pin.
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
            
            // Tell the main view controller to close the loading view since all actions are complete.
            NotificationCenter.default.post(name: Notification.Name(rawValue: MM_NOTIFICATION_CLOSE_LOADING_VIEW), object: nil)
            
        default:
            break
        }
        
        // After handling all launch actions, return the session's launch state to normal.
        MMSession.sharedSession.launchState = .normal
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Failed to get location: \(error.localizedDescription)")
    }
}
