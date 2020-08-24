import Foundation

public class Controller {

    public init(config: Config, session: URLSessionProtocol) {
        self.config = config
        self.session = session
    }

    public var signInPageURL: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "accounts.google.com"
        components.path = "/o/oauth2/v2/auth"
        components.queryItems = [
            URLQueryItem(name: "client_id", value: config.clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "email"),
            URLQueryItem(name: "redirect_uri", value: config.redirectUri)
        ]
        return components.url!
    }

    public func getTokenResponse(using redirectUrl: URL, completion: @escaping (Result<TokenResponse, Error>) -> Void) {
        guard let code = self.code(from: redirectUrl) else {
            completion(.failure(.codeNotFoundInRedirectURL))
            return
        }
        let task = session.dataTask(with: makeTokenRequest(with: code)) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }
            do {
                completion(.success(try self.decodeToken(from: data)))
            } catch {
                completion(.failure(.tokenDecodingError(error)))
            }
        }
        task.resume()
    }

    // MARK: - Private

    private let config: Config
    private let session: URLSessionProtocol

    private func code(from redirectURL: URL) -> String? {
        let components = URLComponents(url: redirectURL, resolvingAgainstBaseURL: false)
        return components?.queryItems?.first(where: { $0.name == "code" })?.value
    }

    private func makeTokenRequest(with code: String) -> URLRequest {
        var request = URLRequest(url: makeTokenURL())
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let params = [
            "code": code,
            "client_id": config.clientId,
            "client_secret": config.clientSecret,
            "grant_type": "authorization_code",
            "redirect_uri": config.redirectUri
        ]
        let bodyString = params
            .map { key, value in "\(key)=\(value)" }
            .joined(separator: "&")
        let bodyData = bodyString.data(using: .utf8)
        request.httpBody = bodyData
        return request
    }

    private func makeTokenURL() -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.googleapis.com"
        components.path = "/oauth2/v4/token"
        return components.url!
    }

    private func decodeToken(from data: Data) throws -> TokenResponse {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(TokenResponse.self, from: data)
    }

}
