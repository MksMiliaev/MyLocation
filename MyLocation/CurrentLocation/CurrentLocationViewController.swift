//
//  ViewController.swift
//  MyLocation
//
//  Created by Миляев Максим on 10.04.2022.
//

import UIKit
import CoreLocation

class CurrentLocationViewController: UIViewController {
    
    //location obtain and errors
    let locationManager = CLLocationManager()
    var location: CLLocation?
    
    var updatingLocation = false
    var lastLocationError: Error?
    
    //placemark obtain and errors
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverceGeoCoding = false
    var lastGeoCodingError: Error?
    
    //timer
    var timer: Timer?
    
    //labels outlets
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    //buttons outlets
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    
    //----------------------------------------------------------------------------------------
    // MARK: - Life Cycle
    //----------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
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
        if updatingLocation{
            stopLocationManager()
        } else {
            location = nil
            lastLocationError = nil
            startLocationManager()
        }
        
        updateLabels()
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Navigation
    //----------------------------------------------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TagLocation", let vc = segue.destination as? LocationDetailViewController{
            vc.coordinate = location!.coordinate
            vc.placemark = placemark
        }
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - methods
    //----------------------------------------------------------------------------------------
    func startLocationManager(){
        placemark = nil
        lastGeoCodingError = nil
        if CLLocationManager.locationServicesEnabled(){
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
            timer = Timer.scheduledTimer(timeInterval: 60,
                                         target: self,
                                         selector: #selector(didTimeOut),
                                         userInfo: nil,
                                         repeats: false)
        }
    }
    func stopLocationManager(){
        if updatingLocation {
            locationManager.stopUpdatingLocation()
            updatingLocation = false
            locationManager.delegate = nil
            if let timer = timer {
                timer.invalidate()
            }
        }
    }
    @objc
    func didTimeOut(){
        print("*** Time Out!")
        if location == nil{
            stopLocationManager()
            lastLocationError = NSError(domain: "MyLocationsErrorDpmain",
                                        code: 1,
                                        userInfo: nil)
            updateLabels()
        }
    }
    func updateLabels(){
        if let location = location{
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            tagButton.isHidden = false
            messageLabel.text = ""
            
            if let placemark = placemark{
                addressLabel.text = Helper.current.string(from: placemark)
            } else if performingReverceGeoCoding {
                addressLabel.text = "Searchng for address..."
            } else if lastGeoCodingError == nil{
                addressLabel.text = "Error finding address"
            } else {
                addressLabel.text = "No address found"
            }
        }else{
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.isHidden = true
            
            let statusMessage: String
            if let error = lastLocationError as NSError?{
                if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue{
                    statusMessage = "Location service disabled"
                } else {
                    statusMessage = "Error Getting Location"
                }
            } else if !CLLocationManager.locationServicesEnabled(){
                statusMessage = "Location service disabled"
            } else if updatingLocation {
                statusMessage = "Searching..."
            } else {
                statusMessage = "Tap 'Get My Location' to START"
            }
            
            messageLabel.text = statusMessage
        }
        configureGetButton()
    }
//    func string(from placemark: CLPlacemark) -> String{
//        var line1 = ""
//        if let subThoroughfare = placemark.subThoroughfare{
//            line1 += subThoroughfare + " "
//        }
//        if let thouroughfare = placemark.thoroughfare{
//            line1 += thouroughfare
//        }
//        var line2 = ""
//        if let city = placemark.locality{
//            line2 += city + " "
//        }
//        if let postalCode = placemark.postalCode{
//            line2 += postalCode
//        }
//        
//        return line1 + "\n" + line2
//    }
    
    func configureGetButton(){
        if updatingLocation{
            getButton.setTitle("Stop", for: .normal)
        } else {
            getButton.setTitle("Get My Location", for: .normal)
        }
    }
}
//----------------------------------------------------------------------------------------
// MARK: - CLLocationManagerDelegate
//----------------------------------------------------------------------------------------
extension CurrentLocationViewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        print("Did fail with error: \(error.localizedDescription)")
        if (error as NSError).code == CLError.locationUnknown.rawValue{
            return
        }
        lastLocationError = error
        stopLocationManager()
        updateLabels()
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
//        print("oldLocation is \(String(describing: location ?? nil))")
//        print("did update location \(newLocation)")
        
        if newLocation.timestamp.timeIntervalSinceNow < -5 { //old value - older then 5 sec
            return
        }
        if newLocation.horizontalAccuracy < 0 { //invalid value
            return
        }
        
        var distance = CLLocationDistance(Double.greatestFiniteMagnitude)
        if let location = location{
            distance = newLocation.distance(from: location)
        }
        
        if location == nil || newLocation.horizontalAccuracy < location!.horizontalAccuracy{
            location = newLocation
            lastLocationError = nil
        
        if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy{
//            print("--- We are done!")
            stopLocationManager()
            if distance > 0 {
                performingReverceGeoCoding = false
            }
        }

        updateLabels()
            //location geocoding
            if !performingReverceGeoCoding {
//                print("*** Going to geocode")
                performingReverceGeoCoding = true
                geocoder.reverseGeocodeLocation(newLocation) { placemarks, error in
                    self.lastGeoCodingError = error
                    if error == nil, let places = placemarks, !places.isEmpty{
                        self.placemark = places.last!
                    } else {
                        self.placemark = nil
                    }
                    self.performingReverceGeoCoding = false
                    self.updateLabels()
                }
            }
        } else if distance < 1{
            let timeInterval = newLocation.timestamp.timeIntervalSince(location!.timestamp)
            if timeInterval > 10 {
//                print("*** Force STOP!")
                stopLocationManager()
                updateLabels()
            }
        }
    }
   //class end
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
