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
    func presentCustomViewController(_ controller: UIViewController, animated: Bool, completion: @escaping () -> Void)
}

class MMBagsView: UIView, UITextFieldDelegate, MMBagsTableViewDelegate, MMTextInputViewDelegate, MMNavigationDelegate
{
    // MARK: Internal Types and Variables
    
    internal var delegate : MMBagsViewDelegate?
    
    // MARK: Private Types and Variables
    
    fileprivate var contentView : UIView!
    fileprivate var bags : [Bag]?
    fileprivate var mainHeader : MMHeaderView!
    fileprivate var mainTableView : MMBagsTableView!
    fileprivate var currentNewBag : Bag?
    
    fileprivate let rowHeight : CGFloat = 100
    
    // MARK: Initialization
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        backgroundColor = MM_COLOR_BASE
        
        contentView = UIView(frame: CGRect().zeroBoundedRect(self.frame))
        
        // MARK: Header
        mainHeader = MMHeaderView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: 50))
        mainHeader.headerText = "MapMark"
        mainHeader.isTitleEditable = false
        
        let addButton = UIButton(type: .custom)
        addButton.frame = CGRect.zero
        addButton.titleLabel?.font = UIFont(name: MM_FONT_LIGHT, size: 45)
        addButton.titleLabel?.textAlignment = .center
        addButton.setTitleColor(MM_COLOR_GREEN_LIGHT, for: UIControlState())
        addButton.setTitleColor(MM_COLOR_GREEN_DARK, for: .highlighted)
        addButton.setTitle("+", for: UIControlState())
        addButton.sizeToFit()
        let addCenter = mainHeader.getHeaderLabelCenter()
        addButton.center = CGPoint(x: mainHeader.frame.size.width - 35, y: addCenter.y)
        addButton.addTarget(self, action: #selector(self.addNewBag), for: .touchUpInside)
        mainHeader.addSubview(addButton)
        
        // MARK: Export Button
        let exportButton = UIButton(type: .custom)
        exportButton.frame = CGRect(x: self.frame.size.width - 40, y: self.frame.size.height - 40, width: 30, height: 30)
        exportButton.center = CGPoint(x: addButton.center.x, y: exportButton.center.y)
        exportButton.setBackgroundImage(UIImage(named: "mm_export_button.png"), for: UIControlState())
        exportButton.tintColor = MM_COLOR_BLUE_DARK
        exportButton.addTarget(self, action: #selector(self.exportCoreDataToCSV), for: .touchUpInside)
        
        // MARK: Table View
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Bag")
        let fetchSort = NSSortDescriptor(key: "last_edited", ascending: false)
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
        UIView.animate(withDuration: 0.25,
                                   delay: 0.5,
                                   options: UIViewAnimationOptions.curveEaseOut,
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
        let fileName = exporter.getDocumentsDirectory().appendingPathComponent("mapmark_data.csv")
        
        do
        {
            try csvString.write(toFile: fileName, atomically: true, encoding: String.Encoding.utf8)
            let fileData = URL(fileURLWithPath: fileName)
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
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "Bag", in: MMSession.sharedSession.managedObjectContext)
            else { return }
        let newBag = Bag(entity: entityDescription, insertInto: MMSession.sharedSession.managedObjectContext)
        newBag.updateLastEdited()
        currentNewBag = newBag
    }
    
    // MARK: Text View Delegate
    func textInputViewReturned(_ inputView: MMTextInputView, field: UITextField, string: String?)
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
    func tableViewRowSelected(_ tableView: UITableView, indexPath: IndexPath)
    {
        rowSelected(indexPath)
    }
    
    func tableViewRowLongPressed(_ tableView: UITableView, indexPath: IndexPath)
    {
    }
    
    func tableViewActionViewItemSelected(_ tableView: UITableView, indexPath: IndexPath, actionType: MMTableViewActionTypes)
    {
    }
    
    fileprivate func rowSelected(_ indexPath : IndexPath)
    {
        guard let selectedBag = mainTableView.fetchedResultsController.object(at: indexPath) as? Bag
            else { return }
        let sbv = MMSingleBagView(frame: self.frame, bag: selectedBag)
        sbv.navDelegate = self
        animateViewOn(sbv)
    }
    
    // MARK: Navigation Delegate
    func navigationDelegateViewClosed(_ view: UIView)
    {
        animateViewOff(view)
    }
    
    fileprivate func animateViewOn(_ view : UIView)
    {
        let initialFrame = view.frame
        view.frame = CGRect(x: 0, y: self.frame.size.height, width: view.frame.size.width, height: view.frame.size.height)
        self.addSubview(view)
        UIView.animate(withDuration: 0.25,
                                   delay: 0,
                                   options: UIViewAnimationOptions.curveEaseOut,
                                   animations: {
                                    self.contentView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                                    view.frame = initialFrame
        }) { (completed) in
        }
    }
    
    fileprivate func animateViewOff(_ view : UIView)
    {
        UIView.animate(withDuration: 0.25,
                                   delay: 0,
                                   options: UIViewAnimationOptions.curveEaseOut,
                                   animations: {
                                    view.frame = CGRect(x: 0, y: self.frame.size.height, width: view.frame.size.width, height: view.frame.size.height)
                                    self.contentView.transform = CGAffineTransform(scaleX: 1, y: 1)
            }) { (completed) in
                if completed
                {
                    view.removeFromSuperview()
                }
        }
    }
    
}

enum MMTableViewActionTypes
{
    case move
}

protocol MMBagsTableViewDelegate
{
    func tableViewRowSelected(_ tableView: UITableView, indexPath: IndexPath)
    func tableViewRowLongPressed(_ tableView: UITableView, indexPath: IndexPath)
    func tableViewActionViewItemSelected(_ tableView: UITableView, indexPath: IndexPath, actionType: MMTableViewActionTypes)
}

final class MMBagsTableView: MMDefaultFetchedResultsTableView
{
    internal var selectionDelegate : MMBagsTableViewDelegate?
    
    override func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath)
    {
        super.configureCell(cell, atIndexPath: indexPath)
        guard let record = fetchedResultsController.object(at: indexPath) as? Bag
            else { return }
        cell.textLabel?.text = record.name
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAtIndexPath indexPath: IndexPath) -> CGFloat
    {
        return 100
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        super.tableView(tableView, didSelectRowAt: indexPath)
        selectionDelegate?.tableViewRowSelected(self, indexPath: indexPath)
    }
}
