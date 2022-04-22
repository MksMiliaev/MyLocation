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
    
    var managedObjectContext: NSManagedObjectContext!
    
    var locations = [Location]()
    
    //----------------------------------------------------------------------------------------
    // MARK: - life cycle
    //----------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLocations()
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
            let annotation = annotations.first!
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
                topLeft.longitude = min(topLeft.latitude,
                                        annotation.coordinate.longitude)
                bottomRight.latitude = min(bottomRight.latitude,
                                           annotation.coordinate.latitude)
                bottomRight.longitude = max(bottomRight.longitude,
                                            annotation.coordinate.longitude)
            }
            let center = CLLocationCoordinate2D(latitude: topLeft.latitude - (topLeft.latitude - bottomRight.latitude / 2),
                                                longitude: topLeft.longitude - (topLeft.longitude - bottomRight.longitude / 2))
            let extraSpace = 1.1
            let span = MKCoordinateSpan(latitudeDelta: abs(topLeft.latitude - bottomRight.latitude) * extraSpace,
                                        longitudeDelta: abs(topLeft.longitude - bottomRight.longitude) * extraSpace)
            region = MKCoordinateRegion(center: center, span: span)
        }
        return mapView.regionThatFits(region)
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
    
}
