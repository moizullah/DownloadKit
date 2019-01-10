//
//  TaskManagerTests.swift
//  DownloadKitTests
//
//  Created by Moiz on 08/01/2019.
//  Copyright © 2019 Moiz Ullah. All rights reserved.
//

import XCTest
@testable import DownloadKit

/// Mock class for URLSessionTask
class MockURLSessionTask: URLSessionTask {
    var cancelled = false
    override func cancel() {
        cancelled = true
    }
}

class TaskManagerTests: XCTestCase {
    
    let timeout = TimeInterval(10)

    override func setUp() {
        DownloadKit.shared = DownloadKit(memorySize: DownloadKit.DEFAULT_CACHE_SIZE)
    }

    func testInitialization() {
        // Given / When
        let manager = TaskManager()
        
        // Then
        XCTAssertNotNil(manager, "task manager should not be nil")
        XCTAssertNotNil(manager._requests, "task manager requests list should not be nil")
    }
    
    func testDeInitialization() {
        // Given
        var manager: TaskManager? = TaskManager()
        
        // When
        manager = nil
        
        // Then
        XCTAssertNil(manager, "task manager should be nil")
    }

    func testAddTask() {
        // Given
        let manager = DownloadKit.shared._taskManager
        let request = URLRequest(url: URL(string: "https://httpbin.org/image/jpeg")!)
        let task = URLSessionTask()
        let id = UUID().uuidString
        let completion: CompletionHandler = { (_, _) in }
        
        // When
        manager.addTask(for: request, task: DownloadKitTask(sessionTask: task, requestID: id, completion: completion))
        
        // Then
        XCTAssertNotNil(manager._requests[request], "task for given request should exist in request list of task manager")
    }
    
    func testGetTaskWhenTaskExists() {
        // Given
        let manager = DownloadKit.shared._taskManager
        let request = URLRequest(url: URL(string: "https://httpbin.org/image/jpeg")!)
        let task = URLSessionTask()
        let id = UUID().uuidString
        let completion: CompletionHandler = { (_, _) in }
        
        // When
        manager.addTask(for: request, task: DownloadKitTask(sessionTask: task, requestID: id, completion: completion))
        
        // Then
        XCTAssertNotNil(manager._requests[request], "task for given request should exist in request list of task manager")
        XCTAssertNotNil(manager.getTask(for: request), "getTask should not return nil")
    }
    
    func testGetTaskWhenTaskDoesNotExist() {
        // Given / When
        let manager = DownloadKit.shared._taskManager
        let request = URLRequest(url: URL(string: "https://httpbin.org/image/jpeg")!)
        
        // Then
        XCTAssertNil(manager.getTask(for: request), "getTask should return nil")
    }
    
    func testRemoveTask() {
        // Given
        let manager = DownloadKit.shared._taskManager
        let request = URLRequest(url: URL(string: "https://httpbin.org/image/jpeg")!)
        let task = URLSessionTask()
        let id = UUID().uuidString
        let completion: CompletionHandler = { (_, _) in }
        
        // When
        manager.addTask(for: request, task: DownloadKitTask(sessionTask: task, requestID: id, completion: completion))
        
        // Then
        XCTAssertNotNil(manager._requests[request], "task for given request should exist in request list of task manager")
        XCTAssertNotNil(manager.getTask(for: request), "getTask should not return nil")
        
        // When
        manager.removeTask(for: request)
        
        // Then
        XCTAssertNil(manager._requests[request], "task for given request should not exist in request list of task manager")
        XCTAssertNil(manager.getTask(for: request), "getTask should return nil")
    }
    
    func testHasTask() {
        // Given
        let manager = DownloadKit.shared._taskManager
        let request = URLRequest(url: URL(string: "https://httpbin.org/image/jpeg")!)
        let task = URLSessionTask()
        let id = UUID().uuidString
        let completion: CompletionHandler = { (_, _) in }
        
        // When
        manager.addTask(for: request, task: DownloadKitTask(sessionTask: task, requestID: id, completion: completion))
        
        // Then
        XCTAssertTrue(manager.hasTask(for: request), "manager should have task")
    }
    
