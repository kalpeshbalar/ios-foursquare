//
//  Pin.swift
//  Food Tracker
//
//  Created by Kalpesh Balar on 10/07/16.
//  Copyright © 2016 Kalpesh Balar. All rights reserved.
//

import UIKit
import CoreData

class Pin : NSManagedObject {

    struct Keys {
        static let lat = "latitude"
        static let lon = "longitude"
        static let Places = "places"
    }
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var places: [Place]
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        print(dictionary[Keys.lat])
        print(dictionary[Keys.lon])
        latitude = dictionary[Keys.lat] as! Double
        longitude = dictionary[Keys.lon] as! Double
     }
}