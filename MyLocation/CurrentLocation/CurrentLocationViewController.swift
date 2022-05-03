//
//  ViewController.swift
//  MyLocation
//
//  Created by Миляев Максим on 10.04.2022.
//

import UIKit
import CoreLocation
import CoreData
import AudioToolbox

class CurrentLocationViewController: UIViewController {
    
    // core data object context
    var managedObjectContext: NSManagedObjectContext!

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
    
    //sound
    var soundID: SystemSoundID = 0
    
    //labels outlets
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    @IBOutlet weak var latitudeTextLabel: UILabel!
    @IBOutlet weak var longitudeTextLabel: UILabel!
    
    @IBOutlet weak var conteinerView: UIView!
    
    //buttons outlets
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    
    var isLogoVisible = false
    lazy var logoButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setBackgroundImage(UIImage(named: "Logo"),
                                  for: .normal)
        button.sizeToFit()
        button.addTarget(self,
                         action: #selector (getLocation),
                         for: .touchUpInside)
        button.center.x = self.view.bounds.midX
        button.center.y = 220
        return button
    }()
    
    //----------------------------------------------------------------------------------------
    // MARK: - Life Cycle
    //----------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSoundEffect(name: "Sound.caf")
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
    // MARK: - Sound Effects
    //----------------------------------------------------------------------------------------
    func loadSoundEffect(name: String){
        if let path = Bundle.main.path(forResource: name, ofType: nil){
            let fileURL = URL(fileURLWithPath: path, isDirectory: false)
            let error = AudioServicesCreateSystemSoundID(fileURL as CFURL, &soundID)
            if error != kAudioServicesNoError{
                print("Error code \(error) loading sound \(path)")
            }
        }
    }
    func unloadSoundEffect(){
        AudioServicesDisposeSystemSoundID(soundID)
        soundID = 0
    }
    
    func playSoundEffect(){
        AudioServicesPlaySystemSound(soundID)
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
        if isLogoVisible{
            hideLogoView()
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
            vc.managedObjectContext = managedObjectContext
        }
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - methods
    //----------------------------------------------------------------------------------------
    func showLogoView(){
        if !isLogoVisible{
            isLogoVisible = true
            conteinerView.isHidden = true
            logoButton.alpha = 0.0
            view.addSubview(logoButton)
            UIView.animate(withDuration: 0.3) {
                self.logoButton.alpha = 1.0
            }
            
        }
    }
    func hideLogoView(){
//        isLogoVisible = false
//        conteinerView.isHidden = false
//        logoButton.removeFromSuperview()
        
        //animation
        guard isLogoVisible else { return }
        getButton.isUserInteractionEnabled = false
        isLogoVisible = false
        conteinerView.isHidden = false
        conteinerView.center.x = view.bounds.size.width / 2
        conteinerView.center.y = 40 + conteinerView.bounds.size.height / 2
        
        let centerX = view.bounds.midX
        
        let panelMover = CABasicAnimation(keyPath: "position")
        panelMover.isRemovedOnCompletion = false
        panelMover.fillMode = .forwards
        panelMover.duration = 0.76
        panelMover.fromValue = NSValue(cgPoint: CGPoint(x: centerX, y: -conteinerView.center.y))
        panelMover.toValue = NSValue(cgPoint: CGPoint(x: centerX, y: conteinerView.center.y))
        panelMover.timingFunction = CAMediaTimingFunction(name: .easeOut)
        panelMover.delegate = self
        conteinerView.layer.add(panelMover, forKey: "panelMover")

        let logoMover = CABasicAnimation(keyPath: "position")
        logoMover.isRemovedOnCompletion = false
        logoMover.fillMode = .forwards
        logoMover.duration = 0.75
        logoMover.fromValue = NSValue(cgPoint: logoButton.center)
        logoMover.toValue = NSValue(cgPoint: CGPoint(x: -centerX, y: logoButton.center.y))
        logoMover.timingFunction = CAMediaTimingFunction(name: .easeIn)
        logoButton.layer.add(logoMover, forKey: "logoMover")
        
        let logoRotator = CABasicAnimation(keyPath: "transform.rotation.z")
        logoRotator.isRemovedOnCompletion = false
        logoRotator.fillMode = .forwards
        logoRotator.duration = 0.75
        logoRotator.fromValue = 0.0
        logoRotator.toValue = -1 * ((logoButton.bounds.size.width * 2 * CGFloat.pi) / (centerX * 2))
        logoRotator.timingFunction = CAMediaTimingFunction(name: .easeIn)
        logoButton.layer.add(logoRotator, forKey: "logoRotator")
   
    }
    
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
            latitudeTextLabel.isHidden = false
            longitudeTextLabel.isHidden = false
        }else{
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.isHidden = true
            latitudeTextLabel.isHidden = true
            longitudeTextLabel.isHidden = true
            
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
                statusMessage = ""
                showLogoView()
            }
            
            messageLabel.text = statusMessage
        }
        configureGetButton()
    }
    
    func configureGetButton(){
        let spinnerTag = 1000
        
        if updatingLocation{
            getButton.setTitle("Stop", for: .normal)
            
            if view.viewWithTag(spinnerTag) == nil {
                let spinner = UIActivityIndicatorView(style: .medium)
                spinner.center = messageLabel.center
                spinner.center.y += spinner.bounds.size.height / 2 + 25
                spinner.tag = spinnerTag
                spinner.startAnimating()
                conteinerView.addSubview(spinner)
            }
        } else {
            getButton.setTitle("Get My Location", for: .normal)
            
            if let spinner = view.viewWithTag(spinnerTag){
                spinner.removeFromSuperview()
            }
        }
    }
}

//----------------------------------------------------------------------------------------
// MARK: - CAAnimationDelegate
//----------------------------------------------------------------------------------------
extension CurrentLocationViewController: CAAnimationDelegate{
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        conteinerView.layer.removeAllAnimations()
        conteinerView.center = CGPoint(x: view.bounds.size.width / 2,
                                       y: 40 + conteinerView.bounds.size.height / 2)
        logoButton.layer.removeAllAnimations()
        logoButton.removeFromSuperview()
        getButton.isUserInteractionEnabled = true
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
                        if self.placemark == nil{
                            print("FIRST TIME!")
                            self.playSoundEffect()
                        }
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
