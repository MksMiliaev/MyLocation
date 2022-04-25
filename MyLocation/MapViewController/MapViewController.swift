//
//  MapViewController.swift
//  MyLocation
//
//  Created by Миляев Максим on 21.04.2022.
//

import Foundation
import MapKit
import CoreData

class MapViewcontroller: UIViewController{
    
    @IBOutlet weak var mapView: MKMapView!
    
    var managedObjectContext: NSManagedObjectContext! {
        didSet{
            NotificationCenter.default.addObserver(forName: Notification.Name.NSManagedObjectContextObjectsDidChange,
                                                   object: managedObjectContext,
                                                   queue: OperationQueue.main) { _ in
                if self.isViewLoaded{
                    self.updateLocations()
                }
            }
        }
    }
    
    var locations = [Location]()
    
    //----------------------------------------------------------------------------------------
    // MARK: - life cycle
    //----------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        updateLocations()
//        mapView.showsUserLocation = true

        if !locations.isEmpty{
            showLocation()
        }

    }
    
    
    
    //----------------------------------------------------------------------------------------
    // MARK: - Helper methods
    //----------------------------------------------------------------------------------------
    func updateLocations(){
        mapView.removeAnnotations(locations)
        
        let entity = Location.entity()
        
        let fetchRequest = NSFetchRequest<Location>()
        fetchRequest.entity = entity
        
        locations = try! managedObjectContext.fetch(fetchRequest)
        mapView.addAnnotations(locations)
    }
    
    func region(for annotations: [MKAnnotation]) -> MKCoordinateRegion{
        let region: MKCoordinateRegion
        
        switch annotations.count{
        case 0:
            region = MKCoordinateRegion(center: mapView.userLocation.coordinate,
                                        latitudinalMeters: 1000,
                                        longitudinalMeters: 1000)
        case 1:
            let annotation = annotations[annotations.count - 1]
            region = MKCoordinateRegion(center: annotation.coordinate,
                                        latitudinalMeters: 1000,
                                        longitudinalMeters: 1000)
        default:
            var topLeft = CLLocationCoordinate2D(latitude: -90,
                                                 longitude: 180)
            var bottomRight = CLLocationCoordinate2D(latitude: 90, longitude: -180)
            
            for annotation in annotations {
                topLeft.latitude = max(topLeft.latitude,
                                       annotation.coordinate.latitude)
                topLeft.longitude = min(topLeft.longitude,
                                        annotation.coordinate.longitude)
                bottomRight.latitude = min(bottomRight.latitude,
                                           annotation.coordinate.latitude)
                bottomRight.longitude = max(bottomRight.longitude,
                                            annotation.coordinate.longitude)
            }
            let center = CLLocationCoordinate2D(latitude: topLeft.latitude - (topLeft.latitude - bottomRight.latitude) / 2,
                                                longitude: topLeft.longitude - (topLeft.longitude - bottomRight.longitude) / 2)
            let extraSpace = 1.1
            let span = MKCoordinateSpan(latitudeDelta: abs(topLeft.latitude - bottomRight.latitude) * extraSpace,
                                        longitudeDelta: abs(topLeft.longitude - bottomRight.longitude) * extraSpace)
            region = MKCoordinateRegion(center: center, span: span)
        }
        return mapView.regionThatFits(region)
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Navigation
    //----------------------------------------------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditLocationSegue",
            let controller = segue.destination as? LocationDetailViewController{
            controller.managedObjectContext = managedObjectContext
            let button = sender as! UIButton
            controller.locationToEdit = locations[button.tag]
        }
    }
    
    @objc func showLocationDetails(_ sender: UIButton){
        performSegue(withIdentifier: "EditLocationSegue", sender: sender)
    }
    
    
    //----------------------------------------------------------------------------------------
    // MARK: - Actions
    //----------------------------------------------------------------------------------------

    @IBAction func showUser(_ sender: Any) {
        let region = MKCoordinateRegion(center: mapView.userLocation.coordinate,
                                        latitudinalMeters: 1000,
                                        longitudinalMeters: 1000)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)

    }
    
    @IBAction func showLocation() {
        let theRegion = region(for: locations)
        mapView.setRegion(theRegion, animated: true)
    }
    

}

//----------------------------------------------------------------------------------------
// MARK: - MKMapViewDelegate
//----------------------------------------------------------------------------------------
extension MapViewcontroller: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is Location else { return nil }
        
        let identifier = "Location"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil {
            let markerView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            markerView.isEnabled = true
            markerView.canShowCallout = true
            markerView.animatesWhenAdded = true
            markerView.markerTintColor = UIColor(red: 0.32,
                                                 green: 0.82,
                                                 blue: 0.4,
                                                 alpha: 1)
            markerView.glyphImage = UIImage(systemName: "gamecontroller")
            markerView.glyphTintColor = .red
            let rightButton = UIButton(type: .detailDisclosure)
            rightButton.addTarget(self,
                                  action: #selector (showLocationDetails(_:)),
                                                     for: .touchUpInside)
            markerView.rightCalloutAccessoryView = rightButton
            annotationView = markerView
        }
        
        if let annotationView = annotationView {
            annotationView.annotation = annotation
            let button = annotationView.rightCalloutAccessoryView as! UIButton
            if let index = locations.firstIndex(of: annotation as! Location){
                button.tag = index
            }
        }
       return annotationView
    }
}
