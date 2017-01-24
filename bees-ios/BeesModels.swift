//
//  BeesModels.swift
//  bees-ios
//
//  Created by Cameron Deardorff on 1/23/17.
//  Copyright © 2017 Cameron Deardorff. All rights reserved.
//

import Foundation

struct BeesRecord {
    var loudness: Double
    var range: BeesRange
}

struct BeesRange {
    var from: String
    var to: String
}

struct BeesError {
    var message: String
    var code: String
}
