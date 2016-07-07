//
//  MMSingleBagView.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/6/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit
import CoreData
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

class MMSingleBagView : UIView, NSFetchedResultsControllerDelegate, MKMapViewDelegate
{
    private var mainBag : Bag?
//    private lazy var moc : NSManagedObjectContext? =
//    {
//        guard let delegate = UIApplication.sharedApplication().delegate as? AppDelegate
//            else { return nil }
//        let context = delegate.managedObjectContext
//        return context
//    }()
    private var moc : NSManagedObjectContext!
    
    private lazy var mainFetchedResultsController : NSFetchedResultsController =
    {
        let fetchRequest = NSFetchRequest(entityName: "Bag")
        let predicate = NSPredicate(format: "bag = %@", self.mainBag!)
        let fetchSort = NSSortDescriptor(key: "date_created", ascending: false)
        fetchRequest.sortDescriptors = [fetchSort]
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.moc!, sectionNameKeyPath: nil, cacheName: nil)
        return controller
    }()
    private var mainTableView : MMSingleBagTableView!
    private var mainHeader : MMHeaderView!
    private var mainMap : MKMapView!
    private var annotationIDs : [String : MKAnnotation]?
    private var pinIDs : [String : Pin]?
    
    init(frame: CGRect, bag: Bag, managedObjectContext: NSManagedObjectContext)
    {
        super.init(frame: frame)
        moc = managedObjectContext
        mainBag = bag
        
        mainHeader = MMHeaderView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: 50))
        mainHeader.headerText = mainBag?.name ?? "Tap to name"
        mainFetchedResultsController.delegate = self
        
        do
        {
            try mainFetchedResultsController.performFetch()
        }
        catch let error as NSError
        {
            print("Could not fetch items: \(error.localizedDescription)")
        }
        
        mainMap = MKMapView(frame: CGRect(x: 0, y: mainHeader.frame.size.height, width: self.frame.size.width, height: 375))
        mainMap.delegate = self
        self.addSubview(mainMap)
        
        let dropPinButton = UIButton(type: .Custom)
        dropPinButton.frame = CGRect(x: 0, y: mainMap.frame.origin.y + mainMap.frame.size.height + 15, width: self.frame.size.width * 0.8, height: 35)
        dropPinButton.center = CGPoint(x: self.center.x, y: dropPinButton.center.y)
        dropPinButton.backgroundColor = MM_COLOR_ORANGE_BACKGROUND
        dropPinButton.titleLabel?.textAlignment = .Center
        dropPinButton.titleLabel?.font = UIFont(name: MM_FONT_MEDIUM, size: 24)
        dropPinButton.setTitleColor(MM_COLOR_ORANGE_TEXT, forState: .Normal)
        dropPinButton.setTitleColor(MM_COLOR_ORANGE_DARK, forState: .Highlighted)
        dropPinButton.setTitle("Drop Pin", forState: UIControlState.Normal)
        dropPinButton.layer.cornerRadius = 5
        dropPinButton.addTarget(self, action: #selector(self.pinDropButtonPressed), forControlEvents: .TouchUpInside)
        self.addSubview(dropPinButton)
        
        mainTableView = MMSingleBagTableView(frame: CGRect(x: 0, y: dropPinButton.frame.origin.y + dropPinButton.frame.size.height, width: self.frame.size.width, height: self.frame.size.height - (dropPinButton.frame.origin.y + dropPinButton.frame.size.height)),
                                             fetchedResultsController: mainFetchedResultsController.copy() as! NSFetchedResultsController,
                                             managedObjectContext: moc!)
        self.addSubview(mainTableView)
        self.addSubview(mainHeader)
        
        annotationIDs = [String : MKAnnotation]()
        pinIDs = [String : Pin]()
        
        if mainFetchedResultsController.fetchedObjects != nil
        {
            for item in mainFetchedResultsController.fetchedObjects!
            {
                if let pinItem = item as? Pin
                {
                    let newAnnotation = MMMapPin(title: pinItem.name, ID: pinItem.pin_id, coordinate: CLLocationCoordinate2D(latitude: pinItem.latitude, longitude: pinItem.longitude))
                    annotationIDs![pinItem.pin_id!] = newAnnotation
                    mainMap.addAnnotation(newAnnotation)
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Adding Pins
    
    func pinDropButtonPressed()
    {
        dropPinAtLocation(mainMap.centerCoordinate)
    }
    
    private func dropPinAtLocation(location : CLLocationCoordinate2D)
    {
        let entityDescription = NSEntityDescription.entityForName("Pin", inManagedObjectContext: moc!)
        let newPin = Pin(entity: entityDescription!, insertIntoManagedObjectContext: moc!)
        newPin.name = "New Pin"
        newPin.latitude = location.latitude
        newPin.longitude = location.longitude
        newPin.bag = mainBag
        pinIDs![newPin.pin_id!] = newPin
        
        let newAnnotation = MMMapPin(title: newPin.name, ID: newPin.pin_id, coordinate: CLLocationCoordinate2D(latitude: newPin.latitude, longitude: newPin.longitude))
        annotationIDs![newPin.pin_id!] = newAnnotation
        mainMap.addAnnotation(newAnnotation)
        
        do
        {
            try moc?.save()
        }
        catch let error as NSError
        {
            print("Error saving Core Data context: \(error.localizedDescription)")
        }
    }
    
    // MARK: Map View Delegates
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        if let annotation = annotation as? MMMapPin
        {
            let ID = "pin_id"
            var view : MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(ID) as? MKPinAnnotationView
            {
                dequeuedView.annotation = annotation
                view = dequeuedView
            }
            else
            {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: ID)
                view.canShowCallout = false
                view.draggable = true
            }
            
            view.draggable = true
            return view
        }
        return nil
    }
}

class MMSingleBagTableView: MMDefaultFetchedResultsTableView
{
    internal var selectionDelegate : MMBagsTableViewDelegate?
    
    override func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath)
    {
        super.configureCell(cell, atIndexPath: indexPath)
        guard let record = fetchedResultsController.objectAtIndexPath(indexPath) as? Pin
            else { return }
        cell.textLabel?.text = record.name
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 35
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        selectionDelegate?.tableViewRowSelected(self, indexPath: indexPath)
    }
}
