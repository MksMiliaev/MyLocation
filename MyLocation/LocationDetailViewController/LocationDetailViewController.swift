//
//  LocationDetailViewController.swift
//  MyLocation
//
//  Created by Миляев Максим on 14.04.2022.
//

import UIKit
import CoreLocation
import CoreData

class LocationDetailViewController: UITableViewController {
    
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var placemark: CLPlacemark?
    
    var category = "No category"
    
    // core data object context
    var managedObjectContext: NSManagedObjectContext!

    //----------------------------------------------------------------------------------------
    // MARK: - life cycle
    //----------------------------------------------------------------------------------------
    override func viewDidLoad() {
        descriptionTextView.text = ""
        categoryLabel.text = category
        
        latitudeLabel.text = String(format: "%.6f",  coordinate.latitude)
        longitudeLabel.text = String(format: "%.6f",  coordinate.longitude)
        if let placemark = placemark{
            addressLabel.text = Helper.current.string(from: placemark)
        } else {
            addressLabel.text = "No address found"
        }
        dateLabel.text = Helper.current.dateFormatter.string(from: Date())
        
        let gestRecognizer = UITapGestureRecognizer(target: self,
                                                    action: #selector(hideKeyboard))
        gestRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(gestRecognizer)
    }
    //----------------------------------------------------------------------------------------
    // MARK: - methods
    //----------------------------------------------------------------------------------------
    @objc func hideKeyboard(_ gestureRecognizer: UITapGestureRecognizer){
        let point = gestureRecognizer.location(in: tableView)
        if let indexPath = tableView.indexPathForRow(at: point){
            if indexPath.section == 0 && indexPath.row == 0{
                return
            } else {
                descriptionTextView.resignFirstResponder()
            }
        } else {
            descriptionTextView.resignFirstResponder()
        }
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Navigation
    //----------------------------------------------------------------------------------------
    @IBAction func categoryPickerDidPickCategory(_ segue: UIStoryboardSegue){
        if let souceVC = segue.source as? CategoryPickerTableViewController{
            category = souceVC.selectedCategoryName
            categoryLabel.text = category
            print(category)
        }
        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PickerSegue", let vc = segue.destination as? CategoryPickerTableViewController{
            vc.selectedCategoryName = category
        }
    }
    //----------------------------------------------------------------------------------------
    // MARK: - Actions
    //----------------------------------------------------------------------------------------
    @IBAction func done(_ sender: Any) {
//        navigationController?.popViewController(animated: true)
        guard let mainView = navigationController?.parent?.view else { return }
        let hudView = HudView.hud(inView: mainView, animated: true)
        hudView.text = "Tagged"
        let delayInSec = 0.6
        afterDelay(sec: delayInSec) {
            hudView.hide(completionHandler: {
                self.navigationController?.popViewController(animated: true)
            })
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - table view delegate
    //----------------------------------------------------------------------------------------
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 0  || indexPath.section == 1{
            return indexPath
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 0{
            descriptionTextView.becomeFirstResponder()
        }
    }
}
