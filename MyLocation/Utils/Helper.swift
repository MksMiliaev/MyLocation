//
//  Helper.swift
//  MyLocation
//
//  Created by Миляев Максим on 14.04.2022.
//

import UIKit
import CoreLocation

class Helper {
   static let current = Helper()
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    func string(from placemark: CLPlacemark) -> String{
        var line1 = ""
        if let subThoroughfare = placemark.subThoroughfare{
            line1 += subThoroughfare + " "
        }
        if let thouroughfare = placemark.thoroughfare{
            line1 += thouroughfare
        }
        var line2 = ""
        if let city = placemark.locality{
            line2 += city + " "
        }
        if let postalCode = placemark.postalCode{
            line2 += postalCode
        }
        
        return line1 + "\n" + line2
    }
}
