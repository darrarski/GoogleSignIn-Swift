public struct Config {

    public init(clientId: String,
                clientSecret: String,
                redirectUri: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectUri = redirectUri
    }

    public var clientId: String
    public var clientSecret: String
    public var redirectUri: String

}
