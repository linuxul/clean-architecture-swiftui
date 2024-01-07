//
//  Helpers.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 10.11.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import SwiftUI
import Combine

// MARK: - General
// ProcessInfo 확장으로 테스트 실행 여부를 확인합니다.
extension ProcessInfo {
    var isRunningTests: Bool {
        environment["XCTestConfigurationFilePath"] != nil
    }
}

// String 확장으로 지역화된 문자열을 가져옵니다.
extension String {
    func localized(_ locale: Locale) -> String {
        log.debug("locale = \(locale)")
        
        let localeId = locale.shortIdentifier
        guard let path = Bundle.main.path(forResource: localeId, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(self, comment: "")
        }
        return bundle.localizedString(forKey: self, value: nil, table: nil)
    }
}

// Result 확장으로 성공 여부를 확인합니다.
extension Result {
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
}

// MARK: - View Inspection helper
// Inspection 클래스를 정의하여 SwiftUI 뷰를 검사하는 도우미를 생성합니다.
internal final class Inspection<V> {
    // 검사 시 사용되는 PassthroughSubject를 생성합니다.
    let notice = PassthroughSubject<UInt, Never>()
    // 콜백 목록을 초기화합니다.
    var callbacks = [UInt: (V) -> Void]()
    
    // 검사 중인 뷰를 방문하고 해당 줄의 콜백을 실행합니다.
    func visit(_ view: V, _ line: UInt) {
        log.debug("view = \(view), line = \(line)")
        
        if let callback = callbacks.removeValue(forKey: line) {
            callback(view)
        }
    }
}
