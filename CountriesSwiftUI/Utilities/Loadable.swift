//
//  Loadable.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 23.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

/*
 이 코드는 Loadable이라는 제네릭 열거형을 정의하고 있습니다. Loadable은 데이터 로드 상태를 나타내는 데 사용되며, 다음의 케이스들을 가지고 있습니다.

 notRequested: 데이터가 아직 요청되지 않은 상태
 isLoading(last: T?, cancelBag: CancelBag): 데이터 로딩 중인 상태. 이전 데이터를 포함하며, 취소 가능한 작업을 저장하는 CancelBag도 포함
 loaded(T): 데이터가 로드된 상태
 failed(Error): 데이터 로딩이 실패한 상태
 Loadable은 데이터의 현재 값(value)과 오류(error)를 가져올 수 있는 프로퍼티를 제공합니다.

 또한, Loadable 열거형은 다음과 같은 여러 메서드를 가지고 있습니다:

 setIsLoading(cancelBag: CancelBag): 현재 상태를 로딩 중으로 변경하고, CancelBag을 설정합니다.
 cancelLoading(): 로딩을 취소하고, 결과에 따라 상태를 변경합니다.
 map<V>(_ transform: (T) throws -> V) -> Loadable<V>: 데이터를 새로운 유형의 Loadable로 변환합니다.
 이 작업에서 오류가 발생하면 새로운 Loadable 상태를 실패로 설정합니다.
 unwrap(): Loadable에서 감싸진 값의 형태를 변경할 때 사용되는 메서드입니다.
 Loadable은 로드 상태를 추적하고 관리하는데 도움이 되는 유용한 구조입니다.
 이를 통해 앱의 상태를 더 명확하게 나타낼 수 있고, 오류 처리 및 데이터 변환에 대한 처리를 쉽게 할 수 있습니다.
 */
import Foundation
import SwiftUI

// 타입 별칭을 사용하여 Loadable을 바인딩으로 감싸는 LoadableSubject를 선언합니다.
typealias LoadableSubject<Value> = Binding<Loadable<Value>>

// 제네릭 Loadable 열거형을 정의합니다.
enum Loadable<T> {

    // 아직 요청되지 않은 상태를 나타냅니다.
    case notRequested
    // 데이터 로딩 중인 상태를 나타냅니다. 이전 데이터와 취소 가능한 작업을 저장하는 CancelBag를 포함합니다.
    case isLoading(last: T?, cancelBag: CancelBag)
    // 데이터가 로드된 상태를 나타냅니다.
    case loaded(T)
    // 데이터 로딩이 실패한 상태를 나타냅니다.
    case failed(Error)

    // 현재 데이터 값을 반환합니다.
    var value: T? {
        switch self {
        case let .loaded(value): return value
        case let .isLoading(last, _): return last
        default: return nil
        }
    }
    // 현재 오류 값을 반환합니다.
    var error: Error? {
        switch self {
        case let .failed(error): return error
        default: return nil
        }
    }
}

// Loadable 열거형에 대한 확장을 정의합니다.
extension Loadable {
    
    // 현재 상태를 로딩 중으로 설정하고 CancelBag을 연결합니다.
    mutating func setIsLoading(cancelBag: CancelBag) {
        log.debug("+")
        self = .isLoading(last: value, cancelBag: cancelBag)
    }
    
    // 현재 로딩을 취소하고 상태를 업데이트하는 함수입니다.
    mutating func cancelLoading() {
        log.debug("+")
        switch self {
        case let .isLoading(last, cancelBag):
            // CancelBag을 사용하여 로딩 작업을 취소합니다.
            cancelBag.cancel()
            if let last = last {
                // 이전 값이 있는 경우 로드된 상태로 변경합니다.
                self = .loaded(last)
            } else {
                // 이전 값이 없는 경우 실패한 상태로 변경하고 사용자 취소 오류를 설정합니다.
                let error = NSError(
                    domain: NSCocoaErrorDomain, code: NSUserCancelledError,
                    userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Canceled by user",
                                                                            comment: "")])
                self = .failed(error)
            }
        default: break
        }
    }
    
    // 현재 데이터를 새로운 Loadable 타입으로 변환합니다.
    func map<V>(_ transform: (T) throws -> V) -> Loadable<V> {
        log.debug("+")
        do {
            switch self {
            case .notRequested: return .notRequested
            case let .failed(error): return .failed(error)
            case let .isLoading(value, cancelBag):
                // 로딩 중인 값에 대해 변환 함수를 적용하고 결과를 새로운 Loadable로 반환합니다.
                return .isLoading(last: try value.map { try transform($0) },
                                  cancelBag: cancelBag)
            case let .loaded(value):
                // 로드된 값에 대해 변환 함수를 적용하고 결과를 새로운 Loadable로 반환합니다.
                return .loaded(try transform(value))
            }
        } catch {
            // 변환 중 오류가 발생한 경우 실패한 상태로 변경합니다.
            return .failed(error)
        }
    }
}

// SomeOptional 프로토콜은 값을 감싸고 있는 값의 형태를 변경하는 데 사용됩니다.
protocol SomeOptional {
    associatedtype Wrapped
    // 감싸진 값을 반환하거나 오류를 발생시키는 메서드를 구현해야 합니다.
    func unwrap() throws -> Wrapped
}

// 값이 누락되었을 때 발생하는 오류를 나타내는 구조체입니다.
struct ValueIsMissingError: Error {
    var localizedDescription: String {
        NSLocalizedString("Data is missing", comment: "")
    }
}

// Optional 유형에 대해 SomeOptional 프로토콜을 구현합니다.
extension Optional: SomeOptional {
    // 감싸진 값을 반환하거나 값이 없는 경우 ValueIsMissingError를 발생시킵니다.
    func unwrap() throws -> Wrapped {
        log.debug("+")
        
        switch self {
        case let .some(value): return value
        case .none: throw ValueIsMissingError()
        }
    }
}

// T가 SomeOptional 프로토콜을 구현하는 경우 Loadable 열거형에 대한 확장을 정의합니다.
extension Loadable where T: SomeOptional {
    // 감싸진 값을 변경하거나 오류를 발생시키는 메서드입니다.
    func unwrap() -> Loadable<T.Wrapped> {
        log.debug("+")
        
        return map { try $0.unwrap() }
    }
}

extension Loadable: Equatable where T: Equatable {
    // 두 Loadable 인스턴스가 동일한지 확인하는 함수입니다.
    static func == (lhs: Loadable<T>, rhs: Loadable<T>) -> Bool {
        log.debug("+")
        switch (lhs, rhs) {
        case (.notRequested, .notRequested):
            // 두 인스턴스가 모두 notRequested 상태인 경우 동일하다고 판단합니다.
            return true
        case let (.isLoading(lhsV, _), .isLoading(rhsV, _)):
            // 두 인스턴스가 모두 isLoading 상태이며 마지막 값이 동일한 경우 동일하다고 판단합니다.
            return lhsV == rhsV
        case let (.loaded(lhsV), .loaded(rhsV)):
            // 두 인스턴스가 모두 loaded 상태이며 값이 동일한 경우 동일하다고 판단합니다.
            return lhsV == rhsV
        case let (.failed(lhsE), .failed(rhsE)):
            // 두 인스턴스가 모두 failed 상태이며 오류 메시지가 동일한 경우 동일하다고 판단합니다.
            return lhsE.localizedDescription == rhsE.localizedDescription
        default:
            // 그 외의 경우에는 동일하지 않다고 판단합니다.
            return false
        }
    }
}
