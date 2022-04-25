//
//  LocationDetailViewController.swift
//  MyLocation
//
//  Created by Миляев Максим on 14.04.2022.
//

import UIKit
import CoreLocation
import CoreData
import PhotosUI

class LocationDetailViewController: UITableViewController {
   
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    //edit state
    var locationToEdit: Location?{
        didSet{
            if let location = locationToEdit{
                descriptionText = location.locationDescription
                category = location.category
                placemark = location.placemark
                date = location.date
                coordinate = CLLocationCoordinate2D(latitude: location.latitude,
                                                    longitude: location.longitude)
            }
        }
    }
    
    //
    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var placemark: CLPlacemark?
    var category = "No category"
    var date = Date()
    var descriptionText = ""
    
    // core data object context
    var managedObjectContext: NSManagedObjectContext!

    //----------------------------------------------------------------------------------------
    // MARK: - life cycle
    //----------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        if locationToEdit != nil{
            title = "Edit Location"
        }
        descriptionTextView.text = descriptionText
        categoryLabel.text = category
        
        latitudeLabel.text = String(format: "%.6f",  coordinate.latitude)
        longitudeLabel.text = String(format: "%.6f",  coordinate.longitude)
        if let placemark = placemark{
            addressLabel.text = Helper.current.string(from: placemark)
        } else {
            addressLabel.text = "No address found"
        }
        dateLabel.text = Helper.current.dateFormatter.string(from: date)
        
        
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
        guard let mainView = navigationController?.parent?.view else { return }
        let hudView = HudView.hud(inView: mainView, animated: true)
        let location: Location
        
        if let temp = locationToEdit{
            hudView.text = "Updated"
            location = temp
        } else {
        location = Location(context: managedObjectContext)
        hudView.text = "Tagged"
        }
        
        location.locationDescription = descriptionTextView.text
        location.latitude = coordinate.latitude
        location.longitude = coordinate.longitude
        location.category = category
        location.date = date
        location.placemark = placemark
        
        do{
            try managedObjectContext.save()
            afterDelay(sec: 0.6) {
                hudView.hide(completionHandler: {
                    self.navigationController?.popViewController(animated: true)
                })
            }
        } catch {
            fatalCoreDataError(error)
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
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 && indexPath.row == 0{
            descriptionTextView.becomeFirstResponder()
        } else if indexPath.section == 1 &&  indexPath.row == 0 {
            takePhotoFromLibrary()
        }
    }
}

//----------------------------------------------------------------------------------------
// MARK: - UIImagePickerControllerDelegate
//----------------------------------------------------------------------------------------
extension LocationDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func takePhotoWithCamera(){
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker,
                animated: true,
                completion: nil)
    }
}

//----------------------------------------------------------------------------------------
// MARK: - PHPickerViewControllerDelegate
//----------------------------------------------------------------------------------------
extension LocationDetailViewController: PHPickerViewControllerDelegate{
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        //TODO: handle selected image
        
        
    }
    func takePhotoFromLibrary(){
        let configuration = PHPickerConfiguration(photoLibrary: .shared())
        let imagePicker = PHPickerViewController(configuration: configuration)
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
