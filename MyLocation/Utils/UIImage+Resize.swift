//
//  UIImage+Resize.swift
//  MyLocation
//
//  Created by Миляев Максим on 01.05.2022.
//

import UIKit

extension UIImage{
    func resized(withBounds bounds: CGSize) -> UIImage{
        let horizontelRatio = bounds.width / size.width
        let verticalRatio = bounds.height / size.height
        
        let ratio = min(horizontelRatio,
                        verticalRatio)
        
        let newSize = CGSize(width: size.width * ratio,
                             height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, true, 0)
        draw(in: CGRect(origin: CGPoint.zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}


