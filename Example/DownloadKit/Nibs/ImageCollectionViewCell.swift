//
//  ImageCollectionViewCell.swift
//  DownloadKitExample
//
//  Created by Moiz on 09/01/2019.
//  Copyright © 2019 Moiz Ullah. All rights reserved.
//

import UIKit
import DownloadKit

// UICollectionViewCell that can download and display images
class ImageCollectionViewCell: UICollectionViewCell {
    // MARK: - IBOutlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    
    // MARK: - Properties
    let downloader = DownloadKit.shared
    var url: URL?
    var downloadRef: RequestReference?
    
    // MARK: - Methods
    override func prepareForReuse() {
        super.prepareForReuse()
        // Reset the cell
        if let ref = downloadRef {
            downloader.cancelRequest(reference: ref)
        }
        imageView.image = nil
        imageView.isHidden = true
        imageView.alpha = 0
        cancelButton.isHidden = false
        cancelButton.alpha = 1
        reloadButton.isHidden = true
        reloadButton.alpha = 0
        loadingIndicator.stopAnimating()
    }

    // Download image from url and display in cell
    func downloadImage(from url: URL) {
        self.url = url
        changeToLoadingUIState()
        
        // MARK: - Example: Download image
        downloadRef = downloader.requestImage(from: url, completion: { [weak self] (image, error) in
            guard let `self` = self else { return }

            guard error == nil else {
                print("Error Downloading:", error!)
                self.changeToFailureUIState()
                return
            }
            guard let image = image else {
                print("No image found")
                self.changeToFailureUIState()
                return
            }

            self.changeToSuccessUIState(image: image)
        })
    }
    
    // Changes UI to failure state
    func changeToFailureUIState() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 1.0, animations: {
                self.loadingIndicator.stopAnimating()
                self.cancelButton.isHidden = true
                self.cancelButton.alpha = 0
                self.reloadButton.isHidden = false
                self.reloadButton.alpha = 1
            })
        }
    }
    
    // Changes UI to success state and loads the given image
    func changeToSuccessUIState(image: UIImage) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 1.0, animations: {
                self.cancelButton.isHidden = true
                self.imageView.image = image
                self.imageView.isHidden = false
                self.imageView.alpha = 1
            })
        }
    }

    // Changes UI to loading state
    func changeToLoadingUIState() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 1.0, animations: {
                self.loadingIndicator.startAnimating()
                self.cancelButton.isHidden = false
                self.cancelButton.alpha = 1
                self.reloadButton.isHidden = true
                self.reloadButton.alpha = 0
            })
        }
    }
    
    // MARK: - IBActions
    // Cancel any existing download and move the UI to the failure state
    @IBAction func cancelDownload(_ sender: UIButton) {
        downloader.cancelRequest(reference: downloadRef!)
        changeToFailureUIState()
    }

    // Attempt to re-download any existing request
    @IBAction func reloadImage(_ sender: UIButton) {
        if let url = url {
            downloadImage(from: url)
        }
    }
    
}
