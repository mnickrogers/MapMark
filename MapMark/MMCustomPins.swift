//
//  MMCustomPins.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/28/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit
import MapKit

class MMMapPin: NSObject, MKAnnotation
{
    internal var pinID : String?
    internal var title: String?
    dynamic var coordinate: CLLocationCoordinate2D
    
    init(title: String?, ID: String?, coordinate: CLLocationCoordinate2D)
    {
        self.coordinate = coordinate
        self.title = title
        self.pinID = ID
        super.init()
    }
}
