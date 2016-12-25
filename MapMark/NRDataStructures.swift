//
//  NRDataStructures.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/8/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import Foundation

public struct NRStack<T>
{
    fileprivate var items = [T]()
    
    public init()
    {
    }
    
    public mutating func push(_ item : T)
    {
        items.append(item)
    }
    
    public mutating func pop() -> T
    {
        return items.removeLast()
    }
    
    public func empty() -> Bool { return !Bool(items.count) }
    public func size() -> Int { return items.count }
}

public struct NRQueue<T>
{
    fileprivate var items = [T]()
    
    public mutating func pushBack(_ item : T)
    {
        items.insert(item, at: 0)
    }
    
    public mutating func popFront() -> T
    {
        return items.removeLast()
    }
    
    public func front() -> T?
    {
        if (!empty())
        {
            return items[items.endIndex - 1]
        }
        else
        {
            return nil
        }
    }
    
    public func back() -> T?
    {
        if (!empty())
        {
            return items[0]
        }
        else
        {
            return nil
        }
    }
    
    public func empty() -> Bool { return !Bool(items.count) }
    public func size() -> Int { return items.count }
}
