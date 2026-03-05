//
//  SceneDelegate.swift
//  ANSD_APP
//
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Check if a Firebase user is already logged in.
        // If yes → go straight to Home. If not → show Onboarding as normal.
        if Auth.auth().currentUser != nil {
            redirectToHome(in: windowScene)
        }
        // If not logged in, the storyboard's initial view controller (Onboarding) loads automatically.
    }

    // MARK: - Helpers

    /// Programmatically sets the root view controller to the HomeViewController
    /// embedded in a UINavigationController, bypassing the Onboarding flow.
    private func redirectToHome(in windowScene: UIWindowScene) {
        let homeStoryboard = UIStoryboard(name: "Home", bundle: nil)
        let homeVC = homeStoryboard.instantiateViewController(withIdentifier: "Home")
        let navController = UINavigationController(rootViewController: homeVC)

        let newWindow = UIWindow(windowScene: windowScene)
        newWindow.rootViewController = navController
        newWindow.makeKeyAndVisible()
        self.window = newWindow
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
