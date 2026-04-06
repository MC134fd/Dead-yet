import SwiftUI
import GoogleSignIn

enum AuthConfig {
    // TODO: Replace with your Google Cloud OAuth client ID
    // 1. Go to https://console.cloud.google.com
    // 2. Create a project -> APIs & Services -> Credentials -> OAuth 2.0 Client ID (iOS)
    // 3. Paste the client ID below
    static let googleClientID = "YOUR_CLIENT_ID.apps.googleusercontent.com"
}

@Observable
@MainActor
final class AuthenticationService {
    var isSignedIn = false
    var userName: String?
    var userEmail: String?
    var userPhotoURL: URL?
    var errorMessage: String?

    func signIn() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            errorMessage = "Cannot find root view controller"
            return
        }

        let config = GIDConfiguration(clientID: AuthConfig.googleClientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
            let name = result?.user.profile?.name
            let email = result?.user.profile?.email
            let photoURL = result?.user.profile?.imageURL(withDimension: 200)
            let errorMsg = error?.localizedDescription

            Task { @MainActor [weak self] in
                guard let self else { return }
                if let errorMsg {
                    self.errorMessage = errorMsg
                    return
                }
                self.isSignedIn = true
                self.userName = name
                self.userEmail = email
                self.userPhotoURL = photoURL
                self.errorMessage = nil
            }
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        isSignedIn = false
        userName = nil
        userEmail = nil
        userPhotoURL = nil
    }

    func restorePreviousSignIn() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            let name = user?.profile?.name
            let email = user?.profile?.email
            let photoURL = user?.profile?.imageURL(withDimension: 200)

            Task { @MainActor [weak self] in
                guard let self, error == nil, name != nil else { return }
                self.isSignedIn = true
                self.userName = name
                self.userEmail = email
                self.userPhotoURL = photoURL
            }
        }
    }

    func handleURL(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
}
