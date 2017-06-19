//
//  Helpers.swift
//  HappyDays
//
//  Created by GERH on 6/17/17.
//  Copyright © 2017 GERH. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(r: CGFloat, g:CGFloat, b: CGFloat) {
        self.init(red: r/255, green: g/255, blue: b/255, alpha: 1)
    }    
}
extension UIImage {
    func resize(to width: CGFloat) -> UIImage? {
        let scale = width / self.size.width
        let height = self.size.height * scale
        // create a new image context to draw into
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
        // draw the original image into the context
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        // pull out the resized version
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        // end the context so UIKit can clean up
        UIGraphicsEndImageContext()
        return newImage
    }
    func resize(scale: CGFloat) -> UIImage? {
        let width = self.size.width * scale
        let height = self.size.height * scale
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
