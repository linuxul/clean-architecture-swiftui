//
//  Store.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 04.04.2020.
//  Copyright © 2020 Alexey Naumov. All rights reserved.
//
/*
 이 코드는 Store 타입 및 관련 확장을 정의합니다.
 Store는 SwiftUI 앱의 상태를 저장하고 관리하는 데 사용되는 CurrentValueSubject의 typealias입니다.
 이 타입은 앱 상태를 저장하고 업데이트하는 방법을 제공하며, 상태 변경에 대한 게시자를 사용하여 앱의 다른 부분과 상태를 동기화할 수 있습니다.
 */
import SwiftUI
import Combine

typealias Store<State> = CurrentValueSubject<State, Never>

// Store를 확장하여 KeyPath를 사용하여 상태 값을 가져오고 설정할 수 있도록 subscript를 추가합니다.
extension Store {
    
    subscript<T>(keyPath: WritableKeyPath<Output, T>) -> T where T: Equatable {
        get { value[keyPath: keyPath] }
        set {
            var value = self.value
            if value[keyPath: keyPath] != newValue {
                value[keyPath: keyPath] = newValue
                self.value = value
            }
        }
    }
    
    // 상태 값을 일괄적으로 업데이트하는 메서드입니다.
    func bulkUpdate(_ update: (inout Output) -> Void) {
        log.debug("+")
        
        var value = self.value
        update(&value)
        self.value = value
    }
    
    // 특정 상태 값에 대한 업데이트를 게시하는 메서드입니다.
    func updates<Value>(for keyPath: KeyPath<Output, Value>) ->
    AnyPublisher<Value, Failure> where Value: Equatable {
        log.debug("+")
        
        return map(keyPath).removeDuplicates().eraseToAnyPublisher()
    }
}

// MARK: -
/*
 Binding 타입을 확장하여 dispatched(to: keyPath:) 및 onSet(_:) 메서드를 추가합니다.
 이 확장은 SwiftUI 뷰의 바인딩 상태를 Store의 상태와 동기화하는 데 도움이 됩니다.
 이렇게 하면 상태 관리를 수행하면서 중복 값을 방지하고 성능을 개선할 수 있습니다.
 이 파일은 앱의 상태 저장 및 관리에 사용되는 핵심 구성 요소입니다.
 */
extension Binding where Value: Equatable {
    func dispatched<State>(to state: Store<State>,
                           _ keyPath: WritableKeyPath<State, Value>) -> Self {
        log.debug("+")
        
        return onSet { state[keyPath] = $0 }
    }
}

// Binding을 확장하여 값이 설정될 때 특정 동작을 수행할 수 있도록 메서드를 추가합니다.
extension Binding where Value: Equatable {
    typealias ValueClosure = (Value) -> Void
    
    func onSet(_ perform: @escaping ValueClosure) -> Self {
        log.debug("+")
        
        return .init(get: { () -> Value in
            self.wrappedValue
        }, set: { value in
            if self.wrappedValue != value {
                self.wrappedValue = value
            }
            perform(value)
        })
    }
}
