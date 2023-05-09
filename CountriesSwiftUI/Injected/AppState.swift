//
//  AppState.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 23.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import SwiftUI
import Combine

// 앱의 전체 상태를 나타내는 구조체를 정의합니다.
struct AppState: Equatable {
    // 사용자 데이터, 뷰 라우팅, 시스템 상태 및 권한을 포함합니다.
    var userData = UserData()
    var routing = ViewRouting()
    var system = System()
    var permissions = Permissions()
}

// 앱 상태 내부의 사용자 데이터를 정의합니다.
extension AppState {
    struct UserData: Equatable {
        /*
         국가 목록 (Loadable<[Country]>)이 여기에 저장되어 있습니다.
         데이터베이스 내에서 국가 이름별 검색을 수행하기 위해 제거되었습니다.
         결과적으로 이 변수는 하나의 화면 (CountriesList)에서만 로컬로 사용됩니다.
         그렇지 않으면 국가 목록이 여기에 남아 있을 수 있고 전체 앱에서 사용할 수 있습니다.
         */
    }
}

// 앱 상태 내부의 뷰 라우팅을 정의합니다.
extension AppState {
    struct ViewRouting: Equatable {
        var countriesList = CountriesList.Routing()
        var countryDetails = CountryDetails.Routing()
    }
}

// 앱 상태 내부의 시스템 상태를 정의합니다.
extension AppState {
    struct System: Equatable {
        var isActive: Bool = false
        var keyboardHeight: CGFloat = 0
    }
}

// 앱 상태 내부의 권한 상태를 정의합니다.
extension AppState {
    struct Permissions: Equatable {
        var push: Permission.Status = .unknown
    }
    
    // 권한에 대한 키 경로를 반환합니다.
    static func permissionKeyPath(for permission: Permission) -> WritableKeyPath<AppState, Permission.Status> {
        log.debug("+")
        
        let pathToPermissions = \AppState.permissions
        switch permission {
        case .pushNotifications:
            return pathToPermissions.appending(path: \.push)
        }
    }
}

// 앱 상태의 동등성을 확인합니다.
func == (lhs: AppState, rhs: AppState) -> Bool {
    return lhs.userData == rhs.userData &&
    lhs.routing == rhs.routing &&
    lhs.system == rhs.system &&
    lhs.permissions == rhs.permissions
}

// 디버그 모드에서 미리보기용 앱 상태를 생성합니다.
#if DEBUG
extension AppState {
    static var preview: AppState {
        var state = AppState()
        state.system.isActive = true
        return state
    }
}
#endif
