//
//  AppDelegate.swift
//  DownloadKitExample
//
//  Created by Moiz on 07/01/2019.
//  Copyright © 2019 Moiz Ullah. All rights reserved.
//

import UIKit
import DownloadKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // MARK: Example: Setting a custom cache size for DownloadKit
        // Set cache size for DownloadKit to 150 MBs
        // Note: The cache only stores an individual file if it's size is less than 5% of the
        // overall cache size. So keep this in mind when setting a cache size
        DownloadKit.shared = DownloadKit(memorySize: DownloadKit.DEFAULT_CACHE_SIZE)
        return true
    }
    
}

