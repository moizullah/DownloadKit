//
//  JsonModels.swift
//  DownloadKitExample
//
//  Created by Moiz on 09/01/2019.
//  Copyright © 2019 Moiz Ullah. All rights reserved.
//

import Foundation

// MARK: Example: JSON data model

// Partial data model for json @ http://pastebin.com/raw/wgkJgazE
// Only the image urls are retrieved for this example app
class imageModel: Codable {
    let urls: urls
}

class urls: Codable {
    let raw: String
    let full: String
    let regular: String
    let small: String
    let thumb: String
}
