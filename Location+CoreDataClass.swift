//
//  Location+CoreDataClass.swift
//  MyLocation
//
//  Created by Миляев Максим on 16.04.2022.
//
//

import Foundation
import CoreData
import MapKit

@objc(Location)
public class Location: NSManagedObject, MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(latitude, longitude)
    }
    public var title: String?{
        if locationDescription.isEmpty{
            return "(No Description)"
        } else {
            return locationDescription
        }
    }
    
    public var subtitle: String?{
        return category
    }
    
    var hasPhoto: Bool {
        return photoID != nil
    }
    
    var photoURL: URL {
        assert(photoID != nil, "No photoID set")
        let filename = "Photo-\(photoID!.intValue).jpg"
        return applicationDocumentDirectory.appendingPathComponent(filename)
    }
    
    var photoImage: UIImage? {
        return UIImage(contentsOfFile: photoURL.path)
    }
    func nextPhotoID() -> Int{
        let currentID = UserDefaults.standard.integer(forKey: "photoID") + 1
        UserDefaults.standard.set(currentID, forKey: "photoID")
        return currentID
    }
}
