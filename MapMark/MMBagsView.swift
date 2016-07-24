//
//  MMBagsView.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/6/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit
import CoreData

protocol MMBagsViewDelegate
{
    func presentCustomViewController(controller: UIViewController, animated: Bool, completion:() -> Void)
}

class MMBagsView: UIView, UITextFieldDelegate, MMBagsTableViewDelegate, MMTextInputViewDelegate, MMNavigationDelegate
{
    // MARK: Internal Types and Variables
    
    internal var delegate : MMBagsViewDelegate?
    
    // MARK: Private Types and Variables
    
    private var contentView : UIView!
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
        
        contentView = UIView(frame: CGRect().zeroBoundedRect(self.frame))
        
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
        
        // MARK: Export Button
        let exportButton = UIButton(type: .Custom)
        exportButton.frame = CGRect(x: self.frame.size.width - 40, y: self.frame.size.height - 40, width: 30, height: 30)
        exportButton.center = CGPoint(x: addButton.center.x, y: exportButton.center.y)
        exportButton.setBackgroundImage(UIImage(named: "mm_export_button.png"), forState: .Normal)
        exportButton.tintColor = MM_COLOR_BLUE_DARK
        exportButton.addTarget(self, action: #selector(self.exportCoreDataToCSV), forControlEvents: .TouchUpInside)
        
        // MARK: Table View
        let fetchRequest = NSFetchRequest(entityName: "Bag")
        let fetchSort = NSSortDescriptor(key: "date_created", ascending: false)
        fetchRequest.sortDescriptors = [fetchSort]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: MMSession.sharedSession.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        mainTableView = MMBagsTableView(frame: CGRect(x: 0, y: mainHeader.frame.origin.y + mainHeader.frame.size.height, width: self.frame.size.width, height: self.frame.size.height),
                                        fetchedResultsController: fetchedResultsController,
                                        managedObjectContext: MMSession.sharedSession.managedObjectContext)
        mainTableView.selectionDelegate = self
        mainTableView.separatorColor = MM_COLOR_BLUE_DIV
        
        contentView.addSubview(mainTableView)
        contentView.addSubview(exportButton)
        contentView.addSubview(mainHeader)
        self.addSubview(contentView)
        
        let initialTableViewFrame = mainTableView.frame
        mainTableView.frame = CGRect(x: 0, y: mainTableView.frame.origin.y + 40, width: mainTableView.frame.size.width, height: mainTableView.frame.size.height)
        mainTableView.alpha = 0
        UIView.animateWithDuration(0.25,
                                   delay: 0.5,
                                   options: UIViewAnimationOptions.CurveEaseOut,
                                   animations: { 
                                    self.mainTableView.frame = initialTableViewFrame
                                    self.mainTableView.alpha = 1
            }) { (completed) in
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Export functions
    
    func exportCoreDataToCSV()
    {
        let exporter = MMExporter()
        let csvString = exporter.getCoreDataCSVString()
        let fileName = exporter.getDocumentsDirectory().stringByAppendingPathComponent("mapmark_data.csv")
        
        do
        {
            try csvString.writeToFile(fileName, atomically: true, encoding: NSUTF8StringEncoding)
            let fileData = NSURL(fileURLWithPath: fileName)
            let activityVC = UIActivityViewController(activityItems: [fileData], applicationActivities: nil)
            delegate?.presentCustomViewController(activityVC, animated: true, completion:
            {
//                let fManager = NSFileManager.defaultManager()
//                do
//                {
//                    try fManager.removeItemAtURL(fileData)
//                }
//                catch let fileError as NSError
//                {
//                    print("Error removing file: \(fileError.localizedDescription)")
//                }
            })
        }
        catch let error as NSError
        {
            print("File exporting error: \(error.localizedDescription)")
        }
    }
    
    // MARK: Handle New Bags
    
    func addNewBag()
    {
        let input = MMTextInputView(frame: CGRect(x: 0, y: mainHeader.frame.origin.y + mainHeader.frame.size.height, width: self.frame.size.width, height: rowHeight), animated: true)
        input.delegate = self
        self.insertSubview(input, belowSubview: mainHeader)
        guard let entityDescription = NSEntityDescription.entityForName("Bag", inManagedObjectContext: MMSession.sharedSession.managedObjectContext)
            else { return }
        let newBag = Bag(entity: entityDescription, insertIntoManagedObjectContext: MMSession.sharedSession.managedObjectContext)
        currentNewBag = newBag
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
            try MMSession.sharedSession.managedObjectContext.save()
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
    
    func tableViewRowLongPressed(tableView: UITableView, indexPath: NSIndexPath)
    {
    }
    
    private func rowSelected(indexPath : NSIndexPath)
    {
        guard let selectedBag = mainTableView.fetchedResultsController.objectAtIndexPath(indexPath) as? Bag
            else { return }
        let sbv = MMSingleBagView(frame: self.frame, bag: selectedBag)
        sbv.navDelegate = self
        animateViewOn(sbv)
    }
    
    // MARK: Navigation Delegate
    func navigationDelegateViewClosed(view: UIView)
    {
        animateViewOff(view)
    }
    
    private func animateViewOn(view : UIView)
    {
        let initialFrame = view.frame
        view.frame = CGRect(x: 0, y: self.frame.size.height, width: view.frame.size.width, height: view.frame.size.height)
        self.addSubview(view)
        UIView.animateWithDuration(0.25,
                                   delay: 0,
                                   options: UIViewAnimationOptions.CurveEaseOut,
                                   animations: {
                                    self.contentView.transform = CGAffineTransformMakeScale(0.95, 0.95)
                                    view.frame = initialFrame
        }) { (completed) in
        }
    }
    
    private func animateViewOff(view : UIView)
    {
        UIView.animateWithDuration(0.25,
                                   delay: 0,
                                   options: UIViewAnimationOptions.CurveEaseOut,
                                   animations: {
                                    view.frame = CGRect(x: 0, y: self.frame.size.height, width: view.frame.size.width, height: view.frame.size.height)
                                    self.contentView.transform = CGAffineTransformMakeScale(1, 1)
            }) { (completed) in
                if completed
                {
                    view.removeFromSuperview()
                }
        }
    }
    
}

protocol MMBagsTableViewDelegate
{
    func tableViewRowSelected(tableView: UITableView, indexPath: NSIndexPath)
    func tableViewRowLongPressed(tableView: UITableView, indexPath: NSIndexPath)
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
