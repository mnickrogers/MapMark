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
    internal var moc : NSManagedObjectContext?
    internal var fetchedResultsController : NSFetchedResultsController!
    
    // MARK: Initialization
    init(frame: CGRect, fetchedResultsController: NSFetchedResultsController, managedObjectContext: NSManagedObjectContext)
    {
        super.init(frame: frame, style: .Plain)
        moc = managedObjectContext
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
    func controllerWillChangeContent(controller: NSFetchedResultsController)
    {
        self.beginUpdates()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController)
    {
        self.endUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch (type) {
        case .Insert:
            if let indexPath = newIndexPath {
                self.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
            break;
        case .Delete:
            if let indexPath = indexPath {
                self.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
            break;
        case .Update:
            if let indexPath = indexPath {
                guard let cell = self.cellForRowAtIndexPath(indexPath) // Add cast to custom UITableViewCell here
                    else { return }
                self.configureCell(cell, atIndexPath: indexPath)
            }
            break;
        case .Move:
            if let indexPath = indexPath {
                self.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
            
            if let newIndexPath = newIndexPath {
                self.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Fade)
            }
            break;
        }
    }
    
    // MARK: Table View
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
    {
        if editingStyle == .Delete
        {
            guard let record = fetchedResultsController.objectAtIndexPath(indexPath) as? Bag
                else { return }
            moc?.deleteObject(record)
            do
            {
                try moc?.save()
            }
            catch let error as NSError
            {
                print("Failed to delete record: \(error.localizedDescription)")
            }
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        return true
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        if let sections = fetchedResultsController.sections
        {
            return sections.count
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return rowHeight
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
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
        
        scrollEnabled = true
        alwaysBounceVertical = true
        alwaysBounceHorizontal = false
        registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell_id")
        delegate = self
        dataSource = self
        clipsToBounds = false
        backgroundColor = UIColor.clearColor()
        allowsSelectionDuringEditing = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 0
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.01
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
    {
        return UIView()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        guard let cell = tableView.dequeueReusableCellWithIdentifier("cell_id")
            else { return UITableViewCell() }
        
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath)
    {
        cell.backgroundColor = UIColor.clearColor()
        cell.textLabel?.font = UIFont(name: MM_FONT_REGULAR, size: 25)
        cell.textLabel?.textColor = MM_COLOR_BLUE_TEXT
    }
}
