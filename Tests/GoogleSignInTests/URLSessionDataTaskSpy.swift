import Foundation

class URLSessionDataTaskSpy: URLSessionDataTask {

    private(set) var didResume = false

    // MARK: - URLSessionDataTask

    override func resume() {
        didResume = true
    }

}
