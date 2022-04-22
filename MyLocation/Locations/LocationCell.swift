//
//  LocationCellTableViewCell.swift
//  MyLocation
//
//  Created by Миляев Максим on 18.04.2022.
//

import UIKit

class LocationCell: UITableViewCell {

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func configureForLocation(_ location: Location){
        if location.locationDescription.isEmpty{
            descriptionLabel.text = "(no description)"
        } else {
            descriptionLabel.text = location.locationDescription
        }
        
        if let placemark = location.placemark{
            let address = Helper.current.string(from: placemark)
            addressLabel.text = address
        } else {
            addressLabel.text = String(format: "lat: %.8f, long: %.8f",
                                       location.latitude, location.longitude)
        }
    }

}
