//
//  MMBagsView.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/6/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit
import CoreData

class MMBagsView: UIView, UITextFieldDelegate, MMBagsTableViewDelegate, MMTextInputViewDelegate
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
    private var mainTableView : MMBagsTableView!
    private var currentNewBag : Bag?
    
    private let rowHeight : CGFloat = 100
    
    // MARK: Initialization
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        backgroundColor = MM_COLOR_BASE
        
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
        let fetchRequest = NSFetchRequest(entityName: "Bag")
        let fetchSort = NSSortDescriptor(key: "date_created", ascending: false)
        fetchRequest.sortDescriptors = [fetchSort]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.moc!, sectionNameKeyPath: nil, cacheName: nil)
        
        mainTableView = MMBagsTableView(frame: CGRect(x: 0, y: mainHeader.frame.origin.y + mainHeader.frame.size.height, width: self.frame.size.width, height: self.frame.size.height),
                                        fetchedResultsController: fetchedResultsController,
                                        managedObjectContext: moc!)
        mainTableView.selectionDelegate = self
        self.addSubview(mainTableView)
        
        self.addSubview(mainHeader)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
//        tableViewRowSelected(NSIndexPath(forRow: 0, inSection: 0))
    }
    
    // MARK: Table View Methods
    func tableViewRowSelected(tableView: UITableView, indexPath: NSIndexPath)
    {
        rowSelected(indexPath)
    }
    
    private func rowSelected(indexPath : NSIndexPath)
    {
        print("Selected: \(indexPath)")
        guard let selectedBag = mainTableView.fetchedResultsController.objectAtIndexPath(indexPath) as? Bag
            else { return }
        let sbv = MMSingleBagView(frame: self.frame, bag: selectedBag, managedObjectContext: moc!)
        self.addSubview(sbv)
    }
    
    // MARK: Single Bag View
    
}

protocol MMBagsTableViewDelegate
{
    func tableViewRowSelected(tableView: UITableView, indexPath: NSIndexPath)
}

final class MMBagsTableView: MMDefaultFetchedResultsTableView
{
    internal var selectionDelegate : MMBagsTableViewDelegate?
    
    override func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath)
    {
        super.configureCell(cell, atIndexPath: indexPath)
        guard let record = fetchedResultsController.objectAtIndexPath(indexPath) as? Bag
            else { return }
        cell.textLabel?.text = record.name
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 100
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        selectionDelegate?.tableViewRowSelected(self, indexPath: indexPath)
    }
}
