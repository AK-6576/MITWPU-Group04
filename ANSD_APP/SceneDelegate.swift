import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        
        // Check if the scheme is ours
        if url.scheme == "ansdapp" {
            let urlString = url.absoluteString
            // Extract the ID after 'join/'
            if let roomID = urlString.components(separatedBy: "join/").last {
                print("Joining room: \(roomID)")
                
                // Post a notification or call a method to update your GroupNewViewController
                NotificationCenter.default.post(name: NSNotification.Name("JoinRoom"), object: roomID)
            }
        }
    }
}
