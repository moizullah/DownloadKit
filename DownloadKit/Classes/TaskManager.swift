//
//  Downloader.swift
//  DownloadKit
//
//  Created by Moiz on 08/01/2019.
//  Copyright © 2019 Moiz Ullah. All rights reserved.
//

import Foundation

/// The TaskManager class is responsible for maintaining a dictionary of currently active download tasks.
/// It exposes a number of methods that allow the caller to manipulate the dictionary.
///
/// It stores exactly one download task for each URLRequest that has been made. The TaskManager stores the completion
/// handler for any additional requests for the same URL.
///
/// The TaskManager also handles cancellation of download requests, such that a request is only cancelled if it has
/// no completion handlers associated with it, otherwise only the corresponding completion handler is removed.
class TaskManager {
    // MARK: - Properties
    var _requests: [URLRequest: DownloadKitTask]
    
    // MARK: - Initializer
    init() {
        _requests = [:]
    }
    
    
    // MARK: - Methods
    
    /// Add a DownloadKitTask for a given URLRequest to this TaskManager.
    ///
    /// - Parameters:
    ///   - request: The request for which the tast has to be added.
    ///   - task: The task which contains the URLSessionTask and CompletionHandler for the request.
    func addTask(for request: URLRequest, task: DownloadKitTask) {
        _requests[request] = task
    }
    
    
    /// Fetch the DownloadKitTask for the given request if there is any.
    ///
    /// - Parameter request: The request for which the task must be fetched.
    /// - Returns: A DownloadKitTask for the given request if it exists.
    func getTask(for request: URLRequest) -> DownloadKitTask? {
        return _requests[request]
    }
    
    
    /// Removes a given request from this TaskManager.
    ///
    /// - Parameter request: The request whose task needs to be cleared.
    func removeTask(for request: URLRequest) {
        _requests.removeValue(forKey: request)
    }
    
    
    /// Checks if a task exists for a given request.
    ///
    /// - Parameter request: The request whose task needs to be checked.
    /// - Returns: True if the request has an associated task.
    func hasTask(for request: URLRequest) -> Bool {
        return _requests[request] != nil
    }
    
    
    /// Adds a new completion handler for a given request if that request exists.
    ///
    /// - Parameters:
    ///   - request: The request for which the handler must be added
    ///   - reference: The handler reference to be stored for the request.
    func addHandler(for request: URLRequest, reference: HandlerReference) {
        if let task = _requests[request] {
            task.handlers.append(reference)
        }
    }
    
    
    /// Cancels the request inside the given reference by removing the completion handler
    /// from the list of handlers for that request. If no other handlers exist then the request
    /// itself is also cancelled. The handler that is removed is also called with a cancellation
    /// error.
    ///
    /// - Parameter reference: he RequestReference for the request to be cancelled.
    func cancelHandler(for reference: RequestReference) {
        guard let task = _requests[reference.request] else { return }
        
        if let index = task.handlers.firstIndex(where: { $0.id == reference.requestID }) {
            let closureReference = task.handlers.remove(at: index)
            closureReference.completion(nil, DownloadKitErrors.CancelledByUser)
        }
        
        if task.handlers.isEmpty {
            task.task.cancel()
            _requests.removeValue(forKey: reference.request)
        }
    }
    
    
    /// Calls all handlers for a given request, passing them any data or error
    /// that was provided. Once all handlers have been called, the request is removed
    /// from the list of active requests.
    ///
    /// - Parameters:
    ///   - request: The request whose handlers need to be called.
    ///   - data: The data object to be passed to the handlers.
    ///   - error: The error object to be passed to the handlers.
    func callHandlers(for request: URLRequest, data: Data?, error: Error?) {
        if let handlers = _requests[request]?.handlers {
            for handler in handlers {
                handler.completion(data, error)
            }
        }
        _requests.removeValue(forKey: request)
    }
}
