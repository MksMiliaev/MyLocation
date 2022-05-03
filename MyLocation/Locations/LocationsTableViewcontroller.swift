//
//  LocationsTableViewcontrollerTableViewController.swift
//  MyLocation
//
//  Created by Миляев Максим on 18.04.2022.
//

import UIKit
import CoreLocation
import CoreData

class LocationsTableViewcontroller: UITableViewController {
    
    var managedObjectContext: NSManagedObjectContext!
    lazy var fetchedResultsController: NSFetchedResultsController<Location> = {
       let fetchRequest = NSFetchRequest<Location>()
        let entity = Location.entity()
        fetchRequest.entity = entity
        
        let categorySortDescriptor = NSSortDescriptor(key: "category", ascending: true)
        let dateSortDescriptor = NSSortDescriptor(key: "date",
                                              ascending: true)
        fetchRequest.sortDescriptors = [categorySortDescriptor ,dateSortDescriptor]
        
        fetchRequest.fetchBatchSize = 20
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                               managedObjectContext: managedObjectContext,
                                                               sectionNameKeyPath: "category",
                                                               cacheName: "Locations")
        fetchedResultsController.delegate = self
        return fetchedResultsController
        
    }()
    
    //----------------------------------------------------------------------------------------
    // MARK: - life cycle
    //----------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = editButtonItem
        performFetch()
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Helper Methods
    //----------------------------------------------------------------------------------------
    func performFetch(){
        do {
            try fetchedResultsController.performFetch()
        } catch let error {
            fatalCoreDataError(error)
        }
    }
    
    deinit {
        fetchedResultsController.delegate = nil
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Navigation
    //----------------------------------------------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditLocationSegue"{
            let controller = segue.destination as! LocationDetailViewController
            controller.managedObjectContext = managedObjectContext
            if let indexPath = tableView.indexPath(for: sender as! LocationCell){
                let location = fetchedResultsController.object(at: indexPath)
                controller.locationToEdit = location
            }
        }
    }
    //----------------------------------------------------------------------------------------
    // MARK: - Table view data source
    //----------------------------------------------------------------------------------------
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedResultsController.sections![section].name.uppercased()
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let labelRect = CGRect(x: 15, y: tableView.sectionHeaderHeight - 14,
                               width: 300, height: 14)
        let label = UILabel(frame: labelRect)
        label.font = UIFont.boldSystemFont(ofSize: 11)
        label.text = tableView.dataSource!.tableView!(tableView, titleForHeaderInSection: section)
        
        label.textColor = UIColor(white: 1.0, alpha: 0.6)
        label.backgroundColor = .clear
        
        let separatorRect = CGRect(x: 15, y: tableView.sectionHeaderHeight - 0.5,
                                   width: tableView.bounds.size.width, height: 0.5)
        let separator = UIView(frame: separatorRect)
        separator.backgroundColor = tableView.separatorColor
        
        let viewRect = CGRect(x: 0, y: 0,
                              width: tableView.bounds.size.width,
                              height: tableView.sectionHeaderHeight)
        let view = UIView(frame: viewRect)
        view.backgroundColor = UIColor(white: 0, alpha: 0.65)
        view.addSubview(label)
        view.addSubview(separator)
        
        return view
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationsCell", for: indexPath) as! LocationCell
        let location = fetchedResultsController.object(at: indexPath)
        cell.configureForLocation(location)
        
        return cell
    }
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            let location = fetchedResultsController.object(at: indexPath)
            location.removePhotoFile()
            managedObjectContext.delete(location)
            do{
                try managedObjectContext.save()
            } catch let error{
                fatalCoreDataError(error)
            }
        }
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Table View delegate
    //----------------------------------------------------------------------------------------

}
//----------------------------------------------------------------------------------------
// MARK: - NSFetchedResultsControllerDelegate
//----------------------------------------------------------------------------------------
extension LocationsTableViewcontroller: NSFetchedResultsControllerDelegate{
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("*** ControllerWillChangeContent")
        tableView.beginUpdates()
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            print("*** NSFetchedResultsChangesInsert object")
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            print("*** NSFetchedResultsChangesDelete oblect")
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .move:
            print("*** NSFetchedResultsChangesMove object")
            tableView.deleteRows(at: [indexPath!], with: .fade)
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .update:
            print("*** NSFetchedResultsChangesUpdate object")
            if let cell = tableView.cellForRow(at: indexPath!) as? LocationCell{
                let location = controller.object(at: indexPath!) as! Location
                cell.configureForLocation(location)
            }
        @unknown default:
            print("*** NSFetchedResultsChangesUnknownType")
        }
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            print("*** NSFetchedResultsChangesInsert (sections)")
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            print("*** NSFetchedResultsChangesDelete (sections)")
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .move:
            print("*** NSFetchedResultsChangesMove (section)")
        case .update:
            print("*** NSFetchedResultsChangesUpdate (section)")
        @unknown default:
            print("*** NSFetchedResultsChangesUnknownType")
        }
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("*** controllerDidChangeContent")
        tableView.endUpdates()
    }
}
