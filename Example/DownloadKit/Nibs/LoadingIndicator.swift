//
//  LoadingIndicator.swift
//  DownloadKitExample
//
//  Created by Moiz on 09/01/2019.
//  Copyright © 2019 Moiz Ullah. All rights reserved.
//

import UIKit

// Custom loading indicator view
class LoadingIndicator: UIView {
    // Adds a background glow and darken animation to show loading
    func startAnimating() {
        let animation = CABasicAnimation(keyPath: "backgroundColor")
        animation.duration = 1.5
        animation.fromValue = UIColor.gray.cgColor
        animation.toValue = UIColor.lightGray.cgColor
        animation.repeatCount = Float.infinity
        animation.autoreverses = true

        self.layer.add(animation, forKey: "loading")
    }
    
    // Remove the animation from the view
    func stopAnimating() {
        self.layer.removeAnimation(forKey: "loading")
        self.backgroundColor = UIColor.lightGray
    }

}
