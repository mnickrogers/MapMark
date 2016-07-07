//
//  MMBagsView.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/6/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit
import CoreData

class MMBagsView: UIView, NSFetchedResultsControllerDelegate, UITableViewDelegate, UITableViewDataSource, MMTextInputViewDelegate, UITextFieldDelegate
{
    // MARK: Private Types and Variables
    
    private lazy var moc : NSManagedObjectContext? =
    {
        guard let delegate = UIApplication.sharedApplication().delegate as? AppDelegate
            else { return nil }
        let context = delegate.managedObjectContext
        return context
    }()
    private var bags : [Bag]?
    private var mainHeader : MMHeaderView!
    private var mainTableView : UITableView!
    private var currentNewBag : Bag?
    private lazy var fetchedResultsController : NSFetchedResultsController =
    {
        let fetchRequest = NSFetchRequest(entityName: "Bag")
        let fetchSort = NSSortDescriptor(key: "date_created", ascending: false)
        fetchRequest.sortDescriptors = [fetchSort]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.moc!, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    private let rowHeight : CGFloat = 100
    
    // MARK: Initialization
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        backgroundColor = MM_COLOR_BASE
        
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
        
        // MARK: Header
        mainHeader = MMHeaderView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: 50))
        mainHeader.headerText = "MapMark"
        
        let addButton = UIButton(type: .Custom)
        addButton.frame = CGRectZero
        addButton.titleLabel?.font = UIFont(name: MM_FONT_LIGHT, size: 45)
        addButton.titleLabel?.textAlignment = .Center
        addButton.setTitleColor(MM_COLOR_GREEN_LIGHT, forState: .Normal)
        addButton.setTitleColor(MM_COLOR_GREEN_DARK, forState: .Highlighted)
        addButton.setTitle("+", forState: .Normal)
        addButton.sizeToFit()
        let addCenter = mainHeader.getHeaderLabelCenter()
        addButton.center = CGPoint(x: mainHeader.frame.size.width - 35, y: addCenter.y)
        addButton.addTarget(self, action: #selector(self.addNewBag), forControlEvents: .TouchUpInside)
        mainHeader.addSubview(addButton)
        
        // MARK: Table View
        mainTableView = UITableView(frame: CGRect(x: 0, y: mainHeader.frame.origin.y + mainHeader.frame.size.height, width: self.frame.size.width, height: self.frame.size.height), style: .Plain)
        mainTableView.scrollEnabled = true
        mainTableView.alwaysBounceVertical = true
        mainTableView.alwaysBounceHorizontal = false
        mainTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell_id")
        mainTableView.delegate = self
        mainTableView.dataSource = self
        mainTableView.clipsToBounds = false
        mainTableView.backgroundColor = UIColor.clearColor()
        mainTableView.allowsSelectionDuringEditing = false
        mainTableView.separatorColor = MM_COLOR_BLUE_DIV
        self.addSubview(mainTableView)
        
        self.addSubview(mainHeader)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Core Data
    private func getBags() -> [Bag]?
    {
        if moc == nil { return nil }
        let fetchRequest = NSFetchRequest()
        let entityDescription = NSEntityDescription.entityForName("Bag", inManagedObjectContext: moc!)
        let fetchSort = NSSortDescriptor(key: "date_created", ascending: false)
        fetchRequest.entity = entityDescription
        fetchRequest.sortDescriptors = [fetchSort]
        
        guard let results = try? moc!.executeFetchRequest(fetchRequest) as? [Bag]
            else { return nil }
        return results
    }
    
    // MARK: Handle New Bags
    
    func addNewBag()
    {
        let input = MMTextInputView(frame: CGRect(x: 0, y: mainHeader.frame.origin.y + mainHeader.frame.size.height, width: self.frame.size.width, height: rowHeight), animated: true)
        input.delegate = self
        self.insertSubview(input, belowSubview: mainHeader)
        if let context = moc
        {
            guard let entityDescription = NSEntityDescription.entityForName("Bag", inManagedObjectContext: context)
                else { return }
            let newBag = Bag(entity: entityDescription, insertIntoManagedObjectContext: context)
            currentNewBag = newBag
        }
    }
    
    // MARK: Text View Delegate
    func textInputViewReturned(inputView: MMTextInputView, field: UITextField, string: String?)
    {
        inputView.animateViewOff { (completed, view) in
            if completed
            {
                inputView.removeFromSuperview()
            }
        }
        
        if let bag = currentNewBag
        {
            bag.name = string
        }
        
        do
        {
            try moc?.save()
        }
        catch let error as NSError
        {
            print("Could not save Core Data, \(error.localizedDescription)")
        }
        tableViewRowSelected(NSIndexPath(forRow: 0, inSection: 0))
    }
    
    // MARK: Fetched Results Controller
    func controllerWillChangeContent(controller: NSFetchedResultsController)
    {
        mainTableView.beginUpdates()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController)
    {
        mainTableView.endUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch (type) {
        case .Insert:
            if let indexPath = newIndexPath {
                mainTableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
            break;
        case .Delete:
            if let indexPath = indexPath {
                mainTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
            break;
        case .Update:
            if let indexPath = indexPath {
                guard let cell = mainTableView.cellForRowAtIndexPath(indexPath) // Add cast to custom UITableViewCell here
                    else { return }
                configureCell(cell, atIndexPath: indexPath)
            }
            break;
        case .Move:
            if let indexPath = indexPath {
                mainTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
            
            if let newIndexPath = newIndexPath {
                mainTableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Fade)
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
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if let sections = fetchedResultsController.sections
        {
            let sectionInfo = sections[section]
            return sectionInfo.numberOfObjects
        }
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
        tableViewRowSelected(indexPath)
    }
    
    private func tableViewRowSelected(indexPath : NSIndexPath)
    {
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath)
    {
        guard let record = fetchedResultsController.objectAtIndexPath(indexPath) as? Bag
            else { return }
        
        cell.backgroundColor = UIColor.clearColor()
        cell.textLabel?.font = UIFont(name: MM_FONT_REGULAR, size: 25)
        cell.textLabel?.textColor = MM_COLOR_BLUE_TEXT
        cell.textLabel?.text = record.name
    }
    
    // MARK: Single Bag View
    
}
