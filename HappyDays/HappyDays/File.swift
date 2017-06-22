//
//  File.swift
//  HappyDays
//
//  Created by Gonzalo Reyes Huertas on 6/21/17.
//  Copyright © 2017 GERH. All rights reserved.
//

import Foundation

enum File: String {
    case jpg, thumb, m4a, txt
    var fileExtension: String {
        switch self {
        case .jpg: return ".jpg"
        case .thumb: return ".thumb"
        case .m4a: return ".m4a"
        case .txt: return ".txt"
        }
    }
}
