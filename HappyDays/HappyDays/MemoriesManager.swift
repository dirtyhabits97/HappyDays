//
//  MemoriesManager.swift
//  HappyDays
//
//  Created by Gonzalo Reyes Huertas on 6/21/17.
//  Copyright © 2017 GERH. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech

class MemoriesManager {
    
    // MARK: - GetURL Methods
    
    func getMemoryURL(for memory: URL, type: File) -> URL {
        return memory.appendingPathExtension(type.rawValue)
    }
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func saveNewMemory(image: UIImage) {
        // create a unique name for this memory based on time so it's ez to sort
        let memoryName = "memory-\(Date().timeIntervalSince1970)"
        let imageName = memoryName + File.jpg.fileExtension
        let thumbnailName = memoryName + File.thumb.fileExtension
        do {
            // create url with the names created
            let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
            // convert the UIImage into a JPEG data object
            if let imageJPEGData = UIImageJPEGRepresentation(image, 80) {
                // write that data to the url created
                try imageJPEGData.write(to: imagePath, options: [.atomic])
            }
            
            if let thumbnail = image.resize(to: 200) {
                let thumbnailPath = getDocumentsDirectory().appendingPathComponent(thumbnailName)
                if let thumbnailJPEGData = UIImageJPEGRepresentation(thumbnail, 80) {
                    try thumbnailJPEGData.write(to: thumbnailPath, options: [.atomic])
                }
            }
        } catch {
            print("Failed to save new memory")
        }
    }
}
