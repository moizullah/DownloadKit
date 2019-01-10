//
//  LoadingFooterCollectionReusableView.swift
//  DownloadKitExample
//
//  Created by Moiz on 09/01/2019.
//  Copyright © 2019 Moiz Ullah. All rights reserved.
//

import UIKit

// Custom loading footer for UICollectionView that displays a loading spinner
class LoadingFooterCollectionReusableView: UICollectionReusableView {
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Default transform state
        spinner.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
    }
    
    // Start animating the loading spinner and animate the identity transform
    func startAnimating() {
        self.spinner.startAnimating()
        UIView.animate(withDuration: 0.5) {
            self.spinner.transform = CGAffineTransform.identity
        }
    }
    
    // Stop animating the loading spinner and animate the transform property to default
    func stopAnimating() {
        self.spinner.stopAnimating()
        UIView.animate(withDuration: 0.5) {
            self.spinner.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
        }
    }
}
