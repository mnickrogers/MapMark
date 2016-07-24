//
//  MMSingleBagView.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/6/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import MapKit

protocol MMNavigationDelegate
{
    func navigationDelegateViewClosed(view : UIView)
}

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

class MMSingleBagView : UIView, NSFetchedResultsControllerDelegate, MKMapViewDelegate, UIScrollViewDelegate, MMHeaderViewDelegate, MMBagsTableViewDelegate, MMTextInputViewDelegate
{
    // MARK: Internal Types and Variables
    internal var navDelegate : MMNavigationDelegate?
    
    // MARK: Private Types and Variables
    private enum ViewState
    {
        case None
        case NewItemNaming
        case CoordinateEntry
        case StartPinSelection
        case DisplayingRoute
    }
    private var locationManager = CLLocationManager()
    private var mainViewState = ViewState.None
    private var mainBag : Bag?
    private var currentPin : Pin?
    private lazy var mainFetchedResultsController : NSFetchedResultsController =
    {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        let predicate = NSPredicate(format: "bag = %@", self.mainBag!)
        let fetchSort = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [fetchSort]
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: MMSession.sharedSession.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        return controller
    }()
    private var mainTableView : MMSingleBagTableView!
    private var mainHeader : MMHeaderView!
    private var inputScrollView : UIScrollView!
    private var inputPageControl : UIPageControl!
    private var mainMap : MKMapView!
    private var annotationIDs : [String : MKAnnotation]?
    private var pinIDs : [String : Pin]?
    private var defaultHeaderString : String?
    
