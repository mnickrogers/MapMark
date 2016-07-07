//
//  Pin+CoreDataProperties.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/6/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Pin {

    @NSManaged var name:            String?
    @NSManaged var pin_description: String?
    @NSManaged var pin_id:          String?
    @NSManaged var latitude:        Double
    @NSManaged var longitude:       Double
    @NSManaged var date_created:    Int64
    @NSManaged var bag:             NSManagedObject?

}
