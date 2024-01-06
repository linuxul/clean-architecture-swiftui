//
//  SceneDelegate.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 23.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import UIKit
import SwiftUI
import Combine
import Foundation

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    var systemEventsHandler: SystemEventsHandler?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        log.debug("+")
        
        let environment = AppEnvironment.bootstrap()
        let contentView = ContentView(viewModel:
            ContentView.ViewModel(container: environment.container))
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
        self.systemEventsHandler = environment.systemEventsHandler
        if !connectionOptions.urlContexts.isEmpty {
            systemEventsHandler?.sceneOpenURLContexts(connectionOptions.urlContexts)
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        log.debug("+")
        
        systemEventsHandler?.sceneOpenURLContexts(URLContexts)
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        log.debug("+")
        
        systemEventsHandler?.sceneDidBecomeActive()
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        log.debug("+")
        
        systemEventsHandler?.sceneWillResignActive()
    }
}