    init(frame: CGRect, bag: Bag)
    {
        super.init(frame: frame)
        mainBag = bag
        
        mainFetchedResultsController.delegate = self
        
        do
        {
            try mainFetchedResultsController.performFetch()
        }
        catch let error as NSError
        {
            print("Could not fetch items: \(error.localizedDescription)")
        }
        
        // MARK: User location
        locationManager.requestWhenInUseAuthorization()
        
        // MARK: Header
        mainHeader = MMHeaderView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: 50))
        mainHeader.headerText = mainBag?.name ?? "Tap to name"
        mainHeader.delegate = self
        
        // MARK: Background
        let mainBackground = UIView(frame: CGRect(x: 0, y: mainHeader.frame.origin.y + mainHeader.frame.size.height, width: self.frame.size.width, height: self.frame.size.height - mainHeader.frame.size.height))
        mainBackground.backgroundColor = MM_COLOR_BASE
        self.addSubview(mainBackground)

        // MARK: Close button
        let closeButton = UIButton(type: .Custom)
        closeButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        closeButton.center = CGPoint(x: 35, y: mainHeader.getHeaderLabelCenter().y)
        closeButton.setBackgroundImage(UIImage(named: "close_button_green.png"), forState: .Normal)
        closeButton.addTarget(self, action: #selector(self.closeViewButtonPressed), forControlEvents: .TouchUpInside)
        mainHeader.addSubview(closeButton)
        
        // MARK: Map
        let longPressRecog = UILongPressGestureRecognizer(target: self, action: #selector(self.mapViewLongPressed(_:)))
        longPressRecog.minimumPressDuration = 1
        longPressRecog.cancelsTouchesInView = false
        
        mainMap = MKMapView(frame: CGRect(x: 0, y: mainHeader.frame.size.height, width: self.frame.size.width, height: self.frame.size.height * 0.58))
        mainMap.delegate = self
        mainMap.showsUserLocation = true
        mainMap.addGestureRecognizer(longPressRecog)
        self.addSubview(mainMap)

        // MARK: Input scroll-view
        inputScrollView = UIScrollView(frame: CGRect(x: 0, y: mainMap.frame.origin.y + mainMap.frame.size.height, width: self.frame.size.width, height: 70))
        inputScrollView.alwaysBounceHorizontal = true
        inputScrollView.contentSize = CGSize(width: self.frame.size.width * 3, height: inputScrollView.frame.size.height)
        inputScrollView.pagingEnabled = true
        inputScrollView.delegate = self

        inputPageControl = UIPageControl(frame: CGRect(x: 0, y: inputScrollView.frame.origin.y + inputScrollView.frame.size.height, width: 100, height: 15))
        inputPageControl.center = CGPoint(x: inputScrollView.center.x, y: inputPageControl.center.y)
        inputPageControl.numberOfPages = 3
        inputPageControl.pageIndicatorTintColor = UIColor.darkGrayColor()
        inputPageControl.currentPageIndicatorTintColor = MM_COLOR_ORANGE_LIGHT
        inputPageControl.addTarget(self, action: #selector(self.inputPageControlChanged), forControlEvents: .ValueChanged)

        inputScrollView.addSubview(getInputScrollViewItem(atPage: 1))
        inputScrollView.addSubview(getInputScrollViewItem(atPage: 2))
        inputScrollView.addSubview(getInputScrollViewItem(atPage: 3))

        // MARK: Main table view
        mainTableView = MMSingleBagTableView(frame: CGRect(x: 0, y: inputScrollView.frame.origin.y + inputScrollView.frame.size.height + 20, width: self.frame.size.width, height: self.frame.size.height - (inputScrollView.frame.origin.y + inputScrollView.frame.size.height + 20)),
                                             fetchedResultsController: mainFetchedResultsController.copy() as! NSFetchedResultsController,
                                             managedObjectContext: MMSession.sharedSession.managedObjectContext)
        mainTableView.separatorColor = MM_COLOR_ORANGE_DIV
        mainTableView.clipsToBounds = true
        mainTableView.selectionDelegate = self

        // MARK: Add subviews
        self.addSubview(inputScrollView)
        self.addSubview(inputPageControl)
        self.addSubview(mainTableView)
        self.addSubview(mainHeader)

        // MARK: Load pins
        annotationIDs = [String : MKAnnotation]()
        pinIDs = [String : Pin]()
        
        var annotationsRect = MKMapRectNull
        var annotations = [MKAnnotation]()
        
        if mainFetchedResultsController.fetchedObjects != nil
        {
            for item in mainFetchedResultsController.fetchedObjects!
            {
                if let pinItem = item as? Pin
                {
                    let newAnnotation = MMMapPin(title: pinItem.name, ID: pinItem.pin_id, coordinate: CLLocationCoordinate2D(latitude: pinItem.latitude, longitude: pinItem.longitude))
                    annotationIDs![pinItem.pin_id!] = newAnnotation
                    pinIDs![pinItem.pin_id!] = pinItem
                    annotations.append(newAnnotation)
                    
                    let annotationPoint = MKMapPointForCoordinate(newAnnotation.coordinate)
                    let pointRect = MKMapRect(origin: annotationPoint, size: MKMapSize(width: 0.1, height: 0.1))
                    annotationsRect = MKMapRectUnion(annotationsRect, pointRect)
                }
            }
            let bufferRect = MKMapRect(origin: MKMapPoint(x: annotationsRect.origin.x - (annotationsRect.origin.x * 0.02), y: annotationsRect.origin.y - (annotationsRect.origin.y * 0.02)), size: MKMapSize(width: annotationsRect.size.width + ((annotationsRect.origin.x * 0.02) * 2), height: annotationsRect.size.height + ((annotationsRect.origin.y * 0.02) * 2)))
            mainMap.setVisibleMapRect(bufferRect, animated: false)
        }
        
        if annotations.isEmpty
        {
            mainMap.setCenterCoordinate(CLLocationCoordinate2D(latitude: 39.8282, longitude: -98.5795), animated: false)
        }
        
        for ann in annotations
        {
            mainMap.addAnnotation(ann)
        }
    }
    
    override func removeFromSuperview() // Some delegate references cause retain cycles.
    {
        mainHeader.delegate = nil
        mainFetchedResultsController.delegate = nil
        mainMap.delegate = nil
        inputScrollView.delegate = nil
        mainTableView.selectionDelegate = nil
        
        super.removeFromSuperview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Scroll View and Page Control
    private func getInputScrollViewItem(atPage pageNumber : Int) -> UIView
    {
        switch pageNumber
        {
        case 1:
            let view = UIView(frame: CGRect().zeroBoundedRect(inputScrollView.frame))
            let centerLocationButton = configureDefaultButton()
            centerLocationButton.frame = CGRect(x: (self.frame.size.width - (self.frame.size.width * 0.8)) / 4, y: 0, width: centerLocationButton.frame.size.height + 15, height: centerLocationButton.frame.size.height)
            centerLocationButton.setImage(UIImage(named: "mm_location_arrow.png")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
            centerLocationButton.imageView?.contentMode = .ScaleAspectFit
            centerLocationButton.tintColor = MM_COLOR_ORANGE_LIGHT
            centerLocationButton.addTarget(self, action: #selector(self.centerMapOnUser), forControlEvents: .TouchUpInside)
            
            let dropPinOffset = abs(centerLocationButton.frame.size.width - centerLocationButton.frame.origin.x) + 3
            
            let dropPinButton = configureDefaultButton()
            dropPinButton.frame = CGRect(x: dropPinButton.frame.origin.x, y: dropPinButton.frame.origin.y, width: dropPinButton.frame.size.width - dropPinOffset, height: dropPinButton.frame.size.height)
            dropPinButton.center = CGPoint(x: self.center.x * CGFloat(pageNumber) + dropPinOffset, y: dropPinButton.center.y)
            dropPinButton.setTitle("Drop Pin", forState: UIControlState.Normal)
            dropPinButton.addTarget(self, action: #selector(self.pinDropButtonPressed), forControlEvents: .TouchUpInside)
            
            centerLocationButton.center = CGPoint(x: centerLocationButton.center.x, y: dropPinButton.center.y)
            
            view.addSubview(centerLocationButton)
            view.addSubview(dropPinButton)
            return view
        case 2:
            let coordinateEntryButton = configureDefaultButton()
            coordinateEntryButton.center = CGPoint(x: self.center.x * CGFloat(pageNumber) + (inputScrollView.frame.size.width / 2), y: coordinateEntryButton.center.y)
            coordinateEntryButton.setTitle("Enter Coordinates", forState: UIControlState.Normal)
            coordinateEntryButton.addTarget(self, action: #selector(self.enterCoordinateButtonPressed), forControlEvents: .TouchUpInside)
            return coordinateEntryButton
        case 3:
            let calculateRouteButton = configureDefaultButton()
            calculateRouteButton.center = CGPoint(x: self.center.x * CGFloat(pageNumber) + inputScrollView.frame.size.width, y: calculateRouteButton.center.y)
            calculateRouteButton.setTitle("Get Route through Pins", forState: UIControlState.Normal)
            calculateRouteButton.addTarget(self, action: #selector(self.calculateRootThroughPinsButtonPressed(_:)), forControlEvents: .TouchUpInside)
            return calculateRouteButton
        default:
            return UIView()
        }
    }
    
    private func configureDefaultButton() -> UIButton
    {
        let button = UIButton(type: .Custom)
        button.frame = CGRect(x: 0, y: 15, width: self.frame.size.width * 0.8, height: 35)
        button.backgroundColor = MM_COLOR_ORANGE_BACKGROUND
        button.titleLabel?.textAlignment = .Center
        button.titleLabel?.font = UIFont(name: MM_FONT_MEDIUM, size: 24)
        button.setTitleColor(MM_COLOR_ORANGE_TEXT, forState: .Normal)
        button.setTitleColor(MM_COLOR_ORANGE_DARK, forState: .Highlighted)
        button.layer.cornerRadius = 5
        return button
    }
    
    func inputPageControlChanged()
    {
        let newX = CGFloat(inputPageControl.currentPage) * inputScrollView.frame.size.width
        inputScrollView.setContentOffset(CGPoint(x: newX, y: inputScrollView.contentOffset.y), animated: true)
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView)
    {
        let pageNum = Int(round(scrollView.contentOffset.x / scrollView.frame.size.width))
        inputPageControl.currentPage = pageNum
    }
    
    // MARK: Header View Delegate
    func headerViewTextChanged(string: String?)
    {
        mainBag?.name = string
        do
        {
            try MMSession.sharedSession.managedObjectContext.save()
        } catch let error as NSError
        {
            print("Error saving new name: \(error.localizedDescription)")
        }
    }
    
    // MARK: Coordinate Entry
    func enterCoordinateButtonPressed()
    {
        let input = MMTextInputView(frame: CGRect(x: 0, y: mainHeader.frame.origin.y + mainHeader.frame.size.height, width: self.frame.size.width, height: 50), animated: true, backgroundType: UIBlurEffectStyle.Dark)
        input.delegate = self
        input.textField.textAlignment = .Center
        input.textField.placeholder = "34.1 -118.2 OR N34,3.8 W118,14.37"
        input.textField.keyboardType = .NumbersAndPunctuation
        input.textField.autocapitalizationType = .AllCharacters
        self.insertSubview(input, belowSubview: mainHeader)
        mainViewState = .CoordinateEntry
    }
    
    // MARK: Text Field Methods
    func textInputViewReturned(inputView: MMTextInputView, field: UITextField, string: String?)
    {
        inputView.animateViewOff { (completed, view) in
            if completed
            {
                inputView.removeFromSuperview()
            }
        }
        
        switch mainViewState
        {
        case .NewItemNaming:
            if currentPin != nil
            {
                currentPin?.name = string
                currentPin = nil
                
                do
                {
                    try MMSession.sharedSession.managedObjectContext.save()
                }
                catch let error as NSError
                {
                    print("Could not save item name: \(error.localizedDescription)")
                }
            }
            mainViewState = .None
        case .CoordinateEntry:
            guard let coordResults = string?.getCoordinatesFromString()
                else { return }
            let coordinates = CLLocationCoordinate2D(latitude: coordResults.latitude, longitude: coordResults.longitude)
            dropPinAtLocation(coordinates)
            mainViewState = .NewItemNaming
        default:
            break
        }
        inputView.delegate = nil
    }
    
    // MARK: Adding Pins
    func pinDropButtonPressed()
    {
        dropPinAtLocation(mainMap.centerCoordinate)
    }
    
    func mapViewLongPressed(pressRecog: UILongPressGestureRecognizer)
    {
        switch pressRecog.state
        {
        case .Began:
            let pos = pressRecog.locationInView(mainMap)
            let coord = mainMap.convertPoint(pos, toCoordinateFromView: mainMap)
            dropPinAtLocation(coord)
        default:
            break
        }
    }
    
    private func dropPinAtLocation(location : CLLocationCoordinate2D)
    {
        let entityDescription = NSEntityDescription.entityForName("Pin", inManagedObjectContext: MMSession.sharedSession.managedObjectContext)
        let newPin = Pin(entity: entityDescription!, insertIntoManagedObjectContext: MMSession.sharedSession.managedObjectContext)
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
            try MMSession.sharedSession.managedObjectContext.save()
        }
        catch let error as NSError
        {
            print("Error saving Core Data context: \(error.localizedDescription)")
        }
        
        mainViewState = .NewItemNaming
        currentPin = newPin
        
        let input = MMTextInputView(frame: CGRect(x: 0, y: mainHeader.frame.origin.y + mainHeader.frame.size.height, width: self.frame.size.width, height: 50), animated: true, backgroundType: UIBlurEffectStyle.Dark)
        input.delegate = self
        input.textField.textAlignment = .Center
        input.textField.placeholder = "Enter name for location"
        self.insertSubview(input, belowSubview: mainHeader)
    }
    
    // MARK: Map View Methods
    func centerMapOnUser()
    {
        mainMap.setCenterCoordinate(mainMap.userLocation.coordinate, animated: true)
    }
    
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
                view.canShowCallout = true
            }
            else
            {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: ID)
                view.canShowCallout = true
                view.draggable = true
            }
            view.animatesDrop = true
            view.draggable = true
            return view
        }
        return nil
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState)
    {
        switch newState
        {
        case .Ending:
            guard let annotation = view.annotation as? MMMapPin
                else { return }
            guard let pinID = annotation.pinID
                else { return }
            guard let pin = pinIDs?[pinID]
                else { return }
            pin.latitude = annotation.coordinate.latitude
            pin.longitude = annotation.coordinate.longitude
            
            do
            {
                try MMSession.sharedSession.managedObjectContext.save()
            }
            catch let error as NSError
            {
                print("Could not save new pin location: \(error.localizedDescription)")
            }
        default:
            break
        }
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView)
    {
        switch mainViewState
        {
        case .StartPinSelection:
            mainHeader.headerText = defaultHeaderString
            mainViewState = .DisplayingRoute
            calculateRouteFromStart(view.annotation)
        default:
            break
        }
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer
    {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = MM_COLOR_GREEN_DARK
        renderer.lineWidth = 5
        return renderer
    }
    
    private func bounceAnnotationView(annotationView: MKAnnotationView, completion:() -> Void)
    {
        let initialFrame = annotationView.frame
        let midFrame = CGRect(x: annotationView.frame.origin.x, y: annotationView.frame.origin.y - 30, width: annotationView.frame.size.width, height: annotationView.frame.size.height)
        UIView.animateWithDuration(0.2,
                                   delay: 0,
                                   options: UIViewAnimationOptions.CurveLinear,
                                   animations: {
                                    annotationView.frame = midFrame
            }) { (completed) in
                if completed
                {
                    UIView.animateWithDuration(0.5,
                                               delay: 0,
                                               usingSpringWithDamping: 0.7,
                                               initialSpringVelocity: 0.8,
                                               options: UIViewAnimationOptions.CurveLinear,
                                               animations: {
                                                annotationView.frame = initialFrame
                        },
                                               completion: { (completed) in
                                                completion()
                    })
                }
        }
    }
    
    // MARK: Routing
    func calculateRootThroughPinsButtonPressed(button: UIButton)
    {
        switch mainViewState
        {
        case .None:
            defaultHeaderString = mainHeader.headerText
            mainViewState = .StartPinSelection
            mainHeader.headerText = "Select Start Pin"
            button.setTitle("Cancel", forState: UIControlState.Normal)
        case .StartPinSelection:
            mainHeader.headerText = defaultHeaderString
            mainViewState = .None
            button.setTitle("Get Route through Pins", forState: UIControlState.Normal)
        case .DisplayingRoute:
            let overlays = mainMap.overlays
            mainMap.removeOverlays(overlays)
            button.setTitle("Get Route through Pins", forState: UIControlState.Normal)
            mainViewState = .None
        default:
            break
        }
    }
    
    private func calculateRouteFromStart(startPin: MKAnnotation?)
    {
        if startPin == nil
        {
            return
        }
        if annotationIDs == nil
        {
            return
        }
        
        var coordinates = [Coordinate]()
        
        let _ = annotationIDs!.map { coordinates.append(Coordinate(latitude: $0.1.coordinate.latitude, longitude: $0.1.coordinate.longitude)) }
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0))
        {
            let path = findShortestPath(Coordinate(latitude: startPin!.coordinate.latitude, longitude: startPin!.coordinate.longitude), points: coordinates)
            let CLPathArray = path.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
            
            if CLPathArray.isEmpty
            {
                return
            }
            
            var queue = NRQueue<CLLocationCoordinate2D>()
            let _ = CLPathArray.map { queue.pushBack($0) }
            
            var start = queue.popFront()
            while !queue.empty()
            {
                let end = queue.popFront()
                
                let request = MKDirectionsRequest()
                let startPlace = MKPlacemark(coordinate: start, addressDictionary: nil)
                let endPlace = MKPlacemark(coordinate: end, addressDictionary: nil)
                request.source = MKMapItem(placemark: startPlace)
                request.destination = MKMapItem(placemark: endPlace)
                request.requestsAlternateRoutes = false
                request.transportType = .Automobile
                
                let directions = MKDirections(request: request)
                directions.calculateDirectionsWithCompletionHandler { (response, error) in
                    
                    dispatch_async(dispatch_get_main_queue(),
                        {
                            if error == nil
                            {
                                guard let directionResponse = response
                                    else { return }
                                
                                for route in directionResponse.routes
                                {
//                                    let distanceMiles = route.distance * 0.00062137
                                    self.mainMap.addOverlay(route.polyline, level: MKOverlayLevel.AboveRoads)
//                                    self.mainMap.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 40, left: 10, bottom: 10, right: 15), animated: true)
                                }
                            }
                    })
                }
                start = end
            }
        }
    }
    
    // MARK: Fetched Results Controller Methods
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        guard let aPin = anObject as? Pin
            else { return }
        
        guard let annotation = annotationIDs?[aPin.pin_id!] as? MMMapPin
            else { return }
        
        switch (type)
        {
        case .Insert:
            break;
        case .Delete:
            mainMap.removeAnnotation(annotation)
            break;
        case .Update:
            annotation.title = aPin.name
            annotation.coordinate = CLLocationCoordinate2D(latitude: aPin.latitude, longitude: aPin.longitude)
            break
        case .Move:
            break;
        }
    }
    
    // MARK: Scroll View Delegates
    func tableViewRowSelected(tableView: UITableView, indexPath: NSIndexPath)
    {
        guard let record = mainFetchedResultsController.objectAtIndexPath(indexPath) as? Pin
            else { return }
        guard let annotation = annotationIDs?[record.pin_id!]
            else { return }
        guard let annotationView = mainMap.viewForAnnotation(annotation)
            else { return }
        annotationView.setDragState(.Starting, animated: true)
        annotationView.setDragState(.Ending, animated: true)
        
        switch mainViewState
        {
        case .StartPinSelection:
            mainHeader.headerText = defaultHeaderString
            mainViewState = .DisplayingRoute
            calculateRouteFromStart(annotationView.annotation)
        default:
            break
        }
    }
    
    func tableViewRowLongPressed(tableView: UITableView, indexPath: NSIndexPath)
    {
        guard let record = mainFetchedResultsController.objectAtIndexPath(indexPath) as? Pin
            else { return }
        currentPin = record
        
        mainViewState = .NewItemNaming
        
        let input = MMTextInputView(frame: CGRect(x: 0, y: mainHeader.frame.origin.y + mainHeader.frame.size.height, width: self.frame.size.width, height: 50), animated: true, backgroundType: UIBlurEffectStyle.Dark)
        input.delegate = self
        input.textField.textAlignment = .Center
        input.textField.text = record.name
        input.textField.placeholder = "Give this pin a new name"
        self.insertSubview(input, belowSubview: mainHeader)
    }
    
    // MARK: Navigation
    func closeViewButtonPressed()
    {
        navDelegate?.navigationDelegateViewClosed(self)
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
        cell.textLabel?.textColor = MM_COLOR_ORANGE_TEXT
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        
        let pressRecognizer = MMRowLongPressGestureRecognizer(target: self, action: #selector(self.rowLongPressed(_:)))
        pressRecognizer.minimumPressDuration = 1
        pressRecognizer.indexPath = indexPath
        cell.addGestureRecognizer(pressRecognizer)
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 45
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        selectionDelegate?.tableViewRowSelected(self, indexPath: indexPath)
    }
    
    func rowLongPressed(pressRecog: MMRowLongPressGestureRecognizer)
    {
        switch pressRecog.state
        {
        case .Began:
            guard let path = pressRecog.indexPath
                else { return }
            selectionDelegate?.tableViewRowLongPressed(self, indexPath: path)
        default:
            break
        }
    }
}

class MMRowLongPressGestureRecognizer: UILongPressGestureRecognizer
{
    internal var indexPath: NSIndexPath?
}
