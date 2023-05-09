//
//  UserPermissionsInteractor.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 26.04.2020.
//  Copyright © 2020 Alexey Naumov. All rights reserved.
//

import Foundation
import UserNotifications

// 다음은 UserPermissionsInteractor 프로토콜 및 RealUserPermissionsInteractor, StubUserPermissionsInteractor 클래스의 주요 코드입니다.
enum Permission {
    case pushNotifications
}

extension Permission {
    enum Status: Equatable {
        case unknown
        case notRequested
        case granted
        case denied
    }
}

protocol UserPermissionsInteractor: AnyObject {
    func resolveStatus(for permission: Permission)
    func request(permission: Permission)
}

// MARK: - RealUserPermissionsInteractor
/*
 Permission은 앱에서 요청할 수 있는 권한의 유형을 나타냅니다. 현재는 푸시 알림 권한만 있습니다.
 Permission은 각 권한에 대한 현재 상태를 보유하는 Status 열거형을 가지고 있습니다. 이것은 권한이 요청되기 전, 거부되었거나 승인된 경우에 대한 정보를 제공합니다.
 UserPermissionsInteractor 프로토콜은 권한 상태를 확인하고 권한 요청을 시작하는 기능을 정의합니다.
 */
final class RealUserPermissionsInteractor: UserPermissionsInteractor {
    
    private let appState: Store<AppState>
    private let openAppSettings: () -> Void
    
    init(appState: Store<AppState>, openAppSettings: @escaping () -> Void) {
        log.debug("+")
        
        self.appState = appState
        self.openAppSettings = openAppSettings
    }
    
    // 권한 상태 확인
    func resolveStatus(for permission: Permission) {
        log.debug("+")
        
        let keyPath = AppState.permissionKeyPath(for: permission)
        let currentStatus = appState[keyPath]
        guard currentStatus == .unknown else { return }
        let onResolve: (Permission.Status) -> Void = { [weak appState] status in
            appState?[keyPath] = status
        }
        switch permission {
        case .pushNotifications:
            pushNotificationsPermissionStatus(onResolve)
        }
    }
    
    // 권한 요청
    func request(permission: Permission) {
        log.debug("+")
        
        let keyPath = AppState.permissionKeyPath(for: permission)
        let currentStatus = appState[keyPath]
        guard currentStatus != .denied else {
            openAppSettings()
            return
        }
        switch permission {
        case .pushNotifications:
            requestPushNotificationsPermission()
        }
    }
}

// MARK: - Push Notifications
/*
 RealUserPermissionsInteractor는 UserPermissionsInteractor 프로토콜을 구현하는 클래스입니다. 실제 앱에서 권한 상태를 확인하고 권한을 요청하는 기능을 제공합니다.
 StubUserPermissionsInteractor는 UserPermissionsInteractor 프로토콜을 구현하는 클래스입니다. 단순히 권한 상태를 확인하고 권한을 요청하지 않습니다.
 */
extension UNAuthorizationStatus {
    // UNAuthorizationStatus를 Permission.Status로 변환
    var map: Permission.Status {
        switch self {
        case .denied: return .denied
        case .authorized: return .granted
        case .notDetermined, .provisional, .ephemeral: return .notRequested
        @unknown default: return .notRequested
        }
    }
}

private extension RealUserPermissionsInteractor {
    // 푸시 알림 권한 상태 확인
    func pushNotificationsPermissionStatus(_ resolve: @escaping (Permission.Status) -> Void) {
        log.debug("+")
        
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                resolve(settings.authorizationStatus.map)
            }
        }
    }
    
    // 푸시 알림 권한 요청
    func requestPushNotificationsPermission() {
        log.debug("+")
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { (isGranted, error) in
            DispatchQueue.main.async {
                self.appState[\.permissions.push] = isGranted ? .granted : .denied
            }
        }
    }
}

// MARK: -

final class StubUserPermissionsInteractor: UserPermissionsInteractor {
    
    func resolveStatus(for permission: Permission) {
        log.debug("+")
        
    }
    func request(permission: Permission) {
        log.debug("+")
        
    }
}
