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
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var addPhotoLabel: UILabel!
    
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
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
    var image: UIImage?
    
    // core data object context
    var managedObjectContext: NSManagedObjectContext!
    
    //observer
    var observer: Any?

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
        listenForBackgroundNotification()
    }
    deinit {
        print("*** deinit \(self)")
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
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
    
    func show(image: UIImage){
        let aR = image.size.width / image.size.height
        addPhotoLabel.text = ""
        imageView.contentMode = .scaleAspectFit
        imageView.alpha = 0
        imageView.isHidden = false
        tableView.beginUpdates()
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       options: [.curveEaseInOut]) {
            self.imageViewHeight.constant = aR > 0 ? 365 / aR : 365 * aR
            self.imageView.image = image
            self.imageView.alpha = 1
        } completion: { _ in
            
        }
        tableView.endUpdates()

    }
    func showPhotoMenu(){
        if UIImagePickerController.isSourceTypeAvailable(.camera){
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { _ in
            self.takePhotoWithCamera()
        }
        alertController.addAction(cameraAction)
        let libraryAction = UIAlertAction(title: "Media Library", style: .default) { _ in
            self.takePhotoFromLibrary()
        }
        alertController.addAction(libraryAction)
        } else {
            takePhotoFromLibrary()
        }
    }
    func listenForBackgroundNotification(){
        observer = NotificationCenter.default.addObserver(forName: UIScene.didEnterBackgroundNotification,
                                                          object: nil,
                                                          queue: OperationQueue.main) { [weak self] _ in
            if let weakSelf = self{
                if weakSelf.presentedViewController != nil {
                    weakSelf.dismiss(animated: true, completion: nil)
                }
                weakSelf.descriptionTextView.resignFirstResponder()
            }
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
            showPhotoMenu()
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
        if !results.isEmpty{
            results[0].itemProvider.loadObject(ofClass: UIImage.self) {[weak self] image, error in
                
                if let image = image as? UIImage{
                    self?.image = image
                    DispatchQueue.main.async {
                        //
//                        let aR = image.size.width / image.size.height
//                        self?.addPhotoLabel.text = ""
//                        self?.imageView.contentMode = .scaleAspectFit
//                        self?.imageViewHeight.constant = aR > 0 ? 365 / aR : 365 * aR
//                        self?.imageView.image = image
//                        self?.tableView.reloadData()
                        //
                        self?.show(image: image)
                    }
                }
                if let error = error {
                    print("error: \(error.localizedDescription)")
                }
            }
        }
        dismiss(animated: true, completion: nil)
    }
    func takePhotoFromLibrary(){
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = 1
        configuration.filter = .images
        let imagePicker = PHPickerViewController(configuration: configuration)
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        dismiss(animated: true, completion: nil)
//    }
//    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//        dismiss(animated: true, completion: nil)
//    }
}
