//
//  MMBagViewClasses.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/6/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit
import CoreData

class MMDefaultFetchedResultsTableView: MMDefaultTableView, NSFetchedResultsControllerDelegate
{
//    internal var moc : NSManagedObjectContext?
    internal var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>!
    
    // MARK: Initialization
    init(frame: CGRect, fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>, managedObjectContext: NSManagedObjectContext)
    {
        super.init(frame: frame, style: .plain)
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
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        self.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        self.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    {
        switch (type)
        {
        case .insert:
            if let indexPath = newIndexPath
            {
                self.insertRows(at: [indexPath], with: .fade)
            }
            break;
        case .delete:
            if let indexPath = indexPath
            {
                self.deleteRows(at: [indexPath], with: .fade)
            }
            break;
        case .update:
            if let indexPath = indexPath
            {
                guard let cell = self.cellForRow(at: indexPath) // Add cast to custom UITableViewCell here
                    else { return }
                self.configureCell(cell, atIndexPath: indexPath)
            }
            break;
        case .move:
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
    func tableView(_ tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: IndexPath)
    {
        if editingStyle == .delete
        {
            deleteObject(indexPath)
        }
    }
    
    internal func deleteObject(_ indexPath: IndexPath)
    {
        guard let record = fetchedResultsController.object(at: indexPath) as? NSManagedObject
            else { return }
        
        if let deletePin = record as? Pin
        {
            if let updateBag = deletePin.bag as? Bag
            {
                updateBag.updateLastEdited()
            }
        }
        
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
    
    func tableView(_ tableView: UITableView, canEditRowAtIndexPath indexPath: IndexPath) -> Bool
    {
        return true
    }
    
    func numberOfSectionsInTableView(_ tableView: UITableView) -> Int
    {
        if let sections = fetchedResultsController.sections
        {
            return sections.count
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAtIndexPath indexPath: IndexPath) -> CGFloat
    {
        return rowHeight
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if let sections = fetchedResultsController.sections
        {
            let sectionInfo = sections[section]
            return sectionInfo.numberOfObjects
        }
        return 0
    }
}

class MMDefaultTableView: UITableView, UITableViewDelegate, UITableViewDataSource
{
    override init(frame: CGRect, style: UITableViewStyle)
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
    {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell_id")
            else { return UITableViewCell() }
        
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath)
    {
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = UIColor.darkGray
        cell.backgroundColor = UIColor.clear
        cell.textLabel?.font = UIFont(name: MM_FONT_REGULAR, size: 25)
        cell.textLabel?.textColor = MM_COLOR_BLUE_TEXT
    }
}
