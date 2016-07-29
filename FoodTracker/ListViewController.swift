//
//  ListViewController.swift
//  FoodTracker
//
//  Created by Kalpesh Balar on 17/07/16.
//  Copyright © 2016 Kalpesh Balar. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class ListViewController: UIViewController, NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    var pin: Pin!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var reloadButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        self.activityIndicator.alpha = 0.0
        self.activityIndicator.stopAnimating()
        super.viewDidLoad()
        addPin()
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            displayError("Error reading local database")
        }
        
        fetchedResultsController.delegate = self
    }
    
    func addPin() {
        let pincoordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = pincoordinate
        mapView.addAnnotation(annotation)
        let mapRegion:MKCoordinateRegion? = MKCoordinateRegion(center: pincoordinate, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        self.mapView.setRegion(mapRegion!, animated: true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if pin.places.isEmpty {
            self.reloadCollection(nil)
        }
        else {
            reloadButton.enabled = true
        }
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }

    lazy var fetchedResultsController: NSFetchedResultsController = {
        // Create the fetch request
        let fetchRequest = NSFetchRequest(entityName: "Place")
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin);
        
        // Add a sort descriptor. This enforces a sort order on the results that are generated
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "rating", ascending: false)]
        
        // Create the Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Return the fetched results controller. It will be the value of the lazy variable
        return fetchedResultsController
    }()

    @IBAction func reloadCollection(sender: AnyObject?) {
        self.activityIndicator.alpha = 1.0
        self.activityIndicator.startAnimating()
        
        sharedContext.performBlockAndWait({
            for place in self.fetchedResultsController.fetchedObjects as! [Place] {
                place.pin = nil
                self.sharedContext.deleteObject(place)
            }
            self.saveContext()
        })
        
        FourSquareDB.sharedInstance().searchPlacesByLatLon(pin) { JSONResult, error  in

            if let error = error {
                self.displayError(error.localizedDescription)
            } else {
                if let groups = JSONResult.valueForKey("groups") as? [[String: AnyObject]] {
                    for group in groups {
                        if let items = group["items"] as? [[String: AnyObject]] {
                            for item in items {
                                let dictionary = item["venue"] as? Dictionary<String, AnyObject>
                                let place = Place(dictionary: dictionary!, context: self.sharedContext)
                                place.pin = self.pin
                            }
                        }
                    }
                    self.saveContext()
                    
                    // Update the table on the main thread
                    dispatch_async(dispatch_get_main_queue()) {
                        self.activityIndicator.alpha = 0.0
                        self.activityIndicator.stopAnimating()
                        self.tableView.reloadData()
                    }
                }
                return
            }
        }
    }
    
    //table view methods:
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            let CellIdentifier = "PlaceCell"
        
            // Here is how to replace the actors array using objectAtIndexPath
            let place = fetchedResultsController.objectAtIndexPath(indexPath) as! Place
            let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier)
            
            // This is the new configureCell method
            configureCell(cell!, place: place)
            return cell!
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle,
        forRowAtIndexPath indexPath: NSIndexPath) {
            
            switch (editingStyle) {
            case .Delete:
                // Here we get the actor, then delete it from core data
                let place = fetchedResultsController.objectAtIndexPath(indexPath) as! Place
                sharedContext.deleteObject(place)
                CoreDataStackManager.sharedInstance().saveContext()
            default:
                break
            }
    }
    
    // MARK: - Configure Cell
    func configureCell(cell: UITableViewCell, place: Place) {
        cell.textLabel!.text = place.title
        cell.detailTextLabel!.text = place.address
    }

    
    // MARK: - Fetched Results Controller Delegate
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
  
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
        atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
            case .Insert:
                self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
                
            case .Delete:
                self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
                
            default:
                return
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
            case .Insert:
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            case .Delete:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            case .Update:
                let cell = tableView.cellForRowAtIndexPath(indexPath!)
                let place = controller.objectAtIndexPath(indexPath!) as! Place
                self.configureCell(cell!, place: place)
            case .Move:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            default:
                return
            }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
    
    func displayError(errorString: String?) {
        dispatch_async(dispatch_get_main_queue(), {
            self.activityIndicator.alpha = 0.0
            self.activityIndicator.stopAnimating()

            if let errorString = errorString {
                let alertController:UIAlertController = UIAlertController(title: "Error", message: errorString, preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        })
    }
 }































