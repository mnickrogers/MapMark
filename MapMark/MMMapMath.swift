//
//  MMMapMath.swift
//  MapMark
//
//  Created by Nicholas Rogers on 7/8/16.
//  Copyright © 2016 Nicholas Rogers. All rights reserved.
//

import Foundation
import MapKit

public struct Coordinate
{
    public var latitude: Double
    public var longitude: Double
    
    public var hashValue: Int
    {
        return abs(Int(Int(latitude) + Int(longitude)) & Int(latitude) & Int(longitude) + Int(latitude * longitude))
    }
    
    public var description: String
    {
        return "Latitude: \(latitude), Longitude: \(longitude)"
    }
}

extension Coordinate: Hashable {}
extension Coordinate: Equatable {}
public func ==(lhs: Coordinate, rhs: Coordinate) -> Bool
{
    return lhs.hashValue == rhs.hashValue
}

public func haversine(coordinate1: CLLocationCoordinate2D, coordinate2: CLLocationCoordinate2D) -> Double
{
    return haversine(coordinate1.latitude, longitude1: coordinate1.longitude, latitude2: coordinate2.latitude, longitude2: coordinate2.longitude)
}

public func haversine(coordinate1: Coordinate, coordinate2: Coordinate) -> Double
{
    return haversine(coordinate1.latitude, longitude1: coordinate1.longitude, latitude2: coordinate2.latitude, longitude2: coordinate2.longitude)
}

public func haversine(latitude1: Double, longitude1: Double, latitude2: Double, longitude2: Double) -> Double
{
    let coords = [latitude1, longitude1, latitude2, longitude2]
    let radianCoords = coords.map {degreesToRadians($0)}
    
    let deltaLat = radianCoords[2] - radianCoords[0]
    let deltaLon = radianCoords[3] - radianCoords[1]
    
    let a = pow(sin(deltaLat / 2.0), 2.0) + cos(radianCoords[0]) * cos(radianCoords[2]) * pow(deltaLon / 2.0, 2.0)
    let c = 2.0 * asin(sqrt(a))
    let r = 3959.0 // Use 6371 for km
    return c * r
}

public func degreesToRadians(degrees: Double) -> Double
{
    return degrees * (M_PI / 180.0)
}

public func findShortestPath(start: Coordinate, points: [Coordinate]) -> [Coordinate]
{
    var path = [Coordinate]()
    var visited = Set<Coordinate>()
    var stack = NRStack<Coordinate>()
    stack.push(start)
    path.append(start)
    
    // Set initial values.
    visited.insert(start)
    print(start.hashValue)
    print(points[2].hashValue)
    if visited.contains(points[2])
    {
        print("It's here")
    }
    
    while !stack.empty()
    {
        let top = stack.pop()
        var shortest: Coordinate?
        for point in points
        {
            print("Here")
            if !visited.contains(point)
            {
                var deltaTopToPoint: Double
                if shortest == nil
                {
                    deltaTopToPoint = haversine(top, coordinate2: point)
                }
                else
                {
                    deltaTopToPoint = haversine(top, coordinate2: shortest!)
                }
                let distance = haversine(top, coordinate2: point)
                if distance <= deltaTopToPoint
                {
                    shortest = point
                }
            }
        }
        
        if shortest != nil
        {
            if !visited.contains(shortest!)
            {
                visited.insert(shortest!)
                path.append(shortest!)
                stack.push(shortest!)
            }
        }
    }
    
    return path
}
