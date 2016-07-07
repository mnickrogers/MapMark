//
//  Bag+CoreDataProperties.swift
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

extension Bag {

    @NSManaged var name:            String?
    @NSManaged var bag_id:          String?
    @NSManaged var date_created:    Int64
    @NSManaged var pins:            NSSet?

}
