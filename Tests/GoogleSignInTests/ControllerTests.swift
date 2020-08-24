import XCTest
@testable import GoogleSignIn

final class ControllerTests: XCTestCase {

    static var allTests = [
        ("testSingInPageURLShouldBeCorrect", testSingInPageURLShouldBeCorrect),
        ("testGetTokenResponseFromInvalidRedirectURLShouldFail", testGetTokenResponseFromInvalidRedirectURLShouldFail),
        ("testGetTokenResponseShouldCreateCorrectRequest", testGetTokenResponseShouldCreateCorrectRequest),
        ("testGetTokenResponseShouldFailOnNetworkError", testGetTokenResponseShouldFailOnNetworkError),
        ("testGetTokenResponseShouldFailWhenNoDataIsReceived", testGetTokenResponseShouldFailWhenNoDataIsReceived),
        ("testGetTokenResponseShouldFailWhenInvalidDataIsReceived", testGetTokenResponseShouldFailWhenInvalidDataIsReceived),
        ("testGetTokenResponseShouldCompleteWithDecodedToken", testGetTokenResponseShouldCompleteWithDecodedToken)
    ]

    var sut: Controller!
    var config: Config!
    var session: URLSessionSpy!

    override func setUp() {
        config = Config(
            clientId: "CLIENT-ID",
            clientSecret: "CLIENT-SECRET",
            redirectUri: "SCHEME://"
        )
        session = URLSessionSpy()
        sut = Controller(config: config, session: session)
    }

    override func tearDown() {
        sut = nil
        session = nil
        config = nil
    }

    func testSingInPageURLShouldBeCorrect() {
        let url = sut.signInPageURL
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        XCTAssertEqual(components?.scheme, "https")
        XCTAssertEqual(components?.host, "accounts.google.com")
        XCTAssertEqual(components?.path, "/o/oauth2/v2/auth")
        XCTAssertEqual(components?.queryItems?.count, 4)
        XCTAssertEqual(components?.queryItems?.first(where: { $0.name == "client_id" })?.value, config.clientId)
        XCTAssertEqual(components?.queryItems?.first(where: { $0.name == "response_type" })?.value, "code")
        XCTAssertEqual(components?.queryItems?.first(where: { $0.name == "scope" })?.value, "email")
        XCTAssertEqual(components?.queryItems?.first(where: { $0.name == "redirect_uri" })?.value, config.redirectUri)
    }

    func testGetTokenResponseFromInvalidRedirectURLShouldFail() {
        let redirectURL = URL(string: "https://localhost/no_code")!
        let completionCalled = XCTestExpectation(description: "Completion block called")
        sut.getTokenResponse(using: redirectURL) { result in
            if case .failure(.codeNotFoundInRedirectURL) = result {} else {
                let expectedResult = Result<TokenResponse, Error>.failure(.codeNotFoundInRedirectURL)
                XCTFail("Invalid result, expected <\(expectedResult)>, got <\(result)>")
            }
            completionCalled.fulfill()
        }
        wait(for: [completionCalled], timeout: 1)
        XCTAssertNil(session.didCreateDataTaskWithRequest)
    }

