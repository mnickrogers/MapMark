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
    func navigationDelegateViewClosed(_ view : UIView)
}

class MMSingleBagView : UIView, NSFetchedResultsControllerDelegate, MKMapViewDelegate, UIScrollViewDelegate, MMHeaderViewDelegate, MMBagsTableViewDelegate, MMTextInputViewDelegate, MMNavigationDelegate
{
    // MARK: Internal Types and Variables
    internal var navDelegate : MMNavigationDelegate?
    
    // MARK: Private Types and Variables
    private enum ViewState
    {
        case none
        case newItemNaming
        case coordinateEntry
        case startPinSelection
        case displayingRoute
    }
    private var locationManager = CLLocationManager()
    private var mainViewState = ViewState.none
    private var mainBag : Bag?
    private var currentPin : Pin?
    private lazy var mainFetchedResultsController : NSFetchedResultsController<Pin> =
    {
        let fetchRequest = NSFetchRequest<Pin>(entityName: "Pin")
        let predicate = NSPredicate(format: "bag = %@", self.mainBag!)
        let fetchSort = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [fetchSort]
        let controller = NSFetchedResultsController<Pin>(fetchRequest: fetchRequest, managedObjectContext: MMSession.sharedSession.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
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
        let closeButton = UIButton(type: .custom)
        closeButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        closeButton.center = CGPoint(x: 35, y: mainHeader.getHeaderLabelCenter().y)
        closeButton.setBackgroundImage(UIImage(named: "close_button_green.png"), for: UIControlState())
        closeButton.addTarget(self, action: #selector(self.closeViewButtonPressed), for: .touchUpInside)
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
        inputScrollView.isPagingEnabled = true
        inputScrollView.delegate = self

        inputPageControl = UIPageControl(frame: CGRect(x: 0, y: inputScrollView.frame.origin.y + inputScrollView.frame.size.height, width: 100, height: 15))
        inputPageControl.center = CGPoint(x: inputScrollView.center.x, y: inputPageControl.center.y)
        inputPageControl.numberOfPages = 3
        inputPageControl.pageIndicatorTintColor = UIColor.darkGray
        inputPageControl.currentPageIndicatorTintColor = MM_COLOR_ORANGE_LIGHT
        inputPageControl.addTarget(self, action: #selector(self.inputPageControlChanged), for: .valueChanged)

        inputScrollView.addSubview(getInputScrollViewItem(atPage: 1))
        inputScrollView.addSubview(getInputScrollViewItem(atPage: 2))
        inputScrollView.addSubview(getInputScrollViewItem(atPage: 3))

        // MARK: Main table view
//        mainTableView = MMSingleBagTableView(frame: CGRect(x: 0, y: inputScrollView.frame.origin.y + inputScrollView.frame.size.height + 20, width: self.frame.size.width, height: self.frame.size.height - (inputScrollView.frame.origin.y + inputScrollView.frame.size.height + 20)),
//                                             fetchedResultsController: mainFetchedResultsController.copy() as! NSFetchedResultsController,
//                                             managedObjectContext: MMSession.sharedSession.managedObjectContext)
        mainTableView = MMSingleBagTableView(frame: CGRect(x: 0, y: inputScrollView.frame.origin.y + inputScrollView.frame.size.height + 20, width: self.frame.size.width, height: self.frame.size.height - (inputScrollView.frame.origin.y + inputScrollView.frame.size.height + 20)),
                                             fetchedResultsController: mainFetchedResultsController as! NSFetchedResultsController<NSFetchRequestResult>,
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
//                if let pinItem = item as? Pin
//                {
//                }
                let pinItem = item
                let newAnnotation = MMMapPin(title: pinItem.name, ID: pinItem.pin_id, coordinate: CLLocationCoordinate2D(latitude: pinItem.latitude, longitude: pinItem.longitude))
                annotationIDs![pinItem.pin_id!] = newAnnotation
                pinIDs![pinItem.pin_id!] = pinItem
                annotations.append(newAnnotation)
                
                let annotationPoint = MKMapPointForCoordinate(newAnnotation.coordinate)
                let pointRect = MKMapRect(origin: annotationPoint, size: MKMapSize(width: 0.1, height: 0.1))
                annotationsRect = MKMapRectUnion(annotationsRect, pointRect)
            }
            let bufferRect = MKMapRect(origin: MKMapPoint(x: annotationsRect.origin.x - (annotationsRect.origin.x * 0.02), y: annotationsRect.origin.y - (annotationsRect.origin.y * 0.02)), size: MKMapSize(width: annotationsRect.size.width + ((annotationsRect.origin.x * 0.02) * 2), height: annotationsRect.size.height + ((annotationsRect.origin.y * 0.02) * 2)))
            mainMap.setVisibleMapRect(bufferRect, animated: false)
        }
        
        if annotations.isEmpty
        {
            mainMap.setCenter(CLLocationCoordinate2D(latitude: 39.8282, longitude: -98.5795), animated: false)
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
            centerLocationButton.setImage(UIImage(named: "mm_location_arrow.png")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
            centerLocationButton.imageView?.contentMode = .scaleAspectFit
            centerLocationButton.tintColor = MM_COLOR_ORANGE_LIGHT
            centerLocationButton.addTarget(self, action: #selector(self.centerMapOnUser), for: .touchUpInside)
            
            let dropPinOffset = abs(centerLocationButton.frame.size.width - centerLocationButton.frame.origin.x)
            
            let dropPinButton = configureDefaultButton()
            dropPinButton.frame = CGRect(x: dropPinButton.frame.origin.x, y: dropPinButton.frame.origin.y, width: dropPinButton.frame.size.width - dropPinOffset, height: dropPinButton.frame.size.height)
            dropPinButton.center = CGPoint(x: self.center.x * CGFloat(pageNumber) + dropPinOffset, y: dropPinButton.center.y)
            dropPinButton.setTitle("Drop Pin", for: UIControlState())
            dropPinButton.addTarget(self, action: #selector(self.pinDropButtonPressed), for: .touchUpInside)
            
            centerLocationButton.center = CGPoint(x: centerLocationButton.center.x, y: dropPinButton.center.y)
            
            view.addSubview(centerLocationButton)
            view.addSubview(dropPinButton)
            return view
        case 2:
            let coordinateEntryButton = configureDefaultButton()
            coordinateEntryButton.center = CGPoint(x: self.center.x * CGFloat(pageNumber) + (inputScrollView.frame.size.width / 2), y: coordinateEntryButton.center.y)
            coordinateEntryButton.setTitle("Enter Coordinates", for: UIControlState())
            coordinateEntryButton.addTarget(self, action: #selector(self.enterCoordinateButtonPressed), for: .touchUpInside)
            return coordinateEntryButton
        case 3:
            let calculateRouteButton = configureDefaultButton()
            calculateRouteButton.center = CGPoint(x: self.center.x * CGFloat(pageNumber) + inputScrollView.frame.size.width, y: calculateRouteButton.center.y)
            calculateRouteButton.setTitle("Get Route through Pins", for: UIControlState())
            calculateRouteButton.addTarget(self, action: #selector(self.calculateRootThroughPinsButtonPressed(_:)), for: .touchUpInside)
            return calculateRouteButton
        default:
            return UIView()
        }
    }
    
    private func configureDefaultButton() -> UIButton
    {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 15, width: self.frame.size.width * 0.8, height: 35)
        button.backgroundColor = MM_COLOR_ORANGE_BACKGROUND
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont(name: MM_FONT_MEDIUM, size: 24)
        button.setTitleColor(MM_COLOR_ORANGE_TEXT, for: UIControlState())
        button.setTitleColor(MM_COLOR_ORANGE_DARK, for: .highlighted)
        button.layer.cornerRadius = 5
        return button
    }
    
    func inputPageControlChanged()
    {
        let newX = CGFloat(inputPageControl.currentPage) * inputScrollView.frame.size.width
        inputScrollView.setContentOffset(CGPoint(x: newX, y: inputScrollView.contentOffset.y), animated: true)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {
        let pageNum = Int(round(scrollView.contentOffset.x / scrollView.frame.size.width))
        inputPageControl.currentPage = pageNum
    }
    
    // MARK: Header View Delegate
    func headerViewTextChanged(_ string: String?)
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
        let input = MMTextInputView(frame: CGRect(x: 0, y: mainHeader.frame.origin.y + mainHeader.frame.size.height, width: self.frame.size.width, height: 50), animated: true, backgroundType: UIBlurEffectStyle.dark)
        input.delegate = self
        input.textField.textAlignment = .center
        input.textField.placeholder = "34.1 -118.2 OR N34,3.8 W118,14.37"
        input.textField.keyboardType = .numbersAndPunctuation
        input.textField.autocapitalizationType = .allCharacters
        self.insertSubview(input, belowSubview: mainHeader)
        mainViewState = .coordinateEntry
    }
    
    // MARK: Text Field Methods
    func textInputViewReturned(_ inputView: MMTextInputView, field: UITextField, string: String?)
    {
        inputView.animateViewOff { (completed, view) in
            if completed
            {
                inputView.removeFromSuperview()
            }
        }
        
        switch mainViewState
        {
        case .newItemNaming:
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
            mainViewState = .none
        case .coordinateEntry:
            guard let coordResults = string?.getCoordinatesFromString()
                else { return }
            let coordinates = CLLocationCoordinate2D(latitude: coordResults.latitude, longitude: coordResults.longitude)
            dropPinAtLocation(coordinates)
            mainViewState = .newItemNaming
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
    
    func mapViewLongPressed(_ pressRecog: UILongPressGestureRecognizer)
    {
        switch pressRecog.state
        {
        case .began:
            let pos = pressRecog.location(in: mainMap)
            let coord = mainMap.convert(pos, toCoordinateFrom: mainMap)
            dropPinAtLocation(coord)
        default:
            break
        }
    }
    
    private func dropPinAtLocation(_ location : CLLocationCoordinate2D)
    {
        let entityDescription = NSEntityDescription.entity(forEntityName: "Pin", in: MMSession.sharedSession.managedObjectContext)
        let newPin = Pin(entity: entityDescription!, insertInto: MMSession.sharedSession.managedObjectContext)
        newPin.name = "New Pin"
        newPin.latitude = location.latitude
        newPin.longitude = location.longitude
        newPin.bag = mainBag
        mainBag?.updateLastEdited()
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
        
        mainViewState = .newItemNaming
        currentPin = newPin
        
        let input = MMTextInputView(frame: CGRect(x: 0, y: mainHeader.frame.origin.y + mainHeader.frame.size.height, width: self.frame.size.width, height: 50), animated: true, backgroundType: UIBlurEffectStyle.dark)
        input.delegate = self
        input.textField.textAlignment = .center
        input.textField.placeholder = "Enter name for location"
        self.insertSubview(input, belowSubview: mainHeader)
    }
    
    // MARK: Map View Methods
    
    private func pinEntityFromAnnotationView(_ annotationView: MKAnnotationView) -> Pin?
    {
        guard let annotation = annotationView.annotation as? MMMapPin
            else { return nil }
        guard let pinID = annotation.pinID
            else { return nil }
        guard let pin = pinIDs?[pinID]
            else { return nil }
        return pin
    }
    
    func centerMapOnUser()
    {
        mainMap.setCenter(mainMap.userLocation.coordinate, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        if let annotation = annotation as? MMMapPin
        {
            let ID = "pin_id"
            var view : MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: ID) as? MKPinAnnotationView
            {
                dequeuedView.annotation = annotation
                view = dequeuedView
                view.canShowCallout = true
            }
            else
            {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: ID)
                view.canShowCallout = true
                view.isDraggable = true
                
                let infoButton = UIButton(type: .detailDisclosure)
                infoButton.tintColor = MM_COLOR_BLUE_DARK
                view.rightCalloutAccessoryView = infoButton
            }
            view.animatesDrop = true
            view.isDraggable = true
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState)
    {
        switch newState
        {
        case .ending:
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
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl)
    {
        guard let pinEntity = pinEntityFromAnnotationView(view)
            else { return }
        
        let descriptionView = MMPinDescriptionView(frame: CGRect().zeroBoundedRect(self.frame), pinEntity: pinEntity)
        descriptionView.navDelegate = self
        self.addSubview(descriptionView)
        
        descriptionView.frame = CGRect().frameBeneathFrame(CGRect().zeroBoundedRect(self.frame), beneathFrame: self.frame)
        UIView.animate(withDuration: 0.2,
                                   delay: 0,
                                   options: UIViewAnimationOptions.curveEaseOut,
                                   animations: { 
                                    descriptionView.frame = CGRect().zeroBoundedRect(self.frame)
            },
                                   completion: nil)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)
    {
        switch mainViewState
        {
        case .startPinSelection:
            mainHeader.headerText = defaultHeaderString
            mainViewState = .displayingRoute
            calculateRouteFromStart(view.annotation)
        default:
            break
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer
    {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = MM_COLOR_GREEN_DARK
        renderer.lineWidth = 5
        return renderer
    }
    
    private func bounceAnnotationView(_ annotationView: MKAnnotationView, completion:@escaping () -> Void)
    {
        let initialFrame = annotationView.frame
        let midFrame = CGRect(x: annotationView.frame.origin.x, y: annotationView.frame.origin.y - 30, width: annotationView.frame.size.width, height: annotationView.frame.size.height)
        UIView.animate(withDuration: 0.2,
                                   delay: 0,
                                   options: UIViewAnimationOptions.curveLinear,
                                   animations: {
                                    annotationView.frame = midFrame
            }) { (completed) in
                if completed
                {
                    UIView.animate(withDuration: 0.5,
                                               delay: 0,
                                               usingSpringWithDamping: 0.7,
                                               initialSpringVelocity: 0.8,
                                               options: UIViewAnimationOptions.curveLinear,
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
    func calculateRootThroughPinsButtonPressed(_ button: UIButton)
    {
        switch mainViewState
        {
        case .none:
            defaultHeaderString = mainHeader.headerText
            mainViewState = .startPinSelection
            mainHeader.headerText = "Select Start Pin"
            button.setTitle("Clear", for: UIControlState())
        case .startPinSelection:
            mainHeader.headerText = defaultHeaderString
            mainViewState = .none
            button.setTitle("Get Route through Pins", for: UIControlState())
        case .displayingRoute:
            let overlays = mainMap.overlays
            mainMap.removeOverlays(overlays)
            button.setTitle("Get Route through Pins", for: UIControlState())
            mainViewState = .none
        default:
            break
        }
    }
    
    private func calculateRouteFromStart(_ startPin: MKAnnotation?)
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
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async
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
                request.transportType = .automobile
                
                let directions = MKDirections(request: request)
                directions.calculate { (response, error) in
                    
                    DispatchQueue.main.async(execute: {
                            if error == nil
                            {
                                guard let directionResponse = response
                                    else { return }
                                
                                for route in directionResponse.routes
                                {
//                                    let distanceMiles = route.distance * 0.00062137
                                    self.mainMap.add(route.polyline, level: MKOverlayLevel.aboveRoads)
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
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let aPin = anObject as? Pin
            else { return }
        
        guard let annotation = annotationIDs?[aPin.pin_id!] as? MMMapPin
            else { return }
        
        switch (type)
        {
        case .insert:
            break;
        case .delete:
            mainMap.removeAnnotation(annotation)
            break;
        case .update:
            annotation.title = aPin.name
            annotation.coordinate = CLLocationCoordinate2D(latitude: aPin.latitude, longitude: aPin.longitude)
            break
        case .move:
            break;
        }
    }
    
    // MARK: Table View Delegates
    func tableViewRowSelected(_ tableView: UITableView, indexPath: IndexPath)
    {
        let record = mainFetchedResultsController.object(at: indexPath)
        guard let annotation = annotationIDs?[record.pin_id!]
            else { return }
//        let annotationView = mainMap.viewForAnnotation(annotation)
        
//        Bounce annotation
//        annotationView.setDragState(.Starting, animated: true)
//        annotationView.setDragState(.Ending, animated: true)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
        mainMap.setRegion(region, animated: true)
        
        mainMap.selectAnnotation(annotation, animated: true)
        
        switch mainViewState
        {
        case .startPinSelection:
            mainHeader.headerText = defaultHeaderString
            mainViewState = .displayingRoute
            calculateRouteFromStart(annotation)
        default:
            break
        }
    }
    
    func tableViewRowLongPressed(_ tableView: UITableView, indexPath: IndexPath)
    {
        let record = mainFetchedResultsController.object(at: indexPath)
        currentPin = record
        
        mainViewState = .newItemNaming
        
        let input = MMTextInputView(frame: CGRect(x: 0, y: mainHeader.frame.origin.y + mainHeader.frame.size.height, width: self.frame.size.width, height: 50), animated: true, backgroundType: UIBlurEffectStyle.dark)
        input.delegate = self
        input.textField.textAlignment = .center
        input.textField.text = record.name
        input.textField.placeholder = "Give this pin a new name"
        self.insertSubview(input, belowSubview: mainHeader)
    }
    
    func tableViewActionViewItemSelected(_ tableView: UITableView, indexPath: IndexPath, actionType: MMTableViewActionTypes)
    {
        let record = mainFetchedResultsController.object(at: indexPath)
        
        switch actionType
        {
        case .move:
            let qView = MMQuickView(frame: CGRect().frameBeneathFrame(self.frame, beneathFrame: self.frame), chosenPin: record)
            qView.navDelegate = self
            qView.alpha = 0
            self.addSubview(qView)
            
            UIView.animate(withDuration: 0.2,
                                       delay: 0,
                                       options: UIViewAnimationOptions.curveEaseOut,
                                       animations: {
                                        qView.frame = CGRect().zeroBoundedRect(self.frame)
                                        qView.alpha = 1
                },
                                       completion: nil)
        }
    }
    
    // MARK: Navigation
    func closeViewButtonPressed()
    {
        navDelegate?.navigationDelegateViewClosed(self)
    }
    
    func navigationDelegateViewClosed(_ view: UIView)
    {
//        if let moveView = view as? MMQuickView
//        {
//        }
        
        UIView.animate(withDuration: 0.25,
                                   delay: 0,
                                   options: UIViewAnimationOptions.curveEaseOut,
                                   animations: {
                                    view.frame = CGRect(x: 0, y: self.frame.size.height, width: view.frame.size.width, height: view.frame.size.height)
                                    view.alpha = 0
            },
                                   completion: { (completed) in
                                    if completed
                                    {
                                        view.removeFromSuperview()
                                    }
        })
    }
}

class MMSingleBagTableView: MMDefaultFetchedResultsTableView
{
    internal var selectionDelegate : MMBagsTableViewDelegate?
    
    override func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath)
    {
        super.configureCell(cell, atIndexPath: indexPath)
        
        let pressRecognizer = MMRowLongPressGestureRecognizer(target: self, action: #selector(self.rowLongPressed(_:)))
        pressRecognizer.minimumPressDuration = 1
        pressRecognizer.indexPath = indexPath
        cell.addGestureRecognizer(pressRecognizer)
        
        cell.textLabel?.textColor = MM_COLOR_ORANGE_TEXT
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        
        if let record = fetchedResultsController.object(at: indexPath) as? Pin
        {
            cell.textLabel?.text = record.name
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAtIndexPath indexPath: IndexPath) -> CGFloat
    {
        return 45
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        super.tableView(tableView, didSelectRowAt: indexPath)
        selectionDelegate?.tableViewRowSelected(self, indexPath: indexPath)
    }
    
    func rowLongPressed(_ pressRecog: MMRowLongPressGestureRecognizer)
    {
        switch pressRecog.state
        {
        case .began:
            guard let path = pressRecog.indexPath
                else { return }
            selectionDelegate?.tableViewRowLongPressed(self, indexPath: path)
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAtIndexPath indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        let editAction = UITableViewRowAction(style: .normal, title: "Move") { (rowAction, indexPath) in
            self.selectionDelegate?.tableViewActionViewItemSelected(self, indexPath: indexPath, actionType: .move)
        }
        editAction.backgroundColor = MM_COLOR_BLUE_DARK
        
        let deleteAction = UITableViewRowAction(style: .normal, title: "Delete") { (rowAction, indexPath) in
            super.deleteObject(indexPath)
        }
        deleteAction.backgroundColor = MM_COLOR_RED_DARK
        
        return [deleteAction, editAction]
    }
}

class MMRowLongPressGestureRecognizer: UILongPressGestureRecognizer
{
    internal var indexPath: IndexPath?
}
