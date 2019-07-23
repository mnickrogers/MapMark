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

/// A protocol for default navigation communication between views.
protocol MMNavigationDelegate
{
    /// Called when a view is requesting that it be closed by its superview.
    func navigationDelegateViewClosed(_ view : UIView)
}

/// A view for displaying the contents of a single bag.
class MMSingleBagView : UIView, NSFetchedResultsControllerDelegate, MKMapViewDelegate, UIScrollViewDelegate, MMHeaderViewDelegate, MMBagsTableViewDelegate, MMTextInputViewDelegate, MMNavigationDelegate
{
    // MARK: Internal Types and Variables
    
    /// The navigation delegate for this view.
    internal var navDelegate : MMNavigationDelegate?
    
    // MARK: Private Types and Variables
    
    /// The state used to describe the user's interaction with this view. A user can be changing a pin's name, entering coordinates for a new pin, starting to select a pin or displaying a route. These states alter the way interface elements behave in accordinate with the way a user would expect them to behave based on the current way the user is interacting with the view.
    private enum ViewState
    {
        /// The user is not engaging in a specific activity that requires changing the interface's default behavior.
        case none
        /// The user is in the process of adding a new pin to this bag of pins.
        case newItemNaming
        /// The user is entering in coordinates for a new pin.
        case coordinateEntry
        /// The user is starting to select a pin on the map.
        case startPinSelection
        /// The user is viewing and the map is presenting a route through all of the pins.
        case displayingRoute
    }
    
    /// The location manager for this view.
    private var locationManager = CLLocationManager()
    
    /// The state that describes the way the user is interacting with this view.
    private var mainViewState = ViewState.none
    
    /// The main bag from which the pins in this view are loaded.
    private var mainBag: Bag?
    
    /// The pin that a user is currently adding.
    private var currentPin: Pin?
    
    /// The fetched results controller used to load and update the pins that are stored in this bag.
    private lazy var mainFetchedResultsController: NSFetchedResultsController<Pin> =
    {
        let fetchRequest = NSFetchRequest<Pin>(entityName: "Pin")
        // Load pins for this view's bag.
        let predicate = NSPredicate(format: "bag = %@", self.mainBag!)
        // Sort pins alphabetically by their name.
        let fetchSort = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [fetchSort]
        let controller = NSFetchedResultsController<Pin>(fetchRequest: fetchRequest, managedObjectContext: MMSession.sharedSession.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        return controller
    }()
    
    /// The table used to present the pins for this view's bag.
    private var mainTableView: MMSingleBagTableView!
    
    /// The navigation header at the top of this view.
    private var mainHeader: MMHeaderView!
    
    /// The horizontal scroll view beneath this view's "mainMap" used to display options for interacting with pins from this bag.
    private var inputScrollView: UIScrollView!
    
    /// The page controll that displays the current "page" the user has scrolled this view's "inputScrollView" to; this view's "inputScrollView" has paging enabled.
    private var inputPageControl: UIPageControl!
    
    /// The map used to display this view's bag's pins.
    private var mainMap: MKMapView!
    
    /// A dictionary associating an MKAnnotation to a specific ID for that annotation. This will be used to fetch annotations that users have selected.
    private var annotationIDs: [String : MKAnnotation]?
    
    /// A dictionary associating a pin to a specific ID. This will be used to associate annotations with their coresponding pin.
    private var pinIDs: [String : Pin]?
    
    /// The default string for this view's navigation header view. Since different values of "ViewState" will alter the navigation view's header text, a default is necessary to restore the navigation header's text when mainViewState = ViewState.none.
    private var defaultHeaderString: String?
    
    /// Initialize this MMSingleBagView.
    init(frame: CGRect, bag: Bag)
    {
        super.init(frame: frame)
        
        // Set the mainBag equal to the supplied bag.
        mainBag = bag
        
        // Assign the delegate for this NSFetchedResultsController to this view so that this view will handle changes to the CoreData model.
        mainFetchedResultsController.delegate = self
        
        
        // Fetch the appropriate data from the CoreData model.
        do
        {
            try mainFetchedResultsController.performFetch()
        }
        catch let error as NSError
        {
            print("Could not fetch items: \(error.localizedDescription)")
        }
        
        // MARK: User location
        
        // Request this user's location while the app is in use.
        locationManager.requestWhenInUseAuthorization()
        
        // MARK: Header
        
        // Set up the navigation header view.
        mainHeader = MMHeaderView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: 50))
        mainHeader.headerText = mainBag?.name ?? "Tap to name"
        mainHeader.delegate = self
        