    func testGetTokenResponseShouldCreateCorrectRequest() {
        let code = "CODE-1234"
        let redirectURL = URL(string: "\(config.redirectUri)?code=\(code)&OTHER=1")!
        sut.getTokenResponse(using: redirectURL) { _ in }

        let createdRequest = session.didCreateDataTaskWithRequest
        XCTAssertEqual(createdRequest?.httpMethod, "POST")
        XCTAssertEqual(createdRequest?.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded")

        let createdRequestUrlComponents = createdRequest?.url.map { URLComponents(url: $0, resolvingAgainstBaseURL: true) }
        XCTAssertEqual(createdRequestUrlComponents??.scheme, "https")
        XCTAssertEqual(createdRequestUrlComponents??.host, "www.googleapis.com")
        XCTAssertEqual(createdRequestUrlComponents??.path, "/oauth2/v4/token")

        let createdRequestParams = createdRequest?.httpBody
            .map({ String(data: $0, encoding: .utf8) })??
            .components(separatedBy: "&")
            .reduce([String: String]()) { params, paramString in
                var params = params
                let components = paramString.components(separatedBy: "=")
                if let key = components.first, let value = components.last {
                    params[key] = value
                }
                return params
            }
        XCTAssertEqual(createdRequestParams, [
            "code": code,
            "client_id": config.clientId,
            "client_secret": config.clientSecret,
            "grant_type": "authorization_code",
            "redirect_uri": config.redirectUri
        ])

        XCTAssertEqual(session.createdDataTask?.didResume, true)
    }

    func testGetTokenResponseShouldFailOnNetworkError() {
        let code = "CODE-1234"
        let redirectURL = URL(string: "\(config.redirectUri)?code=\(code)&OTHER=1")!
        let networkError = NSError(domain: "some error", code: 357, userInfo: nil)
        let completionCalled = XCTestExpectation(description: "Completion block called")
        sut.getTokenResponse(using: redirectURL) { result in
            if case let .failure(.networkError(error)) = result {
                XCTAssert((error as NSError) === networkError)
            } else {
                let expectedResult = Result<TokenResponse, Error>.failure(.networkError(networkError))
                XCTFail("Invalid result, expected <\(expectedResult)>, got <\(result)>")
            }
            completionCalled.fulfill()
        }
        session.dataTaskCompletionHandler?(nil, nil, networkError)
        wait(for: [completionCalled], timeout: 1)
    }

    func testGetTokenResponseShouldFailWhenNoDataIsReceived() {
        let code = "CODE-1234"
        let redirectURL = URL(string: "\(config.redirectUri)?code=\(code)&OTHER=1")!
        let completionCalled = XCTestExpectation(description: "Completion block called")
        sut.getTokenResponse(using: redirectURL) { result in
            if case .failure(.invalidResponse) = result {} else {
                let expectedResult = Result<TokenResponse, Error>.failure(.invalidResponse)
                XCTFail("Invalid result, expected <\(expectedResult)>, got <\(result)>")
            }
            completionCalled.fulfill()
        }
        session.dataTaskCompletionHandler?(nil, nil, nil)
        wait(for: [completionCalled], timeout: 1)
    }

    func testGetTokenResponseShouldFailWhenInvalidDataIsReceived() {
        let code = "CODE-1234"
        let redirectURL = URL(string: "\(config.redirectUri)?code=\(code)&OTHER=1")!
        let completionCalled = XCTestExpectation(description: "Completion block called")
        sut.getTokenResponse(using: redirectURL) { result in
            if case .failure(.tokenDecodingError(_)) = result {} else {
                XCTFail("Invalid result, expected <failure(GoogleSignIn.Error.tokenDecodingError(...)>, got <\(result)>")
            }
            completionCalled.fulfill()
        }
        session.dataTaskCompletionHandler?(Data(), nil, nil)
        wait(for: [completionCalled], timeout: 1)
    }

    func testGetTokenResponseShouldCompleteWithDecodedToken() {
        let code = "CODE-1234"
        let redirectURL = URL(string: "\(config.redirectUri)?code=\(code)&OTHER=1")!
        let token = TokenResponse(
            accessToken: "ACCESS-TOKEN-4321",
            expiresIn: 0,
            idToken: "",
            scope: "",
            tokenType: "",
            refreshToken: nil
        )
        let completionCalled = XCTestExpectation(description: "Completion block called")
        sut.getTokenResponse(using: redirectURL) { result in
            if case let .success(resultToken) = result {
                XCTAssertEqual(resultToken, token)
            } else {
                let expectedResult = Result<TokenResponse, Error>.success(token)
                XCTFail("Invalid result, expected <\(expectedResult)>, got <\(result)>")
            }
            completionCalled.fulfill()
        }
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let tokenData = try! encoder.encode(token)
        session.dataTaskCompletionHandler?(tokenData, nil, nil)
        wait(for: [completionCalled], timeout: 1)
    }

}
