//
//  DownloadKitTests.swift
//  DownloadKitTests
//
//  Created by Moiz on 08/01/2019.
//  Copyright © 2019 Moiz Ullah. All rights reserved.
//

import XCTest
@testable import DownloadKit

class DownloadKitTests: XCTestCase {
    
    let timeout = TimeInterval(60)

    override func setUp() {
        DownloadKit.shared._cache.removeAllCachedResponses()
    }

    override func tearDown() {
        DownloadKit.shared._cache.removeAllCachedResponses()
    }
    
    func testSharedInitialization() {
        // Given / When
        let downloader = DownloadKit.shared
        
        // Then
        XCTAssertNotNil(downloader, "downloader should not be nil")
        XCTAssertNotNil(downloader._cache, "cache should not be nil")
        XCTAssertNotNil(downloader._session, "session should not be nil")
        XCTAssertNotNil(downloader._taskManager, "task manager should not be nil")
        XCTAssertTrue(downloader._cache.memoryCapacity == DownloadKit.DEFAULT_CACHE_SIZE, "cache memory should be same as default cache size")
    }
    
    func testRegularInitialization() {
        // Given / When
        let size = 10 * 1024 * 1024
        let downloader = DownloadKit(memorySize: size)
        
        // Then
        XCTAssertNotNil(downloader, "downloader shouldn't be nil")
        XCTAssertNotNil(downloader._cache, "cache should not be nil")
        XCTAssertNotNil(downloader._session, "session should not be nil")
        XCTAssertNotNil(downloader._taskManager, "task manager should not be nil")
        XCTAssertTrue(downloader._cache.memoryCapacity == size, "cache memory should be same as what was passed in the initializer")
    }
    
    func testDeInitialization() {
        // Given
        let size = 10 * 1024 * 1024
        var downloader: DownloadKit? = DownloadKit(memorySize: size)
        
        // When
        downloader = nil
        
        // Then
        XCTAssertNil(downloader, "downloader should be nil")
    }
    
    func testDeInitializationWithActiveDownload() {
        // Given
        let url = URL(string: "https://httpbin.org/image/jpeg")
        var downloader: DownloadKit? = DownloadKit(memorySize: DownloadKit.DEFAULT_CACHE_SIZE)

        // When
        _ = downloader!.request(from: url!) { (_, _) in }
        downloader = nil

        // Then
        XCTAssertNil(downloader, "downloader should be nil")
    }
    
