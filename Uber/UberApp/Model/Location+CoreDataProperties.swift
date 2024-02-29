//
//  Location+CoreDataProperties.swift
//  Uber
//
//  Created by Umang Kedan on 21/02/24.
//
//

import Foundation
import CoreData


extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var fromCoordinates: NSObject?
    @NSManaged public var toCoordinates: NSObject?
    @NSManaged public var name: String?
    @NSManaged public var path: NSObject?

}

extension Location : Identifiable {

}
