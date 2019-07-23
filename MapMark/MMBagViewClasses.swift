//
//  MMBagViewClasses.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/6/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit
import CoreData

/// A UITableView with a built-in NSFetchedResultsController.
class MMDefaultFetchedResultsTableView: MMDefaultTableView, NSFetchedResultsControllerDelegate
{
    /// The fetched results controller for this UITableView subclass.
    internal var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>!
    
    // MARK: Initialization
    init(frame: CGRect, fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>, managedObjectContext: NSManagedObjectContext)
    {
        super.init(frame: frame, style: .plain)
        
        // Set the fetched results controller and managed object context for this UITableView.
        self.fetchedResultsController = fetchedResultsController
        self.fetchedResultsController.delegate = self
        
        // MARK: Core Data Fetch
        do
        {
            try fetchedResultsController.performFetch()
        }
        catch
        {
            let fetchError = error as NSError
            print("Error: \(fetchError.localizedDescription)")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Fetched Results Controller
    
    /// Handle notifications to change this table view's contents.
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        self.beginUpdates()
    }
    
    /// Complete tasks to change this table view's contents.
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        self.endUpdates()
    }
    
    /// Handle changes to this table view's contents.
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    {
        switch (type)
        {
        case .insert:
            // Insert a new cell into this UITableView.
            
            if let indexPath = newIndexPath
            {
                self.insertRows(at: [indexPath], with: .fade)
            }
            break;
        case .delete:
            // Delete a cell from this UITableView.
            
            if let indexPath = indexPath
            {
                self.deleteRows(at: [indexPath], with: .fade)
            }
            break;
        case .update:
            // Update the contents of a cell in this UITableView. This class's "configureCell" method will be overridden by its subclasses.
            
            if let indexPath = indexPath
            {
                guard let cell = self.cellForRow(at: indexPath) // Add cast to custom UITableViewCell here
                    else { return }
                self.configureCell(cell, atIndexPath: indexPath)
            }
            break;
        case .move:
            // Relocate a cell in this UITableView.
            
            if let indexPath = indexPath
            {
                self.deleteRows(at: [indexPath], with: .fade)
            }
            
            if let newIndexPath = newIndexPath
            {
                self.insertRows(at: [newIndexPath], with: .fade)
            }
            break;
        }
    }
    
    // MARK: Table View
    
    /// Handle a preconfigured action from an editing style.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)
    {
        // If the editing option selected is "delete", then remove the cell and its corresponding CoreData entity.
        if editingStyle == .delete
        {
            deleteObject(indexPath)
        }
    }
    
    /// Delete an object and its CoreData entity stored at a given IndexPath.
    internal func deleteObject(_ indexPath: IndexPath)
    {
        // Get the record stored at the corresponding IndexPath.
        guard let record = fetchedResultsController.object(at: indexPath) as? NSManagedObject
            else { return }
        
        // If that record is a pin, delete it.
        if let deletePin = record as? Pin
        {
            // Get the bag associated with the pin being deleted.
            if let updateBag = deletePin.bag as? Bag
            {
                // Update the time the bag was last edited to match the current time the pin was deleted.
                updateBag.updateLastEdited()
            }
        }
        
        // Save changes to the CoreData model.
        MMSession.sharedSession.managedObjectContext.delete(record)
        do
        {
            try MMSession.sharedSession.managedObjectContext.save()
        }
        catch let error as NSError
        {
            print("Failed to delete record: \(error.localizedDescription)")
        }
    }
    
    /// Enable cell editing so that a user can swipe to reveal action views.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return true
    }
    
    /// Get the number of sections in this UITableView.
    func numberOfSectionsInTableView(_ tableView: UITableView) -> Int
    {
        if let sections = fetchedResultsController.sections
        {
            return sections.count
        }
        
        return 0
    }
    
    /// Get the row height for this UITableView's cells.
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return rowHeight
    }
    
    /// Get the number of rows in a section for this UITableView.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // Get the sections in this UITableView from its NSFetchedResultsController.
        if let sections = fetchedResultsController.sections
        {
            // Get the number of objects (or rows) in each section.
            let sectionInfo = sections[section]
            return sectionInfo.numberOfObjects
        }
        return 0
    }
}

/// A class for representing a UITableView with a consistent style across the app. Subclass this class for specific UITableView functionality.
class MMDefaultTableView: UITableView, UITableViewDelegate, UITableViewDataSource
{
    override init(frame: CGRect, style: UITableView.Style)
    {
        super.init(frame: frame, style: style)
        
        isScrollEnabled = true
        alwaysBounceVertical = true
        alwaysBounceHorizontal = false
        register(UITableViewCell.self, forCellReuseIdentifier: "cell_id")
        delegate = self
        dataSource = self
        clipsToBounds = false
        backgroundColor = UIColor.clear
        allowsSelectionDuringEditing = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Get the number of rows in this UITableView's section.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 0
    }
    
    /// Get the height for a footer in this UITableView section.
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.01
    }
    
    /// Get the view for a footer in this UITableView section.
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
    {
        return UIView()
    }
    
    
    /// Get the cell at a given row's IndexPath.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell_id")
            else { return UITableViewCell() }
        
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    /// Handle a row being selected in this UITableView.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    /// Configure a cell at a given IndexPath.
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath)
    {
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = UIColor.darkGray
        cell.backgroundColor = UIColor.clear
        cell.textLabel?.font = UIFont(name: MM_FONT_REGULAR, size: 25)
        cell.textLabel?.textColor = MM_COLOR_BLUE_TEXT
    }
}
