//
//  MMBagsView.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/6/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import UIKit
import CoreData

/// The delegate for the main bags view.
protocol MMBagsViewDelegate
{
    /// Use this view to present a view controller on a view's view controller.
    func presentCustomViewController(_ controller: UIViewController, animated: Bool, completion: @escaping () -> Void)
}

/// A view for displaying all of the bags that a user has saved. Each bag contains its own pins that can be deleted or transferred to another bag.
class MMBagsView: UIView, UITextFieldDelegate, MMBagsTableViewDelegate, MMTextInputViewDelegate, MMNavigationDelegate
{
    // MARK: Internal Types and Variables
    
    /// The main navigation delegate for this view.
    internal var delegate : MMBagsViewDelegate?
    
    // MARK: Private Types and Variables
    
    /// The main content view for this view.
    private var contentView : UIView!
    
    /// All of the bags for this view to display.
    private var bags : [Bag]?
    
    /// The navigation header at the top of this bag.
    private var mainHeader : MMHeaderView!
    
    /// The table view used to display all of the bags in this view's "bags" array.
    private var mainTableView : MMBagsTableView!
    
    /// The bag currently being added to this view. This bag is created when the user chooses to create a new bag. This will be used to set the a new bag's parameters through the various stages of creating it in this view.
    private var currentNewBag : Bag?
    
    /// The row height for this view's "mainTableView" variable.
    private let rowHeight : CGFloat = 100
    
    // MARK: Initialization
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        // Set the background to the base color.
        backgroundColor = MM_COLOR_BASE
        
        // Set the content view to be the size of this view.
        contentView = UIView(frame: CGRect().zeroBoundedRect(self.frame))
        
