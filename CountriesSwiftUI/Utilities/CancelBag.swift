//
//  CancelBag.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 04.04.2020.
//  Copyright © 2020 Alexey Naumov. All rights reserved.
//
/*
 이 코드는 CancelBag 클래스와 관련된 확장을 정의합니다.
 CancelBag은 Combine 프레임워크를 사용할 때 구독을 관리하는 데 도움이 되는 유틸리티 클래스입니다.
 이 클래스를 사용하면 여러 구독을 쉽게 취소할 수 있습니다.
 */
import Combine

// CancelBag 클래스 정의
final class CancelBag {
    // Set of AnyCancellable 객체를 저장할 프로퍼티
    fileprivate(set) var subscriptions = Set<AnyCancellable>()
    
    // 모든 구독을 취소하고 Set을 비우는 메서드
    func cancel() {
        log.debug("+")
        subscriptions.removeAll()
    }
}

/*
 또한, AnyCancellable 타입을 확장하여 store(in:) 메서드를 추가합니다.
 이 메서드를 사용하여 CancelBag 인스턴스에 구독을 저장할 수 있습니다.
 나중에 CancelBag의 cancel() 메서드를 호출하여 모든 구독을 한 번에 취소할 수 있습니다.
 */
extension AnyCancellable {
    
    // CancelBag에 구독을 저장하는 메서드
    func store(in cancelBag: CancelBag) {
        log.debug("+")
        cancelBag.subscriptions.insert(self)
    }
}
