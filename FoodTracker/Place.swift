//
//  Place.swift
//  FoodTracker
//
//  Created by Kalpesh Balar on 17/07/16.
//  Copyright © 2016 Kalpesh Balar. All rights reserved.
//

import UIKit
import CoreData

class Place : NSManagedObject {
    
    struct Keys {
        static let ID = "id"
        static let Name = "name"
        static let Rating = "rating"
        static let Address = "address"
    }
    
    @NSManaged var title: String
    @NSManaged var id: String
    @NSManaged var rating: Double
    @NSManaged var address: String
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Place", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        id = dictionary[Keys.ID] as! String
        title = dictionary[Keys.Name] as! String
        if let ratingF = dictionary[Keys.Rating] as? Double {
            rating = ratingF
        }
        if let location = dictionary["location"] as? [String: AnyObject] {
            if let addressF = location[Keys.Address] as? String {
                address = addressF
            }
        }
    }
}