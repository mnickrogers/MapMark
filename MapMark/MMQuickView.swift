//
//  MMQuickView.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/24/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit
import CoreData

/// A view for displaying a list of all bags. Use this for a quick reference to a user's saved bags such as when an MMSingleBagView is moving pins from one bag to another.
class MMQuickView: UIView, MMBagsTableViewDelegate
{
    // MARK: Internal Types and Variables
    
    internal var navDelegate: MMNavigationDelegate?
    
    // MARK: Private Types and Variables
    
    /// The fetched results controller for this bags view.
    private lazy var mainFetchedResultsController : NSFetchedResultsController<Bag> =
        {
            let fetchRequest = NSFetchRequest<Bag>(entityName: "Bag")
            let fetchSort = NSSortDescriptor(key: "name", ascending: true)
            fetchRequest.sortDescriptors = [fetchSort]
            let controller = NSFetchedResultsController<Bag>(fetchRequest: fetchRequest, managedObjectContext: MMSession.sharedSession.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
            return controller
    }()
    
    /// The table view used to display the users saved bags.
    private var mainTableView: MMQuickViewTableView!
    
    /// The pin that a user has selected to be moved into a different bag.
    private var mainPin: Pin?
    
    /// The navigation header for this view.
    private var mainHeader : MMHeaderView!
    
    // MARK: Initialization
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        // Run the CoreData fetch for this mainFetchedResultsController.
        do
        {
            try mainFetchedResultsController.performFetch()
        }
        catch let error as NSError
        {
            print("Could not fetch items: \(error.localizedDescription)")
        }
        
        // MARK: Background
        
        // Create a blur effect for this view's background.
        let bgEffect = UIBlurEffect(style: .dark)
        let effectView = UIVisualEffectView(effect: bgEffect)
        effectView.frame = CGRect().zeroBoundedRect(self.frame)
        self.addSubview(effectView)
        
        // MARK: Header
        
        // Create the view's navigation header.
        mainHeader = MMHeaderView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: 50))
        mainHeader.headerText = "Move to Bag:"
        mainHeader.isTitleEditable = false
        self.addSubview(mainHeader)
        
        // MARK: Close button
        
        // This close button will allow the user to close this view, thus returning to the view that presented it.
        let closeButton = UIButton(type: .custom)
        closeButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        closeButton.center = CGPoint(x: 35, y: mainHeader.getHeaderLabelCenter().y)
        closeButton.setBackgroundImage(UIImage(named: "close_button_green.png"), for: UIControl.State())
        closeButton.addTarget(self, action: #selector(self.closeViewButtonPressed), for: .touchUpInside)
        mainHeader.addSubview(closeButton)
        
        // MARK: Table view
        mainTableView = MMQuickViewTableView(frame: CGRect(x: 0, y: mainHeader.frame.origin.y + mainHeader.frame.size.height, width: self.frame.size.width, height: self.frame.size.height),
                                             fetchedResultsController: mainFetchedResultsController as! NSFetchedResultsController<NSFetchRequestResult>,
                                             managedObjectContext: MMSession.sharedSession.managedObjectContext)
        mainTableView.separatorColor = MM_COLOR_BLUE_DIV
        mainTableView.clipsToBounds = true
        mainTableView.selectionDelegate = self
        
        self.addSubview(mainTableView)
    }
    
    /// Initialize this MMQuickView with an active pin that can get moved to a different bag.
    convenience init(frame: CGRect, chosenPin: Pin)
    {
        self.init(frame: frame)
        mainPin = chosenPin
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func removeFromSuperview()
    {
        navDelegate = nil
        mainFetchedResultsController.delegate = nil
        super.removeFromSuperview()
    }
    
    /// Handle close operations to remove this view from its superview by calling the close method on this view's navigation delegate.
    @objc func closeViewButtonPressed()
    {
        navDelegate?.navigationDelegateViewClosed(self)
    }
    
    // MARK: Bags table view delegate
    
    /// Handle table view row selection. If there is an active pin, this will assign that pin to the bag at the selected row.
    func tableViewRowSelected(_ tableView: UITableView, indexPath: IndexPath)
    {
        let selectedBag = mainFetchedResultsController.object(at: indexPath)
        mainPin?.bag = selectedBag
        
        // Save changes to the CoreData model.
        do
        {
            try MMSession.sharedSession.managedObjectContext.save()
        }
        catch let error as NSError
        {
            print("Error changing pin's bag: \(error.localizedDescription)")
        }
        
        // After a user has selected a bag for the pin, close this view.
        navDelegate?.navigationDelegateViewClosed(self)
    }
    
    func tableViewRowLongPressed(_ tableView: UITableView, indexPath: IndexPath)
    {
    }
    
    func tableViewActionViewItemSelected(_ tableView: UITableView, indexPath: IndexPath, actionType: MMTableViewActionTypes)
    {
    }
}

/// The table view used to display bags in a quick table view (used for moving pins to new bags).
final class MMQuickViewTableView: MMSingleBagTableView
{
    override func tableView(_ tableView: UITableView, heightForRowAtIndexPath indexPath: IndexPath) -> CGFloat
    {
        return 75
    }
    
    override func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath)
    {
        super.configureCell(cell, atIndexPath: indexPath)
        cell.textLabel?.textColor = MM_COLOR_BLUE_TEXT
        
        if let record = fetchedResultsController.object(at: indexPath) as? Bag
        {
            cell.textLabel?.text = record.name
        }
    }
}
