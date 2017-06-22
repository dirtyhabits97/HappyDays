//
//  Protocols.swift
//  HappyDays
//
//  Created by Gonzalo Reyes Huertas on 6/21/17.
//  Copyright © 2017 GERH. All rights reserved.
//

import UIKit
import AVFoundation

protocol MemoryCellDelegate: class {
    func handleLongPress(sender: UILongPressGestureRecognizer)
}

protocol MemoriesManagerDelegate: class, AVAudioRecorderDelegate {
    
}
