//
//  Memory.swift
//  HappyDays
//
//  Created by Gonzalo Reyes Huertas on 6/22/17.
//  Copyright © 2017 GERH. All rights reserved.
//

import Foundation

class Memory {
    let directory: URL
    let name: String
    init(directory: URL, name: String) {
        self.directory = directory
        self.name = name
    }
}
