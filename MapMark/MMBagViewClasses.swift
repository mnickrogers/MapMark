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
    private var fetchedResultsController : NSFetchedResultsController!
    
    convenience init(frame: CGRect, fetchedResultsController: NSFetchedResultsController)
    {
        self.init(frame: frame, style: .Plain)
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
