import Foundation

public protocol URLSessionProtocol {
    func dataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Swift.Error?) -> Void
    ) -> URLSessionDataTask
}
