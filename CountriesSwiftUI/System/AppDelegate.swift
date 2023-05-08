//
//  AppDelegate.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 23.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import UIKit
import Combine
import XCGLogger


let log = XCGLogger.default

typealias NotificationPayload = [AnyHashable: Any]
typealias FetchCompletion = (UIBackgroundFetchResult) -> Void

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    lazy var systemEventsHandler: SystemEventsHandler? = {
        self.systemEventsHandler(UIApplication.shared)
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        setXcgLoger()
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        log.debug("+")
        
        systemEventsHandler?.handlePushRegistration(result: .success(deviceToken))
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        log.debug("+")
        
        systemEventsHandler?.handlePushRegistration(result: .failure(error))
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: NotificationPayload,
                     fetchCompletionHandler completionHandler: @escaping FetchCompletion) {
        log.debug("+")
        
        systemEventsHandler?
            .appDidReceiveRemoteNotification(payload: userInfo, fetchCompletion: completionHandler)
    }
    
    private func systemEventsHandler(_ application: UIApplication) -> SystemEventsHandler? {
        log.debug("+")
        
        return sceneDelegate(application)?.systemEventsHandler
    }
    
    private func sceneDelegate(_ application: UIApplication) -> SceneDelegate? {
        log.debug("+")
        
        return application.windows
            .compactMap({ $0.windowScene?.delegate as? SceneDelegate })
            .first
    }
    
    // MARK: - XCGLoger 설정
    private func setXcgLoger() {
        
        let cacheDirectory: URL = {
            let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            return urls[urls.endIndex - 1]
        }()
        let nowDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let strLogFile = dateFormatter.string(from: nowDate) + ".log"
        let logPath = cacheDirectory.appendingPathComponent(strLogFile)
        
        // 상용 버전에서만 로그를 에러만 출력을 하도록 변경
        #if DEBUG
            log.setup(level: .verbose, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: logPath, fileLevel: .verbose)
        #else
            log.setup(level: .error, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: "XCGLogger", fileLevel: .error)
        #endif
    }
}