    func testAddHandler() {
        // Given
        let manager = DownloadKit.shared._taskManager
        let request = URLRequest(url: URL(string: "https://httpbin.org/image/jpeg")!)
        let task = URLSessionTask()
        let id = UUID().uuidString
        let id2 = UUID().uuidString
        let completion: CompletionHandler = { (_, _) in }
        
        // When
        manager.addTask(for: request, task: DownloadKitTask(sessionTask: task, requestID: id, completion: completion))
        manager.addHandler(for: request, reference: HandlerReference(id: id2, completion: completion))
        
        // Then
        let handler1 = manager._requests[request]?.handlers.first(where: { $0.id == id })
        let handler2 = manager._requests[request]?.handlers.first(where: { $0.id == id2 })
        XCTAssertNotNil(handler1, "handler 1 should not be nil")
        XCTAssertNotNil(handler2, "handler 2 should not be nil")
    }
    
    func testCancelHandlerForSingleHandler() {
        // Given
        let manager = DownloadKit.shared._taskManager
        let request = URLRequest(url: URL(string: "https://httpbin.org/image/jpeg")!)
        let task = MockURLSessionTask()
        let id = UUID().uuidString
        var error: Error?
        let expectation = self.expectation(description: "handler should receive error upon cancellation")
        let completion: CompletionHandler = { (_, err) in
            error = err
            expectation.fulfill()
        }
        
        // When
        manager.addTask(for: request, task: DownloadKitTask(sessionTask: task, requestID: id, completion: completion))
        manager.cancelHandler(for: RequestReference(request: request, requestID: id))

        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        let handler = manager._requests[request]?.handlers.first(where: { $0.id == id })
        XCTAssertNil(handler, "handler should be nil")
        XCTAssertNil(manager._requests[request], "request should not exist in manager's list of requests")
        XCTAssertNotNil(error, "error should not be nil")
        XCTAssertTrue(task.cancelled, "task should be cancelled")
    }
    
    func testCancelHandlerForMultipleHandlersForSameRequest() {
        // Given
        let manager = DownloadKit.shared._taskManager
        let request = URLRequest(url: URL(string: "https://httpbin.org/image/jpeg")!)
        let task = MockURLSessionTask()
        let id1 = UUID().uuidString
        let id2 = UUID().uuidString
        var error: Error?
        let expectation = self.expectation(description: "handler should receive error upon cancellation")
        let completion1: CompletionHandler = { (_, _) in }
        let completion2: CompletionHandler = { (_, err) in
            error = err
            expectation.fulfill()
        }
        
        // When
        manager.addTask(for: request, task: DownloadKitTask(sessionTask: task, requestID: id1, completion: completion1))
        manager.addHandler(for: request, reference: HandlerReference(id: id2, completion: completion2))
        manager.cancelHandler(for: RequestReference(request: request, requestID: id2))
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        let handler1 = manager._requests[request]?.handlers.first(where: { $0.id == id1 })
        let handler2 = manager._requests[request]?.handlers.first(where: { $0.id == id2 })
        
        XCTAssertNotNil(handler1, "handler 1 should not be nil")
        XCTAssertNotNil(manager._requests[request], "request should exist in manager's list of requests")
        XCTAssertNil(handler2, "handler 2 should be nil")
        XCTAssertNotNil(error, "error should not be nil")
        XCTAssertFalse(task.cancelled, "task should not be cancelled")
    }
    
    func testCallAllHandlers() {
        // Given
        let manager = DownloadKit.shared._taskManager
        let request = URLRequest(url: URL(string: "https://httpbin.org/image/jpeg")!)
        let task = MockURLSessionTask()
        let id1 = UUID().uuidString
        let id2 = UUID().uuidString
        var data1: Data?
        var data2: Data?
        var error1: Error?
        var error2: Error?
        let expectation1 = self.expectation(description: "handler 1 should receive data and error")
        let expectation2 = self.expectation(description: "handler 2 should receive data and error")
        let completion1: CompletionHandler = { (data, err) in
            data1 = data
            error1 = err
            expectation1.fulfill()
        }
        let completion2: CompletionHandler = { (data, err) in
            data2 = data
            error2 = err
            expectation2.fulfill()
        }
        
        // When
        manager.addTask(for: request, task: DownloadKitTask(sessionTask: task, requestID: id1, completion: completion1))
        manager.addHandler(for: request, reference: HandlerReference(id: id2, completion: completion2))
        manager.callHandlers(for: request, data: Data(), error: DownloadKitErrors.CancelledByUser)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        XCTAssertNotNil(data1, "data 1 should not be nil")
        XCTAssertNotNil(data2, "data 2 should not be nil")
        XCTAssertNotNil(error1, "error 1 should not be nil")
        XCTAssertNotNil(error2, "error 2 should not be nil")
        XCTAssertNil(manager._requests[request], "request should not exist in manager's list of requests")
        XCTAssertFalse(task.cancelled, "task should not be cancelled")
    }
}
