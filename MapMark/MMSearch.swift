//
//  MMSearch.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/28/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit
import MapKit
import CoreData

/// Load pins that this user has saved near a given location.
internal func fetchPinsNearLocation(_ location: CLLocationCoordinate2D, radius: Double, sortedByDistance: Bool = false) -> [Pin]?
{
    let distUnit = 69.0 // Use 111.045 for km
    let lat = location.latitude
    let lon = location.longitude
    
    let latMin = lat - (radius / distUnit)
    let latMax = lat + (radius / distUnit)
    let lonMin = lon - (radius / (distUnit * cos(degreesToRadians(lat))))
    let lonMax = lon + (radius / (distUnit * cos(degreesToRadians(lat))))
    
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
    let entityDescription = NSEntityDescription.entity(forEntityName: "Pin", in: MMSession.sharedSession.managedObjectContext)
    let predicate = NSPredicate(format: "(latitude > %f AND latitude < %f) AND (longitude > %f AND longitude < %f)", latMin, latMax, lonMin, lonMax)
    
    fetchRequest.entity = entityDescription
    fetchRequest.predicate = predicate
    
    var pins: [Pin]?
    
    do
    {
        pins = try MMSession.sharedSession.managedObjectContext.fetch(fetchRequest) as? [Pin]
    }
    catch let error as NSError
    {
        print("Error loading nearby pins: \(error.localizedDescription)")
    }
    
    return pins
}