        // MARK: Background
        let mainBackground = UIView(frame: CGRect(x: 0, y: mainHeader.frame.origin.y + mainHeader.frame.size.height, width: self.frame.size.width, height: self.frame.size.height - mainHeader.frame.size.height))
        mainBackground.backgroundColor = MM_COLOR_BASE
        self.addSubview(mainBackground)

        // MARK: Close button
        
        // This button will be used to signal to this view's superview that this view should be closed.
        let closeButton = UIButton(type: .custom)
        closeButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        closeButton.center = CGPoint(x: 35, y: mainHeader.getHeaderLabelCenter().y)
        closeButton.setBackgroundImage(UIImage(named: "close_button_green.png"), for: UIControl.State())
        closeButton.addTarget(self, action: #selector(self.closeViewButtonPressed), for: .touchUpInside)
        mainHeader.addSubview(closeButton)
        
        // MARK: Map
        
        // Use this to handle long-presses to this view's "mainMap" view.
        let longPressRecog = UILongPressGestureRecognizer(target: self, action: #selector(self.mapViewLongPressed(_:)))
        longPressRecog.minimumPressDuration = 1
        longPressRecog.cancelsTouchesInView = false
        
        
        // Create the map for displaying this view's bag's pins.
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

        // Set this view's "inputScrollView"'s different sections to the appropriate collection of views.
        inputScrollView.addSubview(getInputScrollViewItem(atPage: 1))
        inputScrollView.addSubview(getInputScrollViewItem(atPage: 2))
        inputScrollView.addSubview(getInputScrollViewItem(atPage: 3))

        // MARK: Main table view
        
        // Set up this view's table view.
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
        
        var annotations = [MKAnnotation]()
        
        if mainFetchedResultsController.fetchedObjects != nil
        {
            for item in mainFetchedResultsController.fetchedObjects!
            {
                let pinItem = item
                // Create annotations from the pins in this bag.
                let newAnnotation = MMMapPin(title: pinItem.name, ID: pinItem.pin_id, coordinate: CLLocationCoordinate2D(latitude: pinItem.latitude, longitude: pinItem.longitude))
                
                // Associate the annotation with its corresponding ID in this view's "annotationIDs" dictionary.
                annotationIDs![pinItem.pin_id!] = newAnnotation
                
                // Associate the pin with its corresponding ID in this view's "pinIDs" dictionary.
                pinIDs![pinItem.pin_id!] = pinItem
                
                // Add those pins to the array of annotations.
                annotations.append(newAnnotation)
            }
        }
        
        // If there are no annotations, set the map center to the center of the United States.
        if annotations.isEmpty
        {
            mainMap.setCenter(CLLocationCoordinate2D(latitude: 39.8282, longitude: -98.5795), animated: false)
        }
        
        // Add the annotations from the annotations array to this view.
        mainMap.addAnnotations(annotations)
        
        // Zoom the map to show all of the added annotations.
        mainMap.showAnnotations(mainMap.annotations, animated: false)
    }
    
    override func removeFromSuperview() // Some delegate references cause retain cycles (probably because some of Apple's protocols still declare @objc conformance and are thus treated like classes).
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
    
    /// Generate the appropriate collection of views for different sections for this view's "inputScrollView".
    private func getInputScrollViewItem(atPage pageNumber : Int) -> UIView
    {
        switch pageNumber
        {
        case 1:
            // The first section contains a center location button and a new pin button.
            
            // Create the container view for this section's views.
            let view = UIView(frame: CGRect().zeroBoundedRect(inputScrollView.frame))
            
            // This button will allow the user to center this view's "mainMap" on the user's current location.
            let centerLocationButton = configureDefaultButton()
            centerLocationButton.frame = CGRect(x: (self.frame.size.width - (self.frame.size.width * 0.8)) / 4, y: 0, width: centerLocationButton.frame.size.height + 15, height: centerLocationButton.frame.size.height)
            centerLocationButton.setImage(UIImage(named: "mm_location_arrow.png")?.withRenderingMode(.alwaysTemplate), for: UIControl.State())
            centerLocationButton.imageView?.contentMode = .scaleAspectFit
            centerLocationButton.tintColor = MM_COLOR_ORANGE_LIGHT
            centerLocationButton.addTarget(self, action: #selector(self.centerMapOnUser), for: .touchUpInside)
            
            // The amount that the drop pin should be offset so that the distance between its right edge and the left edge of the "centerLocationButton" are equidistant to the side of the view.
            let dropPinOffset = abs(centerLocationButton.frame.size.width - centerLocationButton.frame.origin.x)
            
            // This button will allow the user to drop a new pin at the center of this view's "mainMap".
            let dropPinButton = configureDefaultButton()
            dropPinButton.frame = CGRect(x: dropPinButton.frame.origin.x, y: dropPinButton.frame.origin.y, width: dropPinButton.frame.size.width - dropPinOffset, height: dropPinButton.frame.size.height)
            dropPinButton.center = CGPoint(x: self.center.x * CGFloat(pageNumber) + dropPinOffset, y: dropPinButton.center.y)
            dropPinButton.setTitle("Drop Pin", for: UIControl.State())
            dropPinButton.addTarget(self, action: #selector(self.pinDropButtonPressed), for: .touchUpInside)
            
            centerLocationButton.center = CGPoint(x: centerLocationButton.center.x, y: dropPinButton.center.y)
            
            view.addSubview(centerLocationButton)
            view.addSubview(dropPinButton)
            return view
        case 2:
            // This view will contain a button that allows users to create a new pin and add that new pin to this view's bag by specifying the new pin's coordinates.
            
            let coordinateEntryButton = configureDefaultButton()
            coordinateEntryButton.center = CGPoint(x: self.center.x * CGFloat(pageNumber) + (inputScrollView.frame.size.width / 2), y: coordinateEntryButton.center.y)
            coordinateEntryButton.setTitle("Enter Coordinates", for: UIControl.State())
            coordinateEntryButton.addTarget(self, action: #selector(self.enterCoordinateButtonPressed), for: .touchUpInside)
            return coordinateEntryButton
        case 3:
            
            // This view will contain a button that allows the user to calculate a route through all the pins in this bag. This route will be displayed in this view's "mainMap" view.
            let calculateRouteButton = configureDefaultButton()
            calculateRouteButton.center = CGPoint(x: self.center.x * CGFloat(pageNumber) + inputScrollView.frame.size.width, y: calculateRouteButton.center.y)
            calculateRouteButton.setTitle("Get Route through Pins", for: UIControl.State())
            calculateRouteButton.addTarget(self, action: #selector(self.calculateRootThroughPinsButtonPressed(_:)), for: .touchUpInside)
            return calculateRouteButton
        default:
            return UIView()
        }
    }
    
    /// This method will create and configure a default button with a look and feel that corresponds to the UI of this view.
    private func configureDefaultButton() -> UIButton
    {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 15, width: self.frame.size.width * 0.8, height: 35)
        button.backgroundColor = MM_COLOR_ORANGE_BACKGROUND
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont(name: MM_FONT_MEDIUM, size: 24)
        button.setTitleColor(MM_COLOR_ORANGE_TEXT, for: UIControl.State())
        button.setTitleColor(MM_COLOR_ORANGE_DARK, for: .highlighted)
        button.layer.cornerRadius = 5
        return button
    }
    
    /// Call this function when the inputPageControll view recieves an update (a tap from the user) to move this view's "inputScrollView" to the new position requested by the user.
    @objc func inputPageControlChanged()
    {
        let newX = CGFloat(inputPageControl.currentPage) * inputScrollView.frame.size.width
        inputScrollView.setContentOffset(CGPoint(x: newX, y: inputScrollView.contentOffset.y), animated: true)
    }
    
    /// Determine the page number when this view's "inputScrollView" has been swiped.
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {
        let pageNum = Int(round(scrollView.contentOffset.x / scrollView.frame.size.width))
        // Update the page control.
        inputPageControl.currentPage = pageNum
    }
    
    // MARK: Header View Delegate
    
    /// Handle changes to this view's navigation header text. Since this text displays the name of this view's bag, if the name is changed, the name of the bag is changed. The user changes this name by tapping the navigation header view.
    func headerViewTextChanged(_ string: String?)
    {
        // Update the name of the bag to match the new name created by the user.
        mainBag?.name = string
        
        // Save the bag's name change to the CoreData model.
        do
        {
            try MMSession.sharedSession.managedObjectContext.save()
        } catch let error as NSError
        {
            print("Error saving new name: \(error.localizedDescription)")
        }
    }
    
    // MARK: Coordinate Entry
    
    /// Handle a user requesting to create a new pin for this view's bag by specifying coordinates.
    @objc func enterCoordinateButtonPressed()
    {
        // Load an input text view at the top of this view.
        let input = MMTextInputView(frame: CGRect(x: 0, y: mainHeader.frame.origin.y + mainHeader.frame.size.height, width: self.frame.size.width, height: 50), animated: true, backgroundType: UIBlurEffect.Style.dark)
        input.delegate = self
        input.textField.textAlignment = .center
        input.textField.placeholder = "34.1 -118.2 OR N34,3.8 W118,14.37"
        input.textField.keyboardType = .numbersAndPunctuation
        input.textField.autocapitalizationType = .allCharacters
        self.insertSubview(input, belowSubview: mainHeader)
        
        // Since the user has requested to create a new pin for this view's bag by entering coordinates, the current state of this view is equal to "coordinateEntry" until the user has completed the steps to create the new pin via specified coordinates.
        mainViewState = .coordinateEntry
    }
    
    // MARK: Text Field Methods
    
    // Called when the input text view is done being updated by the user. This will cause different actions depending on the value of this view's "mainViewState".
    func textInputViewReturned(_ inputView: MMTextInputView, field: UITextField, string: String?)
    {
        // Animate the text view off the screen.
        inputView.animateViewOff { (completed, view) in
            if completed
            {
                inputView.removeFromSuperview()
            }
        }
        
        switch mainViewState
        {
        case .newItemNaming:
            // If the user has just added a new pin, that pin needs a name. Thus, the text returned from the input view should be used to signal that name.
            
            if currentPin != nil
            {
                currentPin?.name = string
                currentPin = nil
                
                // Update the core data model with the pin's name.
                do
                {
                    try MMSession.sharedSession.managedObjectContext.save()
                }
                catch let error as NSError
                {
                    print("Could not save item name: \(error.localizedDescription)")
                }
            }
            
            // Return this view's "mainViewState" to normal since entering a name is the last step in adding a new pin to this view's bag.
            mainViewState = .none
        case .coordinateEntry:
            // If the user has just entered coordinates for a new pin into the text input view, convert that text into coordinates and assign them to the newly created pin.
            
            guard let coordResults = string?.getCoordinatesFromString()
                else { return }
            let coordinates = CLLocationCoordinate2D(latitude: coordResults.latitude, longitude: coordResults.longitude)
            
            // Add the pin to this map view based on the new coordinates entered.
            dropPinAtLocation(coordinates)
            
            // After the user has entered coordinates for a new pin, the user must then create a name for that pin, so the next state for this view is "newItemNaming".
            mainViewState = .newItemNaming
        default:
            break
        }
        
        // Remove that input view's delegate to prevent a retain cycle. Shouldn't be necessary since this protocol is a pure-Swift protocol. Need more testing here; better safe than sorry for now.
        inputView.delegate = nil
    }
    
    // MARK: Adding Pins
    
    /// Handle the drop pin button being pressed.
    @objc func pinDropButtonPressed()
    {
        dropPinAtLocation(mainMap.centerCoordinate)
    }
    
    /// If the map view is long-pressed, add a new pin at the location of the touch.
    @objc func mapViewLongPressed(_ pressRecog: UILongPressGestureRecognizer)
    {
        switch pressRecog.state
        {
        case .began:
            // Get the location of the touch within this view's "mainMap" view.
            let pos = pressRecog.location(in: mainMap)
            
            // Convert the location to coordinates in this view's "mainMap" coordinate system.
            let coord = mainMap.convert(pos, toCoordinateFrom: mainMap)
            
            // Addd a pin at the selected location.
            dropPinAtLocation(coord)
        default:
            break
        }
    }
    
    /// Add a pin at a specific location in this view's "mainMap" view.
    private func dropPinAtLocation(_ location : CLLocationCoordinate2D)
    {
        // Insert a new pin entity into the CoreData model.
        let entityDescription = NSEntityDescription.entity(forEntityName: "Pin", in: MMSession.sharedSession.managedObjectContext)
        
        // Assign the new pin all of the corresponding data provided by the user.
        let newPin = Pin(entity: entityDescription!, insertInto: MMSession.sharedSession.managedObjectContext)
        newPin.name = "New Pin"
        newPin.latitude = location.latitude
        newPin.longitude = location.longitude
        newPin.bag = mainBag
        
        // Update the dictionaries containing information used to lookup and match pins to annotations on this view's "mainMap" view.
        mainBag?.updateLastEdited()
        pinIDs![newPin.pin_id!] = newPin
        
        // Create a new annotation for this new pin.
        let newAnnotation = MMMapPin(title: newPin.name, ID: newPin.pin_id, coordinate: CLLocationCoordinate2D(latitude: newPin.latitude, longitude: newPin.longitude))
        annotationIDs![newPin.pin_id!] = newAnnotation
        
        // Add that new annotation to this view's "mainMap" view.
        mainMap.addAnnotation(newAnnotation)
        
        // Save that core data model.
        do
        {
            try MMSession.sharedSession.managedObjectContext.save()
        }
        catch let error as NSError
        {
            print("Error saving Core Data context: \(error.localizedDescription)")
        }
        
        // After a new pin has been added to this view's "mainMap" view, it needs to be named.
        mainViewState = .newItemNaming
        
        // Set this view's "currentPin" to the newly created pin so that it can be updated.
        currentPin = newPin
        
        // Create a text input view to get the name for this new pin.
        let input = MMTextInputView(frame: CGRect(x: 0, y: mainHeader.frame.origin.y + mainHeader.frame.size.height, width: self.frame.size.width, height: 50), animated: true, backgroundType: UIBlurEffect.Style.dark)
        input.delegate = self
        input.textField.textAlignment = .center
        input.textField.placeholder = "Enter name for location"
        
        // Add this input view beneath this view's navigation header.
        self.insertSubview(input, belowSubview: mainHeader)
    }
    
    // MARK: Map View Methods
    
    /// Get a pin from a specific annotation view from this view's "mainMap" view.
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
    
    /// Center this view's "mainMap" view on the user.
    @objc func centerMapOnUser()
    {
        mainMap.setCenter(mainMap.userLocation.coordinate, animated: true)
    }
    
    /// Used for adding an annotation to this view's "mainMap" view.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        if let annotation = annotation as? MMMapPin
        {
            let ID = "pin_id"
            var view : MKPinAnnotationView
            
            // Dequeue an annotation view from this view's "mainMap" view, else create one.
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
                
                // Add an info button to the annotation's callout view. This will be used to display a view that shows and edits a pin's description.
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
    
    /// Allows annotations to be dragged around this view's "mainMap" view by the user.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState)
    {
        switch newState
        {
        case .ending:
            // Once the user is done dragging, update the pin's location by fetching the annotation view's corresponding pin.
            
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
    
    /// When an annotation's callout view is tapped, load a view that will allow the user to change the pin's name and description.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl)
    {
        guard let pinEntity = pinEntityFromAnnotationView(view)
            else { return }
        
        // Load the description view for this selected pin.
        let descriptionView = MMPinDescriptionView(frame: CGRect().zeroBoundedRect(self.frame), pinEntity: pinEntity)
        descriptionView.navDelegate = self
        self.addSubview(descriptionView)
        
        // Animate that description view on.
        descriptionView.frame = CGRect().frameBeneathFrame(CGRect().zeroBoundedRect(self.frame), beneathFrame: self.frame)
        UIView.animate(withDuration: 0.2,
                                   delay: 0,
                                   options: UIView.AnimationOptions.curveEaseOut,
                                   animations: { 
                                    descriptionView.frame = CGRect().zeroBoundedRect(self.frame)
            },
                                   completion: nil)
    }
    
    /// Handle pin selection.
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
    
    /// Render an overlay for this view's "mainMap" view when a route has been plotted between all pins in this view's bag.
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer
    {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = MM_COLOR_GREEN_DARK
        renderer.lineWidth = 5
        return renderer
    }
    
    /// Bounces an annotation view and calls a closure when it is done bouncing. Use this method to call attention to a pin on the map, such as when its corresponding name is selected in the scroll view.
    private func bounceAnnotationView(_ annotationView: MKAnnotationView, completion:@escaping () -> Void)
    {
        // Store the initial frame of the annotation view; use this to complete the bounce.
        let initialFrame = annotationView.frame
        let midFrame = CGRect(x: annotationView.frame.origin.x, y: annotationView.frame.origin.y - 30, width: annotationView.frame.size.width, height: annotationView.frame.size.height)
        
        // Move the annotation view up.
        UIView.animate(withDuration: 0.2,
                                   delay: 0,
                                   options: UIView.AnimationOptions.curveLinear,
                                   animations: {
                                    annotationView.frame = midFrame
            }) { (completed) in
                if completed
                {
                    // After moving the annotation view up, bounce it back down to its original position.
                    UIView.animate(withDuration: 0.5,
                                               delay: 0,
                                               usingSpringWithDamping: 0.7,
                                               initialSpringVelocity: 0.8,
                                               options: UIView.AnimationOptions.curveLinear,
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
    
    /// Handle when the user selects to calculate a route through all of the pins in this view's bag.
    @objc func calculateRootThroughPinsButtonPressed(_ button: UIButton)
    {
        switch mainViewState
        {
        case .none:
            // When the button is first pressed, the user will need to select a starting pin from this view's "mainMap".
            
            defaultHeaderString = mainHeader.headerText
            
            mainViewState = .startPinSelection
            mainHeader.headerText = "Select Start Pin"
            
            // Update the button to match the new state for this view so that when it is tapped next, it will clear the route from this view's "mainMap" view and restore the rest of the view to its default state.
            button.setTitle("Clear", for: UIControl.State())
            
        case .startPinSelection:
            // Afer the user has selected a pin from this view's "mainMap" as the start pin, reset this view's navigation header and reset the button's title. Then, return this view's "viewState" to normal.
            
            mainHeader.headerText = defaultHeaderString
            mainViewState = .none
            button.setTitle("Get Route through Pins", for: UIControl.State())
        case .displayingRoute:
            // If this view is currently displaying a route, clear the route and reset this view to its default state.
            
            let overlays = mainMap.overlays
            mainMap.removeOverlays(overlays)
            button.setTitle("Get Route through Pins", for: UIControl.State())
            mainViewState = .none
        default:
            break
        }
    }
    
    /// Calculate a route through all the pins in this view's bag with a specific pin as its starting point.
    private func calculateRouteFromStart(_ startPin: MKAnnotation?)
    {
        // If there is no start point, return.
        if startPin == nil
        {
            return
        }
        
        // If there is not a dictionary of annotationIDs that associate annotationIDs with their corresponding annotation, return.
        if annotationIDs == nil
        {
            return
        }
        
        var coordinates = [Coordinate]()
        
        let _ = annotationIDs!.map { coordinates.append(Coordinate(latitude: $0.1.coordinate.latitude, longitude: $0.1.coordinate.longitude)) }
        
        // Run the searching and sorting processes so they are non-blocking on a background thread.
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async
        {
            let path = findShortestPath(Coordinate(latitude: startPin!.coordinate.latitude, longitude: startPin!.coordinate.longitude), points: coordinates)
            let CLPathArray = path.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
            
            if CLPathArray.isEmpty
            {
                return
            }
            
            // Use a queue to order the coordinates for navigating.
            var queue = NRQueue<CLLocationCoordinate2D>()
            let _ = CLPathArray.map { queue.pushBack($0) }
            
            var start = queue.popFront()
            while !queue.empty()
            {
                let end = queue.popFront()
                
                let request = MKDirections.Request()
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
                                    self.mainMap.addOverlay(route.polyline, level: MKOverlayLevel.aboveRoads)
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
    
    /// Perform updates to the annotations and this view's "mainMap" view when the CoreData model changes.
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
            // If a pin is deleted, remove it from this view's "mainMap" view.
            
            mainMap.removeAnnotation(annotation)
            break;
        case .update:
            // If a pin has its value updated (name and or coordinates), update it on this view's "mainMap" view.
            
            annotation.title = aPin.name
            annotation.coordinate = CLLocationCoordinate2D(latitude: aPin.latitude, longitude: aPin.longitude)
            break
        case .move:
            break;
        }
    }
    
    // MARK: Table View Delegates
    
    /// Handle a selection in this view's "mainTableView".
    func tableViewRowSelected(_ tableView: UITableView, indexPath: IndexPath)
    {
        // Get the entity selected from this view's "mainTableView".
        let record = mainFetchedResultsController.object(at: indexPath)
        
        // Get the annotation associated with the pin entity selected in this view's "mainTableView".
        guard let annotation = annotationIDs?[record.pin_id!]
            else { return }
//        let annotationView = mainMap.viewForAnnotation(annotation)
        
//        Bounce annotation
//        annotationView.setDragState(.Starting, animated: true)
//        annotationView.setDragState(.Ending, animated: true)
        
        // Create a region around the selected annotation that corresponds with the selected pin entity.
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
        mainMap.setRegion(region, animated: true)
        
        // Select that annotation on this view's "mainMap" view.
        mainMap.selectAnnotation(annotation, animated: true)
        
        switch mainViewState
        {
        case .startPinSelection:
            // If the user is currently selecting a pin as the start point for a route through all of the pins in this view's bag, then update this view's navigation header text and start calculating the route from that selected pin.
            
            mainHeader.headerText = defaultHeaderString
            
            // The next state this view will enter is to display the route.
            mainViewState = .displayingRoute
            
            // Begin calculating a route through all the pins in this view's bag with this one as the start.
            calculateRouteFromStart(annotation)
        default:
            break
        }
    }
    
    /// Handle this view's "mainTableView" being long-pressed.
    func tableViewRowLongPressed(_ tableView: UITableView, indexPath: IndexPath)
    {
        // Load the pin entity that the user long-pressed.
        let record = mainFetchedResultsController.object(at: indexPath)
        
        // Set the long-pressed pin to this view's "currentPin".
        currentPin = record
        
        // When a user long-presses a pin, it signals that the pin should get to be renamed.
        mainViewState = .newItemNaming
        
        // Create a text-input view for renaming the long-pressed pin.
        let input = MMTextInputView(frame: CGRect(x: 0, y: mainHeader.frame.origin.y + mainHeader.frame.size.height, width: self.frame.size.width, height: 50), animated: true, backgroundType: UIBlurEffect.Style.dark)
        input.delegate = self
        input.textField.textAlignment = .center
        input.textField.text = record.name
        input.textField.placeholder = "Give this pin a new name"
        self.insertSubview(input, belowSubview: mainHeader)
    }
    
    /// Handle this view's "mainTableView"'s action buttons being selected.
    func tableViewActionViewItemSelected(_ tableView: UITableView, indexPath: IndexPath, actionType: MMTableViewActionTypes)
    {
        // Get the pin entity associated with the selected action item.
        let record = mainFetchedResultsController.object(at: indexPath)
        
        switch actionType
        {
        case .move:
            // If the user selects to move the pin, create and present an MMQuickView for displaying available bags in which to move the selected pin.
            
            // Create the MMQuickView.
            let qView = MMQuickView(frame: CGRect().frameBeneathFrame(self.frame, beneathFrame: self.frame), chosenPin: record)
            qView.navDelegate = self
            qView.alpha = 0
            self.addSubview(qView)
            
            // Animate the MMQuickView over this view.
            UIView.animate(withDuration: 0.2,
                                       delay: 0,
                                       options: UIView.AnimationOptions.curveEaseOut,
                                       animations: {
                                        qView.frame = CGRect().zeroBoundedRect(self.frame)
                                        qView.alpha = 1
                },
                                       completion: nil)
        }
    }
    
    // MARK: Navigation
    
    /// Handle the user requesting to close this view.
    @objc func closeViewButtonPressed()
    {
        navDelegate?.navigationDelegateViewClosed(self)
    }
    
    /// Handle a view presented by this view requesting to be closed.
    func navigationDelegateViewClosed(_ view: UIView)
    {
        // Animate the view off.
        UIView.animate(withDuration: 0.25,
                                   delay: 0,
                                   options: UIView.AnimationOptions.curveEaseOut,
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

/// A table view used to display the pins stored in a bag.
class MMSingleBagTableView: MMDefaultFetchedResultsTableView
{
    /// A delegate for handling selections from this table view by passing them to a superview.
    internal var selectionDelegate : MMBagsTableViewDelegate?
    
    /// Configure a cell for this table view.
    override func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath)
    {
        super.configureCell(cell, atIndexPath: indexPath)
        
        // Add a press recognizer to detect when a cell has been long-pressed. This will be used to signal to the superview that a cell has been long-pressed.
        let pressRecognizer = MMRowLongPressGestureRecognizer(target: self, action: #selector(self.rowLongPressed(_:)))
        pressRecognizer.minimumPressDuration = 1
        pressRecognizer.indexPath = indexPath
        cell.addGestureRecognizer(pressRecognizer)
        
        cell.textLabel?.textColor = MM_COLOR_ORANGE_TEXT
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        
        // Get the pin entity located at this cell's index.
        if let record = fetchedResultsController.object(at: indexPath) as? Pin
        {
            cell.textLabel?.text = record.name
        }
    }
    
    /// Set the row height for this table view's cells.
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 45
    }
    
    /// Handle selections in this table view.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        super.tableView(tableView, didSelectRowAt: indexPath)
        
        // Pass the selection information onto this view's delegate.
        selectionDelegate?.tableViewRowSelected(self, indexPath: indexPath)
    }
    
    /// Handle a row being long-pressed.
    @objc func rowLongPressed(_ pressRecog: MMRowLongPressGestureRecognizer)
    {
        switch pressRecog.state
        {
        case .began:
            
            // Get the index path of the cell that was long-pressed.
            guard let path = pressRecog.indexPath
                else { return }
            
            // Notify the delegate of the long-press on a specific cell.
            selectionDelegate?.tableViewRowLongPressed(self, indexPath: path)
        default:
            break
        }
    }
    
    /// Create the edit actions for this UITableView.
    func tableView(_ tableView: UITableView, editActionsForRowAtIndexPath indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        // Create an action to move the selected pin entity associated with a row in this UITableView to another bag.
        let editAction = UITableViewRowAction(style: .normal, title: "Move") { (rowAction, indexPath) in
            self.selectionDelegate?.tableViewActionViewItemSelected(self, indexPath: indexPath, actionType: .move)
        }
        editAction.backgroundColor = MM_COLOR_BLUE_DARK
        
        // Create an action to delete the selected pin entity associated with a row in this UITableView from its bag.
        let deleteAction = UITableViewRowAction(style: .normal, title: "Delete") { (rowAction, indexPath) in
            super.deleteObject(indexPath)
        }
        deleteAction.backgroundColor = MM_COLOR_RED_DARK
        
        return [deleteAction, editAction]
    }
}

/// An object for representing long-presses on a UITableViewCell. Use this when information about a long-press in a UITableViewCell needs to be passed onto a delegate.
class MMRowLongPressGestureRecognizer: UILongPressGestureRecognizer
{
    /// The index path of the item in a collection that was long-pressed.
    internal var indexPath: IndexPath?
}