        // MARK: Header
        mainHeader = MMHeaderView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: 50))
        mainHeader.headerText = "MapMark"
        mainHeader.isTitleEditable = false
        
        // This button will allow the user to add new bags.
        let addButton = UIButton(type: .custom)
        addButton.frame = CGRect.zero
        addButton.titleLabel?.font = UIFont(name: MM_FONT_LIGHT, size: 45)
        addButton.titleLabel?.textAlignment = .center
        addButton.setTitleColor(MM_COLOR_GREEN_LIGHT, for: UIControl.State())
        addButton.setTitleColor(MM_COLOR_GREEN_DARK, for: .highlighted)
        addButton.setTitle("+", for: UIControl.State())
        addButton.sizeToFit()
        let addCenter = mainHeader.getHeaderLabelCenter()
        addButton.center = CGPoint(x: mainHeader.frame.size.width - 35, y: addCenter.y)
        addButton.addTarget(self, action: #selector(self.addNewBag), for: .touchUpInside)
        mainHeader.addSubview(addButton)
        
        // MARK: Export Button
        
        // This button will allow the user to export their saved bags and pins to a CSV file that is then handled by a share sheet.
        let exportButton = UIButton(type: .custom)
        exportButton.frame = CGRect(x: self.frame.size.width - 40, y: self.frame.size.height - 40, width: 30, height: 30)
        exportButton.center = CGPoint(x: addButton.center.x, y: exportButton.center.y)
        exportButton.setBackgroundImage(UIImage(named: "mm_export_button.png"), for: UIControl.State())
        exportButton.tintColor = MM_COLOR_BLUE_DARK
        exportButton.addTarget(self, action: #selector(self.exportCoreDataToCSV), for: .touchUpInside)
        
        // MARK: Table View
        
        // Set up the fetch request for this table view.
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Bag")
        // Order the request by the time a bag had its contents last edited.
        let fetchSort = NSSortDescriptor(key: "last_edited", ascending: false)
        fetchRequest.sortDescriptors = [fetchSort]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: MMSession.sharedSession.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Create the main table view for displaying bags.
        mainTableView = MMBagsTableView(frame: CGRect(x: 0, y: mainHeader.frame.origin.y + mainHeader.frame.size.height, width: self.frame.size.width, height: self.frame.size.height - (mainHeader.frame.origin.y + mainHeader.frame.size.height)),
                                        fetchedResultsController: fetchedResultsController,
                                        managedObjectContext: MMSession.sharedSession.managedObjectContext)
        // This view will handle the selection from this table view.
        mainTableView.selectionDelegate = self
        mainTableView.separatorColor = MM_COLOR_BLUE_DIV
        
        // Add all of the created views to this view.
        contentView.addSubview(mainTableView)
        contentView.addSubview(exportButton)
        contentView.addSubview(mainHeader)
        self.addSubview(contentView)
        
        // Set the initial table view frame for this view. This will be used to animate the table view on when the view loads.
        let initialTableViewFrame = mainTableView.frame
        mainTableView.frame = CGRect(x: 0, y: mainTableView.frame.origin.y + 40, width: mainTableView.frame.size.width, height: mainTableView.frame.size.height)
        mainTableView.alpha = 0
        UIView.animate(withDuration: 0.25,
                                   delay: 0.5,
                                   options: UIView.AnimationOptions.curveEaseOut,
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
    
    /// Export all of the saved data (bags and pins) to a CSV file.
    @objc func exportCoreDataToCSV()
    {
        // Create a new instance of the MMExporter class which is used to prepare CoreData entities for exporting.
        let exporter = MMExporter()
        let csvString = exporter.getCoreDataCSVString()
        // Get the current document directory for this user's application.
        let fileName = exporter.getDocumentsDirectory().appendingPathComponent("mapmark_data.csv")
        
        do
        {
            // Create a CSV file from the string of CSV data returned by the MMExporter object.
            try csvString.write(toFile: fileName, atomically: true, encoding: String.Encoding.utf8)
            // Get the url of that CSV file.
            let fileData = URL(fileURLWithPath: fileName)
            // Load the activity sheet and pass the CSV file URL to it.
            let activityVC = UIActivityViewController(activityItems: [fileData], applicationActivities: nil)
            delegate?.presentCustomViewController(activityVC, animated: true, completion:
            {
                // Currently this harms the app's ability to export data. Will need to be fixed. But the file-writing process is automic so the previous file should get cleared.
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
    
    /// Create and save a new bag to this view.
    @objc func addNewBag()
    {
        // Create a text input view to allow the user to enter a name for the new bag.
        let input = MMTextInputView(frame: CGRect(x: 0, y: mainHeader.frame.origin.y + mainHeader.frame.size.height, width: self.frame.size.width, height: rowHeight), animated: true)
        input.delegate = self
        self.insertSubview(input, belowSubview: mainHeader)
        
        // Insert the new bag into the CoreData model.
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "Bag", in: MMSession.sharedSession.managedObjectContext)
            else { return }
        let newBag = Bag(entity: entityDescription, insertInto: MMSession.sharedSession.managedObjectContext)
        newBag.updateLastEdited()
        
        // Update this view's current bag to match the bag currently being created.
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
    
    private func rowSelected(_ indexPath : IndexPath)
    {
        guard let selectedBag = mainTableView.fetchedResultsController.object(at: indexPath) as? Bag
            else { return }
        let sbv = MMSingleBagView(frame: self.frame, bag: selectedBag)
        sbv.navDelegate = self
        animateViewOn(sbv)
    }
    
    // MARK: Navigation Delegate
    
    /// Called when a selected bag is ready to be dismissed from this view.
    func navigationDelegateViewClosed(_ view: UIView)
    {
        animateViewOff(view)
    }
    
    /// Used to animate views over this bags view. Use this to create consistent animations when displaying a new view on top of this one.
    private func animateViewOn(_ view : UIView)
    {
        let initialFrame = view.frame
        view.frame = CGRect(x: 0, y: self.frame.size.height, width: view.frame.size.width, height: view.frame.size.height)
        self.addSubview(view)
        UIView.animate(withDuration: 0.25,
                                   delay: 0,
                                   options: UIView.AnimationOptions.curveEaseOut,
                                   animations: {
                                    self.contentView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                                    view.frame = initialFrame
        }) { (completed) in
        }
    }
    
    /// Call this to remove a view that has been displayed using the "animateViewOn" method.
    private func animateViewOff(_ view : UIView)
    {
        UIView.animate(withDuration: 0.25,
                                   delay: 0,
                                   options: UIView.AnimationOptions.curveEaseOut,
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

/// Different action types for a bags table view. Currently, these table view elements can only be moved.
enum MMTableViewActionTypes
{
    case move
}

/// The protocol for a table view that displays bags.
protocol MMBagsTableViewDelegate
{
    /// Called when a row in a bags table view is selected.
    func tableViewRowSelected(_ tableView: UITableView, indexPath: IndexPath)
    /// Called when a row is long-pressed in a bags table view.
    func tableViewRowLongPressed(_ tableView: UITableView, indexPath: IndexPath)
    /// Called when a view action type was selected on a specific row in a bags table view.
    func tableViewActionViewItemSelected(_ tableView: UITableView, indexPath: IndexPath, actionType: MMTableViewActionTypes)
}

/// The table view used to display bags.
final class MMBagsTableView: MMDefaultFetchedResultsTableView
{
    /// The delegate for handling selections from the rows in this table view.
    internal var selectionDelegate : MMBagsTableViewDelegate?
    
    /// Configure the cells in this table view.
    override func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath)
    {
        super.configureCell(cell, atIndexPath: indexPath)
        guard let record = fetchedResultsController.object(at: indexPath) as? Bag
            else { return }
        cell.textLabel?.text = record.name
    }
    
    /// Set the height for rows in this table view.
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 100
    }
    
    /// Handle selections for rows in this table view by calling the right delegate method from MMBagsTableViewDelegate.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        super.tableView(tableView, didSelectRowAt: indexPath)
        selectionDelegate?.tableViewRowSelected(self, indexPath: indexPath)
    }
}
