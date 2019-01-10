# DownloadKit

<!--[![CI Status](https://img.shields.io/travis/moizullah/DownloadKit.svg?style=flat)](https://travis-ci.org/moizullah/DownloadKit)-->
[![Version](https://img.shields.io/cocoapods/v/DownloadKit.svg?style=flat)](https://cocoapods.org/pods/DownloadKit)
[![License](https://img.shields.io/cocoapods/l/DownloadKit.svg?style=flat)](https://cocoapods.org/pods/DownloadKit)
[![Platform](https://img.shields.io/cocoapods/p/DownloadKit.svg?style=flat)](https://cocoapods.org/pods/DownloadKit)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

OR run `pod try DownloadKit`

## Requirements

- iOS 10.0+
- Xcode 10.0+
- Swift 4.2+

## Installation

DownloadKit is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'DownloadKit'
```

## Usage

### Shared Instance

A shared instance of DownloadKit can be utilised out of the box for managing download requests. 

```swift
import DownloadKit

let downloader = DownloadKit.shared
```
The shared instance comes with a default in-memory cache size of 150 MBs.

### Download Image

Images can be downloaded from a given `URL`, the library will parse the downloaded data as a `UIImage` object and return it via the completion block. If the parsing fails then a nil will be returned.

```swift
let url = URL(string: "https://httpbin.org/image/jpeg")

DownloadKit.shared.requestImage(from: url, completion: { (image, error) in
        guard error == nil else {
            print("Error Downloading:", error!)
            return
        }
        if let image = image {
            print("Downloaded Image:", image)
        }
})
```

### Download JSON

JSON objects can be downloaded from a given `URL`, the library parses the returned data into the provided data model. The provided data model must conform to the `Codable` protocol.
For example the following JSON object has to be downloaded:

```json
{
    "userId": 1,
    "id": 1,
    "title": "JSON Example",
    "body": "This is how you download a JSON file."
}
```
Create a data model for the above JSON object, which conforms to the `Codable` protocol:

```swift
struct Post: Codable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}
```
Finally, call `requestJSON(from:model:completion)`, passing it your JSON data model. 

```swift
let url = URL(string: "https://jsonplaceholder.typicode.com/posts")

DownloadKit.shared.requestImage(from: url, model: [posts].self, completion: { (posts, error) in
        guard error == nil else {
            print("Error Downloading:", error!)
            return
        }
        if let posts = posts {
            print("Downloaded JSON:", posts)
        }
})
```

### Download Raw Data

The library also allows downloading any other files from a given `URL`. The downloaded data is returned as a `Data` object, you may parse this data or store it as per your needs.

```swift
let url = URL(string: "https://httpbin.org/image/jpeg")

DownloadKit.shared.request(from: url, completion: { (data, error) in
        guard error == nil else {
            print("Error Downloading:", error!)
            return
        }
        if let data = data {
            print("Downloaded Data:", data)
        }
})
```

### Cancel Request

Any download requests can be cancelled by calling `cancelRequest(reference:)`. Whenever a request is made a `RequestReference` object is returned, which can be utilised to cancel the request.

```swift
let url = URL(string: "https://httpbin.org/image/jpeg")

let ref = DownloadKit.shared.request(from: url, completion: { (data, error) in
        guard error == nil else {
            print("Error Downloading:", error!)
            return
        }
        if let data = data {
            print("Downloaded Data:", data)
        }
})

DownloadKit.shared.cancelRequest(reference: ref)
```
Upon cancellation of a request the completion block for the request will be passed a `DownloadKitError`, indicating that the request was cancelled by the user.

### Caching

The library comes with built in in-memory caching. This is achieved by using `URLCache` under the hood, which is configured to cache downloaded data into the memory. Hence, multiple requests to the same end-point will result in cached results being returned for subsequent requests. This is done to ensure efficiency.

#### Configuring Cache Size

The cache size can be configured as needed. However, ensure that you are making an informed decision regarding the cache size that your implementation requires. It is recommended that you change the cache size on app launch for the shared instance of DownloadKit. However, for new instances of DownloadKit the cache will be separate from the shared instance. The cache will automatically evict files as needed.

The default cache size is set to 150 MB.

In your  `AppDelegate`:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    DownloadKit.shared = DownloadKit(memorySize: 150 * 1024 * 1024) // 150 MB cache
    return true
}
```

> Due to how Apple implemented `URLCache` the cache will only store a downloaded file if it's size is less than 5% of the total cache size. So take this into account when selecting a cache size.

#### Clearing the Cache

The cache can be cleared manually in case a fresh copy of a file is required. You can clear the entire cache with `clearCache()`.

```swift
DownloadKit.shared.clearCache()
```

OR you can clear a specific file from the cache using `clearCache(for:)`.

```swift
let url = URL(string: "https://httpbin.org/image/jpeg")

DownloadKit.shared.clearCache(for: url)
```
Once the cache has been cleared for a given `URL`, any new requests to that `URL` will fetch new data. 

## Author

moizullah, moizullahamir94@gmail.com

## License

DownloadKit is available under the MIT license. See the LICENSE file for more info.
