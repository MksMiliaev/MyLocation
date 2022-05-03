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
    @IBOutlet weak var photoImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // rounded corners of image
        photoImageView.layer.cornerRadius = photoImageView.bounds.width / 2
        photoImageView.clipsToBounds = true
        separatorInset = UIEdgeInsets(top: 0, left: 82, bottom: 0, right: 0)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    func thumbnail(forLocation location: Location) -> UIImage{
        if location.hasPhoto, let image = location.photoImage{
            return image.resized(withBounds: CGSize(width: 52,
                                                    height: 52))
        }
        return UIImage(named: "No Photo") ?? UIImage()
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
        photoImageView.image = thumbnail(forLocation: location)
        photoImageView.contentMode = .scaleAspectFill
    }

}
