//
//  ImageCollectionViewController.swift
//  DownloadKitExample
//
//  Created by Moiz on 09/01/2019.
//  Copyright © 2019 Moiz Ullah. All rights reserved.
//

import UIKit
import DownloadKit

// MARK: Reuse identifiers
private let cellReuseIdentifier = "imageCell"
private let footerReuseIdentifier = "loadingFooter"

class ImageCollectionViewController: UICollectionViewController {
    // MARK: - Public properties
    let jsonUrl = URL(string: "https://pastebin.com/raw/wgkJgazE")
    var urls = [URL]()
    var downloader: DownloadKit!
    var isLoading = false
    
    // MARK: - Private properties
    private let refreshControl = UIRefreshControl()

    // MARK: - UIViewController methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "DownloadKit"
        collectionView.refreshControl = refreshControl
        
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        
        downloader = DownloadKit.shared
        downloadImageUrls()
    }
    
    // MARK: - Custom methods
    
    // Download image urls in JSON form, injected into a given model object
    func downloadImageUrls() {
        guard let url = jsonUrl else { return }
        isLoading = true
        
        // MARK: Example: Download JSON
        // Downloading JSON requires a model object conforming to the `Codable` protocol
        // and having the same keys as the JSON being downloaded
        _ = downloader.requestJSON(from: url, model: [imageModel].self) { (images, error) in
            self.isLoading = false
            guard error == nil else {
                print("Error Downloading:", error!)
                return
            }
            guard let images = images else {
                print("Error no data found")
                return
            }

            // Parse downloaded json to URL objects
            var newUrls = [URL]()
            images.forEach({ (image) in
                if let url = URL(string: image.urls.regular) {
                    newUrls.append(url)
                }
            })

            // UI updates
            DispatchQueue.main.async {
                if self.refreshControl.isRefreshing {
                    self.refreshControl.endRefreshing()
                    self.urls.removeAll()
                }
                self.urls.append(contentsOf: newUrls)
                self.collectionView.reloadData()
            }
        }
    }
    
    // UIRefreshControl action
    @objc func refreshData(_ sender: UIRefreshControl) {
        downloader.clearCache()
        downloadImageUrls()
    }
}

// MARK: - UICollectionViewDataSource
extension ImageCollectionViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return urls.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath)
    
        guard let imageCell = cell as? ImageCollectionViewCell else {
            print("Unable to downcast cell")
            return cell
        }
        // Inform cell to download image from given URL
        imageCell.downloadImage(from: self.urls[indexPath.row])
        return imageCell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: footerReuseIdentifier, for: indexPath)
        return footer
    }
}

// MARK: - UICollectionViewDelegate
extension ImageCollectionViewController {

    override func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        // Start animating LoadingFooter when it is shown
        if elementKind == UICollectionView.elementKindSectionFooter {
            let footer = view as! LoadingFooterCollectionReusableView
            footer.startAnimating()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        // Stop animating LoadingFooter when it is not shown
        if elementKind == UICollectionView.elementKindSectionFooter {
            let footer = view as! LoadingFooterCollectionReusableView
            footer.stopAnimating()
        }
    }
}

// MARK: - UIScrollViewDelegate
extension ImageCollectionViewController {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Fetch more data when user reaches end of current list
        let height = scrollView.frame.size.height
        let contentOffsetY = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentOffsetY
        if distanceFromBottom < height - 5 {
            if !isLoading {
                downloadImageUrls()
            }
        }
    }
}
