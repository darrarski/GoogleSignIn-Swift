public struct TokenResponse: Codable, Equatable {
    public let accessToken: String
    public let expiresIn: Int
    public let idToken: String
    public let scope: String
    public let tokenType: String
    public let refreshToken: String?
}
