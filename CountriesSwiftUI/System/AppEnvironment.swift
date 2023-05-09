//
//  AppEnvironment.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 09.11.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//


import UIKit
import Combine

/*
 이 코드는 앱 환경 구성과 관련된 파일입니다. 주요 구성 요소 및 서비스를 초기화하고 설정하는 데 사용됩니다. AppEnvironment 구조체는 앱의 DIContainer 및 SystemEventsHandler를 포함하며, 부트스트랩 메서드를 사용하여 앱 구성 요소를 설정하고 초기화합니다. 이 파일에서는 URLSession, 웹 리포지토리, 데이터베이스 리포지토리, 인터랙터를 설정하고 초기화합니다.
 */
struct AppEnvironment {
    let container: DIContainer
    let systemEventsHandler: SystemEventsHandler
}

extension AppEnvironment {
    
    // 앱 환경의 부트스트랩 메서드를 정의합니다.
    // 이 메서드에서 앱 구성 요소를 설정하고 초기화하며 AppEnvironment 인스턴스를 반환합니다.
    static func bootstrap() -> AppEnvironment {
        log.debug("+")
        
        // 앱 상태 저장소를 생성합니다.
        let appState = Store<AppState>(AppState())
        /*
         To see the deep linking in action:
         
         1. Launch the app in iOS 13.4 simulator (or newer)
         2. Subscribe on Push Notifications with "Allow Push" button
         3. Minimize the app
         4. Drag & drop "push_with_deeplink.apns" into the Simulator window
         5. Tap on the push notification
         
         Alternatively, just copy the code below before the "return" and launch:
         
         DispatchQueue.main.async {
         deepLinksHandler.open(deepLink: .showCountryFlag(alpha3Code: "AFG"))
         }
         */
        
        // URLSession을 구성합니다.
        let session = configuredURLSession()
        // 웹 리포지토리를 구성합니다.
        let webRepositories = configuredWebRepositories(session: session)
        // 데이터베이스 리포지토리를 구성합니다.
        let dbRepositories = configuredDBRepositories(appState: appState)
        // 인터랙터를 구성합니다.
        let interactors = configuredInteractors(appState: appState,
                                                dbRepositories: dbRepositories,
                                                webRepositories: webRepositories)
        // DIContainer를 생성합니다.
        let diContainer = DIContainer(appState: appState, interactors: interactors)
        // 딥 링크 핸들러를 생성합니다.
        let deepLinksHandler = RealDeepLinksHandler(container: diContainer)
        // 푸시 알림 핸들러를 생성합니다.
        let pushNotificationsHandler = RealPushNotificationsHandler(deepLinksHandler: deepLinksHandler)
        // 시스템 이벤트 핸들러를 생성합니다.
        let systemEventsHandler = RealSystemEventsHandler(
            container: diContainer, deepLinksHandler: deepLinksHandler,
            pushNotificationsHandler: pushNotificationsHandler,
            pushTokenWebRepository: webRepositories.pushTokenWebRepository)
        
        // 생성된 구성 요소를 사용하여 AppEnvironment 인스턴스를 반환합니다.
        return AppEnvironment(container: diContainer,
                              systemEventsHandler: systemEventsHandler)
    }
    
    // URLSession을 구성하는 메서드를 정의합니다.
    private static func configuredURLSession() -> URLSession {
        log.debug("+")
        
        // URLSessionConfiguration 객체를 생성하고 구성합니다.
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 120
        configuration.waitsForConnectivity = true
        configuration.httpMaximumConnectionsPerHost = 5
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = .shared
        
        // 구성된 URLSessionConfiguration을 사용하여 URLSession을 반환합니다.
        return URLSession(configuration: configuration)
    }
    
    // 웹 리포지토리를 구성하는 메서드를 정의합니다.
    private static func configuredWebRepositories(session: URLSession) -> DIContainer.WebRepositories {
        log.debug("+")
        
        // 각 웹 리포지토리를 생성하고 초기화합니다.
        let countriesWebRepository = RealCountriesWebRepository(
            session: session,
            baseURL: "https://restcountries.com/v2")
        let imageWebRepository = RealImageWebRepository(
            session: session,
            baseURL: "https://ezgif.com")
        let pushTokenWebRepository = RealPushTokenWebRepository(
            session: session,
            baseURL: "https://fake.backend.com")
        
        // 생성된 웹 리포지토리를 DIContainer.WebRepositories 인스턴스로 반환합니다.
        return .init(imageRepository: imageWebRepository,
                     countriesRepository: countriesWebRepository,
                     pushTokenWebRepository: pushTokenWebRepository)
    }
    
    // 데이터베이스 리포지토리를 구성하는 메서드를 정의합니다.
    private static func configuredDBRepositories(appState: Store<AppState>) -> DIContainer.DBRepositories {
        log.debug("+")
        
        // CoreDataStack 객체를 생성합니다.
        let persistentStore = CoreDataStack(version: CoreDataStack.Version.actual)
        // 데이터베이스 리포지토리를 생성하고 초기화합니다.
        let countriesDBRepository = RealCountriesDBRepository(persistentStore: persistentStore)
        // 생성된 데이터베이스 리포지토리를 DIContainer.DBRepositories 인스턴스로 반환합니다.
        return .init(countriesRepository: countriesDBRepository)
    }
    
    // 인터랙터를 구성하는 메서드를 정의합니다.
    private static func configuredInteractors(appState: Store<AppState>,
                                              dbRepositories: DIContainer.DBRepositories,
                                              webRepositories: DIContainer.WebRepositories
    ) -> DIContainer.Interactors {
        log.debug("+")
        
        // 각 인터랙터를 생성하고 초기화합니다.
        let countriesInteractor = RealCountriesInteractor(
            webRepository: webRepositories.countriesRepository,
            dbRepository: dbRepositories.countriesRepository,
            appState: appState)
        
        let imagesInteractor = RealImagesInteractor(
            webRepository: webRepositories.imageRepository)
        
        let userPermissionsInteractor = RealUserPermissionsInteractor(
            appState: appState, openAppSettings: {
                URL(string: UIApplication.openSettingsURLString).flatMap {
                    UIApplication.shared.open($0, options: [:], completionHandler: nil)
                }
            })
        
        // 생성된 인터랙터를 DIContainer.Interactors 인스턴스로 반환합니다.
        return .init(countriesInteractor: countriesInteractor,
                     imagesInteractor: imagesInteractor,
                     userPermissionsInteractor: userPermissionsInteractor)
    }
}

// DIContainer에 웹 리포지토리와 데이터베이스 리포지토리를 정의합니다.
extension DIContainer {
    struct WebRepositories {
        let imageRepository: ImageWebRepository
        let countriesRepository: CountriesWebRepository
        let pushTokenWebRepository: PushTokenWebRepository
    }
    
    struct DBRepositories {
        let countriesRepository: CountriesDBRepository
    }
}
