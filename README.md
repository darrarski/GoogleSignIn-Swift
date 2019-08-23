# GoogleSignIn-Swift

![Swift: v5.0](https://img.shields.io/badge/swift-v5.0-orange.svg)
![platform: iOS | macOS](https://img.shields.io/badge/platform-iOS%20|%20macOS-blue.svg)
![Swift Package Manager](https://img.shields.io/badge/Swift%20Package%20Manager-orange.svg)

Minimalistic Google Sign In oAuth 2.0 client written in Swift

## Install

GoogleSignIn-Swift is compatible with [Swift Package Manager](https://swift.org/package-manager/). You can add it as a dependency to your Xcode project by following [official documentation](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app).

## Use

1. You will need to configure Google oAuth 2.0 client

    1. Go to [Google API Console](https://console.developer.google.com/)
    2. Create new project or choose existing one
    3. On "Credentials" page, choose "Create credentials ➔ oAuth Client ID"
    4. Choose "Other" as a Application Type

2. In your project create `GoogleSignIn.Controller` instance

    ```swift
    import GoogleSignIn

    let controller = GoogleSignIn.Controller(
        config: GoogleSignIn.Config(
            clientId: "CLIENT_ID",
            clientSecret: "CLIENT_SECRET",
            redirectUri: "REDIRECT_URI"
        ),
        session: URLSession.shared
    )
    ```
  
    You can obtain `CLIENT_ID` and `CLIENT_SECRET` from [Google API Console](https://console.developer.google.com/).
  
    `REDIRECT_URI` is your `CLIENT_ID` with reverse domain notation and `://` suffix. For example:
  
    - client id: `1234-abcd.apps.googleusercontent.com`
    - reversed client id: `com.googleusercontent.apps.1234-abcd`
    - redirect uri: `com.googleusercontent.apps.1234-abcd://`

3. Implement presenting sign in page to the user, by opening `signInPageURL` provided by the controller. 

    It can vary depending on the type of the app you are working on. The simpliest way to do it in iOS app is by using `UIApplication.open(_ url:)`:

    ```swift
    UIApplication.shared.open(controller.signInPageURL)
    ```

4. Configure your application, so it can handle redirect after sign in. 
   
    For iOS app, you can do it by adding or modifying `CFBundleURLTypes` in `Info.plist`:

    ```
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleURLName</key>
            <string></string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>REDIRECT_URI_SCHEME</string>
            </array>
        </dict>
    </array>
    ```
  
    Replace `REDIRECT_URI_SCHEME` with your `CLIENT_ID` using reverse domain notation. For example: `com.googleusercontent.apps.1234-abcd`.
  
5. Handle redirection after user signs in to obtain oAuth Access Token by calling `getAccessToken` function on `GoogleSignIn.Controller`.

    For iOS app, you can do it by implementing this function in your `UIApplicationDelegate`:
  
    ```swift
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        controller.getAccessToken(using: url) { result in
            if case let .success(token) = result {
                print("ACCESS TOKEN: \(token)")
            }
        }
        return true
    }
    ```
  
    If you are using `UIWindowSceneDelegate` in your app, implement this function instead:
  
    ```swift
    func scene(_ scene: UIScene, openURLContexts contexts: Set<UIOpenURLContext>) {
        guard let redirectUrl = contexts.first?.url else { return }
        controller.getAccessToken(using: redirectUrl) { result in
            if case let .success(token) = result {
                print("ACCESS TOKEN: \(token)")
            }
        }
    }
    ```

6. Do whatever you want with obtained access token.

## License

Copyright © 2019 Dariusz Rybicki Darrarski

License: [GNU GPLv3](LICENSE)
