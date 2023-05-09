//
//  AppDelegate.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 23.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import UIKit
import XCGLogger

let log = XCGLogger.default

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        setXcgLoger()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        log.debug("+")
        
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
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
