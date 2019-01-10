//
//  DownloadKit.swift
//  DownloadKitExample
//
//  Created by Moiz on 07/01/2019.
//  Copyright © 2019 Moiz Ullah. All rights reserved.
//

import Foundation

/// This class handles the downloading process for the `DownloadKit` library. It allows out of the box parsing
/// for `JSON` and image files as `UIImage` objects. It also provides a regular request method that returns
/// raw data from a given `URL`, which can then be parsed and used as necessary.
///
/// It utilizes `URLSession` under the hood for multiple parallel network requests. In-memory caching is handled by
/// utilising the in-built `URLCache` which can be configured to whatever size the user requires. (Note: The cache will
/// only store downloaded files which are less than 5% of the overall cache size, so keep this in mind when selecting
/// a cache size).
///
/// It also has an in-built `TaskManager` for handling multiple requests to the same URL, so that only one network request
/// is actually made for the same resource.
public class DownloadKit {
    // MARK: - Properties
    let _session: URLSession
    let _cache: URLCache
    var _taskManager = TaskManager()
    
    // MARK: - Static properties

    /// Default Cache size is 150 MBs
    public static let DEFAULT_CACHE_SIZE = 150 * 1024 * 1024
    public static var shared = DownloadKit(memorySize: DownloadKit.DEFAULT_CACHE_SIZE)
    
    // MARK: - Initializer/Deinitializer
    public init(memorySize: Int) {
        _cache = URLCache(
            memoryCapacity: memorySize,
            diskCapacity: 0,
            diskPath: nil
        )
        let config = URLSessionConfiguration.default
        config.urlCache = _cache
        _session = URLSession(configuration: config)
    }
    
    deinit {
        _session.invalidateAndCancel()
    }
    
    
    // MARK: - Public Methods

    /// Cancels the request inside the given reference by removing the completion handler
    /// from the list of handlers for that request. If no other handlers exist then the request
    /// is also cancelled.
    ///
    /// - Parameter reference: The RequestReference for the request to be cancelled.
    public func cancelRequest(reference: RequestReference) {
        _taskManager.cancelHandler(for: reference)
    }
    
    
    /// Clears all stored responses from the cache.
    public func clearCache() {
        _cache.removeAllCachedResponses()
    }
    
    
    /// Clears any stored response for the given request URL.
    ///
    /// - Parameter url: The request url for which the cache has to be cleared.
    public func clearCache(for url: URL) {
        let request = URLRequest(url: url)
        _cache.removeCachedResponse(for: request)
    }
    
    
    /// Creates a data download request to the given URL. The raw data from the response is returned via a
    /// completion block. Use this method for getting raw data from a URL. You can then parse
    /// this data and use it as needed.
    ///
    /// - Parameters:
    ///   - url: The url from which data needs to be requested.
    ///   - completion: Completion block that returns the downloaded data or an error.
    /// - Returns: A reference for the request which can be used to cancel the request.
    public func request(from url: URL, completion: @escaping CompletionHandler) -> RequestReference {
        let request = URLRequest(url: url)
        let requestID = UUID().uuidString
        
        download(from: request, requestID: requestID, completion: completion)
        
        return RequestReference(request: request, requestID: requestID)
    }

    
    /// Creates a data download request to the given URL. The raw data from the response is parsed
    /// to a UIImage instance and returned via the completion block. Use this method for downloading
    /// an image from a URL that is known to return an image. If no image is found then an error will
    /// returned.
    ///
    /// - Parameters:
    ///   - url: The url from which data needs to be requested.
    ///   - completion: Completion block which returns the downloaded image or an error.
    /// - Returns: A reference for the request which can be used to cancel the request.
    public func requestImage(from url: URL, completion: @escaping (_ data: UIImage?, _ error: Error?) -> Void) -> RequestReference {
        let request = URLRequest(url: url)
        let requestID = UUID().uuidString
        
        download(from: request, requestID: requestID) { (data, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            guard let data = data, let image = UIImage(data: data) else {
                completion(nil, DownloadKitErrors.DataNotFound)
                return
            }
            completion(image, nil)
        }
        
        return RequestReference(request: request, requestID: requestID)
    }
    
    
    /// Creates a data download request to the given URL. The raw data from the response is parsed
    /// as json, based on the provided model object provided to the function. The provided model
    /// must conform to the `Codable` protocol. Once the json is successfully parsed into the given
    /// model, it is returned via a completion block. If there is any error it will be returned by
    /// the completion block.
    ///
    /// - Parameters:
    ///   - url: The url from which data needs to be requested.
    ///   - model: The model object to which the json needs to be parsed. Must conform to `Codable`.
    ///   - completion: Completion block which returns the downloaded json as the given model or an error.
    /// - Returns: A reference for the request which can be used to cancel the request.
    public func requestJSON<T>(from url: URL, model: T.Type, completion: @escaping (_ data: T?, _ error: Error?)  -> Void) -> RequestReference where T: Codable {
        let request = URLRequest(url: url)
        let requestID = UUID().uuidString
        
        download(from: request, requestID: requestID) { (data, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            guard let data = data else {
                completion(nil, DownloadKitErrors.DataNotFound)
                return
            }
            do {
                let result = try JSONDecoder().decode(T.self, from: data)
                completion(result, nil)
            } catch let error {
                completion(nil, error)
            }
        }
        
        return RequestReference(request: request, requestID: requestID)
    }
    
    // MARK: - Methods

    
    /// This method is what is used under the hood for all download requests created with DownloadKit.
    /// This method creates the actual download request using URLSession and informs the TaskManager
    /// of any requests it makes along with providing the TaskManager the completion handlers for each request.
    ///
    /// (1) It checks with the TaskManager if the given request has already been made. If the request is made then
    ///     it passes the completion handler for the request to the TaskManager and returns.
    ///
    /// (2) If the request does not already exist, then the current URLSession is utilised to create a request to
    ///     the given URLRequest. The URLSession will automatically fetch the response data from the cache, if it
    ///     exists, or download a fresh copy if it doesn't exist.
    ///
    /// (3) Once the session has fetched the response for the request, the TaskManager is informed to call all
    ///      completion handlers with the given response.
    ///
    /// (4) The current request and it's completion handler are registered with the TaskManager.
    ///
    /// (5) The request is finally sent.
    ///
    /// - Parameters:
    ///   - request: The URLRequest from which the data should be requested.
    ///   - requestID: The ID for the request.
    ///   - completion: Completion block that returns the downloaded data or an error.
    func download(from request: URLRequest, requestID: String, completion: @escaping CompletionHandler) {
        // (1)
        if _taskManager.hasTask(for: request) {
            let handlerRef = HandlerReference(id: requestID, completion: completion)
            _taskManager.addHandler(for: request, reference: handlerRef)
            return
        }
        
        // (2)
        let task = _session.dataTask(with: request) { [weak self] (data, _, error) in
            guard let `self` = self else {
                return
            }

            guard error == nil else {
                // (3)
                self._taskManager.callHandlers(for: request, data: nil, error: error)
                return
            }
            
            guard let data = data else {
                // (3)
                self._taskManager.callHandlers(for: request, data: nil, error: DownloadKitErrors.DataNotFound)
                return
            }
            
            // (3)
            self._taskManager.callHandlers(for: request, data: data, error: nil)
        }
        
        // (4)
        let downloadKitTask = DownloadKitTask(sessionTask: task, requestID: requestID, completion: completion)
        _taskManager.addTask(for: request, task: downloadKitTask)
        // (5)
        task.resume()
    }
}
