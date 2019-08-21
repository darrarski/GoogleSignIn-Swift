import Foundation
import GoogleSignIn

class URLSessionSpy: URLSessionProtocol {

    private(set) var didCreateDataTaskWithRequest: URLRequest?
    private(set) var dataTaskCompletionHandler: ((Data?, URLResponse?, Swift.Error?) -> Void)?
    private(set) var createdDataTask: URLSessionDataTaskSpy?

    // MARK: - URLSessionProtocol

    func dataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Swift.Error?) -> Void
    ) -> URLSessionDataTask {
        didCreateDataTaskWithRequest = request
        dataTaskCompletionHandler = completionHandler
        let task = URLSessionDataTaskSpy()
        createdDataTask = task
        return task
    }

}