    func testDownload() {
        // Given
        let url = URL(string: "https://httpbin.org/image/jpeg")
        let request = URLRequest(url: url!)
        let id = UUID().uuidString
        let downloader = DownloadKit.shared
        let expectation = self.expectation(description: "data download should be successful")
        var result: Data?
        
        // When
        downloader.download(from: request, requestID: id) { (data, _) in
            result = data
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        XCTAssertNotNil(result, "result should not be nil")
    }
    
    func testDownloadIsCached() {
        // Given
        let url = URL(string: "https://httpbin.org/image/jpeg")
        let request = URLRequest(url: url!)
        let id = UUID().uuidString
        let downloader = DownloadKit.shared
        let expectation = self.expectation(description: "data download should be successful")
        var result: Data?
        
        // When
        downloader.download(from: request, requestID: id) { (data, _) in
            result = data
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        XCTAssertNotNil(result, "result should not be nil")
        XCTAssertNotNil(downloader._cache.cachedResponse(for: request), "result should be cached")
    }
    
    func testDownloadIsNotCachedAfterClearingCache() {
        // Given
        let url = URL(string: "https://httpbin.org/image/jpeg")
        let request = URLRequest(url: url!)
        let id = UUID().uuidString
        let downloader = DownloadKit.shared
        let expectation = self.expectation(description: "data download should be successful")
        var result: Data?
        
        // When
        downloader.download(from: request, requestID: id) { (data, _) in
            result = data
            downloader._cache.removeAllCachedResponses()
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        XCTAssertNotNil(result, "result should not be nil")
        XCTAssertNil(downloader._cache.cachedResponse(for: request), "result should not be cached")
    }
    
    func testMultipleSameDownloads() {
        // Given
        let downloader = DownloadKit.shared

        let url = URL(string: "https://httpbin.org/image/jpeg")
        let request1 = URLRequest(url: url!)
        let request2 = URLRequest(url: url!)
        let id1 = UUID().uuidString
        let id2 = UUID().uuidString
        var result1: Data?
        var result2: Data?
        let expectation1 = expectation(description: "data download 1 should be successful")
        let expectation2 = expectation(description: "data download 2 should be successful")
        
        // When
        downloader.download(from: request1, requestID: id1) { (data, _) in
            result1 = data
            expectation1.fulfill()
        }
        
        downloader.download(from: request2, requestID: id2) { (data, _) in
            result2 = data
            expectation2.fulfill()
        }

        // Then
        let handler1 = downloader._taskManager._requests[request1]?.handlers.first(where: { $0.id == id1 })
        let handler2 = downloader._taskManager._requests[request1]?.handlers.first(where: { $0.id == id2 })
        XCTAssertNotNil(handler1, "download 1 should have handler registered with task manager")
        XCTAssertNotNil(handler2, "download 2 should have handler registered with task manager")
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        XCTAssertNotNil(result1, "result 1 should not be nil")
        XCTAssertNotNil(result2, "result 2 should not be nil")
    }
    
    func testMultipleSameDownloadsWithSingleCancel() {
        // Given
        let downloader = DownloadKit.shared
        
        let url = URL(string: "https://httpbin.org/image/jpeg")
        let request1 = URLRequest(url: url!)
        let request2 = URLRequest(url: url!)
        let id1 = UUID().uuidString
        let id2 = UUID().uuidString
        var result1: Data?
        var error2: Error?
        let expectation1 = expectation(description: "data download 1 should be successful")
        let expectation2 = expectation(description: "data download 2 should return error")
        
        // When
        downloader.download(from: request1, requestID: id1) { (data, _) in
            result1 = data
            expectation1.fulfill()
        }
        
        downloader.download(from: request2, requestID: id2) { (_, error) in
            error2 = error
            expectation2.fulfill()
        }

        downloader.cancelRequest(reference: RequestReference(request: request2, requestID: id2))
        
        // Then
        let handler1 = downloader._taskManager._requests[request1]?.handlers.first(where: { $0.id == id1 })
        let handler2 = downloader._taskManager._requests[request1]?.handlers.first(where: { $0.id == id2 })
        XCTAssertNotNil(handler1, "download 1 should have handler registered with task manager")
        XCTAssertNil(handler2, "download 2 should not have handler registered with task manager")
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        XCTAssertNotNil(result1, "result 1 should not be nil")
        XCTAssertNotNil(error2, "error 2 should not be nil")
    }
    
    func testDownloadCancel() {
        // Given
        let url = URL(string: "https://httpbin.org/image/jpeg")
        let request = URLRequest(url: url!)
        let id = UUID().uuidString
        let downloader = DownloadKit.shared
        let expectation = self.expectation(description: "data download should be successful")
        var error: Error?
        
        // When
        downloader.download(from: request, requestID: id) { (_, err) in
            error = err
            expectation.fulfill()
        }
        
        downloader.cancelRequest(reference: RequestReference(request: request, requestID: id))
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        XCTAssertNotNil(error, "error should not be nil")
    }
    
    func testMultipleDistinctDownloads() {
        // Given
        let downloader = DownloadKit.shared
        
        let url1 = URL(string: "https://images.unsplash.com/photo-1464550883968-cec281c19761?ixlib=rb-0.3.5&q=80&fm=jpg&crop=entropy&w=200&fit=max&s=9fba74be19d78b1aa2495c0200b9fbce")
        let url2 = URL(string: "https://images.unsplash.com/photo-1464550838636-1a3496df938b?ixlib=rb-0.3.5&q=80&fm=jpg&crop=entropy&w=200&fit=max&s=9947985b2095f1c8fbbbe09a93b9b1d9")
        let request1 = URLRequest(url: url1!)
        let request2 = URLRequest(url: url2!)
        let id1 = UUID().uuidString
        let id2 = UUID().uuidString
        var result1: Data?
        var result2: Data?
        let expectation1 = expectation(description: "data download 1 should be successful")
        let expectation2 = expectation(description: "data download 2 should be successful")
        
        // When
        downloader.download(from: request1, requestID: id1) { (data, _) in
            result1 = data
            expectation1.fulfill()
        }
        
        downloader.download(from: request2, requestID: id2) { (data, _) in
            result2 = data
            expectation2.fulfill()
        }
        
        // Then
        let handler1 = downloader._taskManager._requests[request1]?.handlers.first(where: { $0.id == id1 })
        let handler2 = downloader._taskManager._requests[request2]?.handlers.first(where: { $0.id == id2 })
        XCTAssertNotNil(handler1, "download 1 should have handler registered with task manager")
        XCTAssertNotNil(handler2, "download 2 should have handler registered with task manager")
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        XCTAssertNotNil(result1, "result 1 should not be nil")
        XCTAssertNotNil(result2, "result 2 should not be nil")
    }
    
    func testDataRequest() {
        // Given
        let url = URL(string: "https://httpbin.org/image/jpeg")
        let downloader = DownloadKit.shared
        let expectation = self.expectation(description: "data download should be successful")
        var result: Data?

        // When
        let ref = downloader.request(from: url!) { (data, _) in
            result = data
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        XCTAssertNotNil(result, "result should not be nil")
        XCTAssertNotNil(ref.request.url, "request reference's url should not be nil")
        XCTAssertEqual(ref.request.url, url, "request url should be equal to reference's request url")
    }
    
    func testFalseDataRequest() {
        // Given
        let url = URL(string: "https://httpbin.or/")
        let downloader = DownloadKit.shared
        let expectation = self.expectation(description: "data download should return an error")
        var error: Error?
        
        // When
        let ref = downloader.request(from: url!) { (_, err) in
            error = err
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        XCTAssertNotNil(error, "error should not be nil")
        XCTAssertNotNil(ref.request.url, "request reference's url should not be nil")
        XCTAssertEqual(ref.request.url, url, "request url should be equal to reference's request url")
    }
    
    func testImageRequest() {
        // Given
        let url = URL(string: "https://httpbin.org/image/jpeg")
        let downloader = DownloadKit.shared
        let expectation = self.expectation(description: "image download should be successful")
        var result: UIImage?
        
        // When
        let ref = downloader.requestImage(from: url!) { (data, _) in
            result = data
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        XCTAssertNotNil(result, "result should not be nil")
        XCTAssertNotNil(ref.request.url, "request reference's url should not be nil")
        XCTAssertEqual(ref.request.url, url, "request url should be equal to reference's request url")
    }
    
    func testFalseImageRequest() {
        // Given
        let url = URL(string: "https://httpbin.org/")
        let downloader = DownloadKit.shared
        let expectation = self.expectation(description: "image download should return an error")
        var error: Error?
        
        // When
        let ref = downloader.requestImage(from: url!) { (_, err) in
            error = err
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        XCTAssertNotNil(error, "error should not be nil")
        XCTAssertNotNil(ref.request.url, "request reference's url should not be nil")
        XCTAssertEqual(ref.request.url, url, "request url should be equal to reference's request url")
    }
    
    func testJSONRequest() {
        // Given
        struct jsonObj: Codable {
            let id: String
        }
        let url = URL(string: "https://pastebin.com/raw/wgkJgazE")
        let downloader = DownloadKit.shared
        let expectation = self.expectation(description: "json download should be successful")
        var result: [jsonObj]?
        
        // When
        let ref = downloader.requestJSON(from: url!, model: [jsonObj].self) { (data, _) in
            result = data
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        XCTAssertNotNil(result, "result should not be nil")
        XCTAssertNotNil(ref.request.url, "request reference's url should not be nil")
        XCTAssertEqual(ref.request.url, url, "request url should be equal to reference's request url")
    }
    
    func testFalseJSONRequest() {
        // Given
        struct jsonObj: Codable {
            let id: String
        }
        let url = URL(string: "http://pastebin.com/")
        let downloader = DownloadKit.shared
        let expectation = self.expectation(description: "json download should be successful")
        var error: Error?
        
        // When
        let ref = downloader.requestJSON(from: url!, model: [jsonObj].self) { (_, err) in
            error = err
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        XCTAssertNotNil(error, "error should not be nil")
        XCTAssertNotNil(ref.request.url, "request reference's url should not be nil")
        XCTAssertEqual(ref.request.url, url, "request url should be equal to reference's request url")
    }
    
    func testJSONRequestWithFalseModel() {
        // Given
        struct jsonObj: Codable {
            let asdasd: String
        }
        let url = URL(string: "http://pastebin.com/raw/wgkJgazE")
        let downloader = DownloadKit.shared
        let expectation = self.expectation(description: "json download should be successful")
        var error: Error?
        
        // When
        let ref = downloader.requestJSON(from: url!, model: [jsonObj].self) { (_, err) in
            error = err
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        XCTAssertNotNil(error, "error should not be nil")
        XCTAssertNotNil(ref.request.url, "request reference's url should not be nil")
        XCTAssertEqual(ref.request.url, url, "request url should be equal to reference's request url")
    }
}
