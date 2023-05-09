//
//  PushNotificationsHandler.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 26.04.2020.
//  Copyright © 2020 Alexey Naumov. All rights reserved.
//

/*
 이 코드는 앱의 푸시 알림을 처리하는 데 사용되는 PushNotificationsHandler 파일입니다.
 푸시 알림을 받아 처리하고, 필요한 경우 딥 링크를 사용하여 관련 작업을 수행합니다.
 UNUserNotificationCenterDelegate 프로토콜을 구현하여 푸시 알림에 대한 사용자 응답을 처리하고,
 알림 페이로드에서 국가 코드를 추출하여 딥 링크 처리를 위임합니다.
 */
import UserNotifications

// 푸시 알림 처리 프로토콜을 정의합니다.
protocol PushNotificationsHandler { }

// 실제 푸시 알림 처리를 수행하는 클래스를 정의합니다.
class RealPushNotificationsHandler: NSObject, PushNotificationsHandler {
    
    private let deepLinksHandler: DeepLinksHandler
    
    // DeepLinksHandler를 사용하여 RealPushNotificationsHandler를 초기화합니다.
    init(deepLinksHandler: DeepLinksHandler) {
        log.debug("+")
        
        self.deepLinksHandler = deepLinksHandler
        super.init()
        // UNUserNotificationCenter의 델리게이트로 현재 객체를 설정합니다.
        UNUserNotificationCenter.current().delegate = self
    }
}

// MARK: - UNUserNotificationCenterDelegate
// UNUserNotificationCenterDelegate 프로토콜을 구현합니다.
extension RealPushNotificationsHandler: UNUserNotificationCenterDelegate {
    
    // 앱이 실행 중일 때 푸시 알림이 도착하면 호출되는 메서드입니다.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void) {
        log.debug("+")
        
        // 푸시 알림을 사용자에게 표시합니다.
        completionHandler([.list, .banner, .sound])
    }
    
    // 사용자가 푸시 알림에 응답하면 호출되는 메서드입니다.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        log.debug("+")
        
        // 푸시 알림의 사용자 정보를 처리합니다.
        let userInfo = response.notification.request.content.userInfo
        handleNotification(userInfo: userInfo, completionHandler: completionHandler)
    }
    
    // 푸시 알림의 사용자 정보를 처리하는 메서드를 정의합니다.
    func handleNotification(userInfo: [AnyHashable: Any], completionHandler: @escaping () -> Void) {
        log.debug("+")
        
        // 푸시 알림 페이로드에서 countryCode를 추출합니다.
        guard let payload = userInfo["aps"] as? NotificationPayload,
            let countryCode = payload["country"] as? Country.Code else {
            completionHandler()
            return
        }
        // countryCode를 사용하여 딥 링크를 엽니다.
        deepLinksHandler.open(deepLink: .showCountryFlag(alpha3Code: countryCode))
        completionHandler()
    }
}
