//
//  DeepLinksHandler.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 26.04.2020.
//  Copyright © 2020 Alexey Naumov. All rights reserved.
//

// DeepLinksHandler 파일입니다.
// 딥 링크를 처리하고 관련된 액션을 수행하는 데 사용됩니다.
import Foundation

// 딥 링크 열거형을 정의합니다.
// 현재 딥 링크 유형은 특정 국가의 국기를 표시하는 것입니다.
enum DeepLink: Equatable {
    
    case showCountryFlag(alpha3Code: Country.Code)
    
    // URL을 사용하여 DeepLink 인스턴스를 생성하는 이니셜라이저입니다.
    init?(url: URL) {
        log.debug("url = \(url)")
        
        // URL에서 URLComponents를 추출하고 호스트 및 쿼리 항목을 확인합니다.
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            components.host == "www.example.com",
            let query = components.queryItems
        else { return nil }
        
        // 쿼리 항목 중 "alpha3code" 항목을 찾고 해당 값을 사용하여 딥 링크를 생성합니다.
        if let item = query.first(where: { $0.name == "alpha3code" }),
           let alpha3Code = item.value {
            self = .showCountryFlag(alpha3Code: Country.Code(alpha3Code))
            return
        }
        return nil
    }
}

// MARK: - DeepLinksHandler
// 딥 링크 처리 프로토콜을 정의합니다.
protocol DeepLinksHandler {
    func open(deepLink: DeepLink)
}

// 실제 딥 링크 처리를 수행하는 구조체를 정의합니다.
struct RealDeepLinksHandler: DeepLinksHandler {
    
    private let container: DIContainer
    
    // DIContainer를 사용하여 RealDeepLinksHandler를 초기화합니다.
    init(container: DIContainer) {
        log.debug("container = \(container)")
        
        self.container = container
    }
    
    // 딥 링크를 처리하고 관련된 액션을 수행하는 메서드를 정의합니다.
    func open(deepLink: DeepLink) {
        log.debug("deepLink = \(deepLink)")
        
        switch deepLink {
        case let .showCountryFlag(alpha3Code):
            // 목적지로 이동하는 루트를 정의합니다.
            let routeToDestination = {
                self.container.appState.bulkUpdate {
                    $0.routing.countriesList.countryDetails = alpha3Code
                    $0.routing.countryDetails.detailsSheet = true
                }
            }
            /*
             SwiftUI는 동시에 이전 화면을 닫고 새 화면을 표시하는 복잡한 탐색을 수행할 수 없습니다.
             이 문제를 해결하기 위해 두 단계로 탐색을 수행합니다:
             */
            let defaultRouting = AppState.ViewRouting()
            if container.appState.value.routing != defaultRouting {
                self.container.appState[\.routing] = defaultRouting
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: routeToDestination)
            } else {
                routeToDestination()
            }
        }
    }
}
