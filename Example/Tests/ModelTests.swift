//
//  ModelTests.swift
//  DownloadKitTests
//
//  Created by Moiz on 09/01/2019.
//  Copyright © 2019 Moiz Ullah. All rights reserved.
//

import XCTest
@testable import DownloadKit

class ModelTests: XCTestCase {

    func testDownloadKitTaskInitialization() {
        // Given / When
        let sessionTask = MockURLSessionTask()
        let id = UUID().uuidString
        let completion: CompletionHandler = { (_, _) in }
        let task = DownloadKitTask(sessionTask: sessionTask, requestID: id, completion: completion)
        
        // Then
        XCTAssertNotNil(task, "task should not be nil")
        XCTAssertNotNil(task.handlers.first, "handler should not be nil")
        XCTAssertEqual(task.handlers.first?.id, id, "handler reference id should be equal to task id")
    }

    func testDownloadKitTaskDeInitialization() {
        // Given
        let sessionTask = MockURLSessionTask()
        let id = UUID().uuidString
        let completion: CompletionHandler = { (_, _) in }
        var task: DownloadKitTask? = DownloadKitTask(sessionTask: sessionTask, requestID: id, completion: completion)
        
        // When
        task = nil
        
        // Then
        XCTAssertNil(task, "task should be nil")
    }
    
    func testRequestReferenceInitialization() {
        // Given / When
        let request = URLRequest(url: URL(string: "https://httpbin.org/image/jpeg")!)
        let id = UUID().uuidString
        let reference = RequestReference(request: request, requestID: id)
        
        // Then
        XCTAssertNotNil(reference, "request reference should not be nil")
    }
}
