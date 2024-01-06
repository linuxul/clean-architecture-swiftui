//
//  SystemEventsHandler.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 27.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//
/*
 이 코드는 앱의 시스템 이벤트를 처리하는 `RealSystemEventsHandler` 구조체와 관련 프로토콜을 정의합니다.
 이 클래스는 앱의 키보드 높이를 옵저빙하고 푸시 알림을 처리하는 등 앱의 시스템 이벤트에 대한 작업을 수행합니다.
 또한 앱이 활성화되거나 비활성화될 때 상태를 업데이트하고, 원격 알림을 받았을 때 국가 목록을 새로고침하는 등의 작업을 수행합니다.
 이러한 작업은 앱의 전반적인 시스템 이벤트를 처리하는 데 사용되며, 이 파일은 시스템 이벤트 처리의 핵심 구성 요소입니다.
 */
import UIKit
import Combine

// 시스템 이벤트 처리 프로토콜을 정의합니다.
protocol SystemEventsHandler {
    func sceneOpenURLContexts(_ urlContexts: Set<UIOpenURLContext>)
    func sceneDidBecomeActive()
    func sceneWillResignActive()
    func handlePushRegistration(result: Result<Data, Error>)
    func appDidReceiveRemoteNotification(payload: NotificationPayload,
                                         fetchCompletion: @escaping FetchCompletion)
}

struct RealSystemEventsHandler: SystemEventsHandler {
    
    let container: DIContainer
    let deepLinksHandler: DeepLinksHandler
    let pushNotificationsHandler: PushNotificationsHandler
    let pushTokenWebRepository: PushTokenWebRepository
    private var cancelBag = CancelBag()
    
    // 이 클래스를 초기화하는 메서드입니다.
    init(container: DIContainer,
         deepLinksHandler: DeepLinksHandler,
         pushNotificationsHandler: PushNotificationsHandler,
         pushTokenWebRepository: PushTokenWebRepository) {
        log.debug("+")
        
        self.container = container
        self.deepLinksHandler = deepLinksHandler
        self.pushNotificationsHandler = pushNotificationsHandler
        self.pushTokenWebRepository = pushTokenWebRepository
        
        installKeyboardHeightObserver()
        installPushNotificationsSubscriberOnLaunch()
    }
    
    // 키보드 높이 옵저버를 설치하는 메서드입니다
    private func installKeyboardHeightObserver() {
        log.debug("+")
        
        let appState = container.appState
        NotificationCenter.default.keyboardHeightPublisher
            .sink { [appState] height in
                appState[\.system.keyboardHeight] = height
            }
            .store(in: cancelBag)
    }
    
    // 앱 실행 시 푸시 알림 구독자를 설치하는 메서드입니다.
    private func installPushNotificationsSubscriberOnLaunch() {
        log.debug("+")
        
        weak var permissions = container.services.userPermissionsService
        container.appState
            .updates(for: AppState.permissionKeyPath(for: .pushNotifications))
            .first(where: { $0 != .unknown })
            .sink { status in
                if status == .granted {
                    // 이전 실행에서 권한이 허용된 경우 푸시 토큰을 다시 요청합니다.
                    permissions?.request(permission: .pushNotifications)
                }
            }
            .store(in: cancelBag)
    }
    
    // URL 컨텍스트를 처리하는 메서드입니다.
    func sceneOpenURLContexts(_ urlContexts: Set<UIOpenURLContext>) {
        log.debug("+")
        
        guard let url = urlContexts.first?.url else { return }
        handle(url: url)
    }
    
    // 주어진 URL을 처리하는 메서드입니다.
    private func handle(url: URL) {
        log.debug("+")
        
        guard let deepLink = DeepLink(url: url) else { return }
        deepLinksHandler.open(deepLink: deepLink)
    }
    
    // 앱이 활성화될 때 호출되는 메서드입니다.
    func sceneDidBecomeActive() {
        log.debug("+")
        
        container.appState[\.system.isActive] = true
        container.services.userPermissionsService.resolveStatus(for: .pushNotifications)
    }
    
    // 앱이 비활성화될 때 호출되는 메서드
    func sceneWillResignActive() {
        log.debug("+")
        
        container.appState[\.system.isActive] = false
    }
    
    // 푸시 등록 결과를 처리하는 메서드입니다.
    func handlePushRegistration(result: Result<Data, Error>) {
        log.debug("+")
        
        if let pushToken = try? result.get() {
            pushTokenWebRepository
                .register(devicePushToken: pushToken)
                .sinkToResult { _ in }
                .store(in: cancelBag)
        }
    }
    
    // 원격 알림을 받았을 때 호출되는 메서드입니다.
    func appDidReceiveRemoteNotification(payload: NotificationPayload,
                                         fetchCompletion: @escaping FetchCompletion) {
        container.services.countriesService
            .refreshCountriesList()
            .sinkToResult { result in
                fetchCompletion(result.isSuccess ? .newData : .failed)
            }
            .store(in: cancelBag)
    }
}

// MARK: - Notifications
// NotificationCenter에 대한 확장을 정의합니다.
private extension NotificationCenter {
    
    // 키보드 높이를 게시하는 퍼블리셔를 반환합니다.
    var keyboardHeightPublisher: AnyPublisher<CGFloat, Never> {
        let willShow = publisher(for: UIApplication.keyboardWillShowNotification)
            .map { $0.keyboardHeight }
        let willHide = publisher(for: UIApplication.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
        return Publishers.Merge(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

// Notification에 대한 확장을 정의합니다.
private extension Notification {
    
    // 키보드 높이를 반환하는 연산 프로퍼티입니다.
    var keyboardHeight: CGFloat {
        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?
            .cgRectValue.height ?? 0
    }
}
