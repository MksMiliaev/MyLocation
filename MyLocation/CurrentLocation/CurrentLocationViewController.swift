//
//  ViewController.swift
//  MyLocation
//
//  Created by Миляев Максим on 10.04.2022.
//

import UIKit
import CoreLocation

class CurrentLocationViewController: UIViewController {
    
    let locationManager = CLLocationManager()
    var location: CLLocation?
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    
    //----------------------------------------------------------------------------------------
    // MARK: - Life Cycle
    //----------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
        
    }

    //----------------------------------------------------------------------------------------
    // MARK: - Actions
    //----------------------------------------------------------------------------------------
    @IBAction func getLocation(_ sender: Any) {
        let authStatus = locationManager.authorizationStatus
        if authStatus == .notDetermined{
            locationManager.requestWhenInUseAuthorization()
            return
        }
        if authStatus == .denied || authStatus == .restricted{
            showLocationServiceDeniedAlert()
            return
        }
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
    }
}
//----------------------------------------------------------------------------------------
// MARK: - CLLocationManagerDelegate
//----------------------------------------------------------------------------------------
extension CurrentLocationViewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Did fail with error: \(error.localizedDescription)")
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
        updateLabels()
        
    }
    func updateLabels(){
        if let location = location{
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            tagButton.isHidden = false
            messageLabel.text = ""
        }else{
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.isHidden = true
            messageLabel.text = "Tap 'Get My Location' to START"
        }
    }
}

//----------------------------------------------------------------------------------------
// MARK: - Helper Methods
//----------------------------------------------------------------------------------------
extension CurrentLocationViewController{
    func showLocationServiceDeniedAlert(){
        let alert = UIAlertController(title: "Location Service disabled",
                                      message: "Please enable location service in Settings",
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK",
                                     style: .default,
                                     handler: nil)
        alert.addAction(okAction)
        present(alert,
                animated: true,
                completion: nil)
    }
}
