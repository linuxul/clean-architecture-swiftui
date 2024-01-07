//
//  NetworkingHelpers.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 04.04.2020.
//  Copyright © 2020 Alexey Naumov. All rights reserved.
//

import SwiftUI
import Combine
import Foundation

// Just의 확장으로 Void 출력에 대한 오류 유형을 설정합니다.
extension Just where Output == Void {
    static func withErrorType<E>(_ errorType: E.Type) -> AnyPublisher<Void, E> {
        log.verbose("+")
        
        return withErrorType((), E.self)
    }
}

// Just의 확장으로 출력에 대한 오류 유형을 설정합니다.
extension Just {
    static func withErrorType<E>(_ value: Output, _ errorType: E.Type) -> AnyPublisher<Output, E> {
        log.debug("value = \(value), errorType = \(errorType)")
        
        return Just(value)
            .setFailureType(to: E.self)
            .eraseToAnyPublisher()
    }
}

extension Publisher {
    // 결과를 처리하는 클로저를 가지는 sinkToResult를 추가합니다.
    func sinkToResult(_ result: @escaping (Result<Output, Failure>) -> Void) -> AnyCancellable {
        log.verbose("+")
        
        return sink(receiveCompletion: { completion in
            switch completion {
            case let .failure(error):
                result(.failure(error))
            default: break
            }
        }, receiveValue: { value in
            result(.success(value))
        })
    }
    
    // Loadable을 처리하는 클로저를 가지는 sinkToLoadable을 추가합니다.
    func sinkToLoadable(_ completion: @escaping (Loadable<Output>) -> Void) -> AnyCancellable {
        log.verbose("+")
        
        return sink(receiveCompletion: { subscriptionCompletion in
            if let error = subscriptionCompletion.error {
                completion(.failed(error))
            }
        }, receiveValue: { value in
            completion(.loaded(value))
        })
    }
    
    // 에러에서 기본 에러를 추출하는 extractUnderlyingError 함수를 추가합니다.
    func extractUnderlyingError() -> Publishers.MapError<Self, Failure> {
        log.verbose("+")
        
        return mapError {
            ($0.underlyingError as? Failure) ?? $0
        }
    }
    
    /// Holds the downstream delivery of output until the specified time interval passed after the subscription
    /// Does not hold the output if it arrives later than the time threshold
    ///
    /// - Parameters:
    ///   - interval: The minimum time interval that should elapse after the subscription.
    /// - Returns: A publisher that optionally delays delivery of elements to the downstream receiver.
    // 지정된 시간 간격이 경과한 후에만 출력을 전달하는 ensureTimeSpan 함수를 추가합니다.
    func ensureTimeSpan(_ interval: TimeInterval) -> AnyPublisher<Output, Failure> {
        log.debug("interval = \(interval)")
        
        let timer = Just<Void>(())
            .delay(for: .seconds(interval), scheduler: RunLoop.main)
            .setFailureType(to: Failure.self)
        return zip(timer)
            .map { $0.0 }
            .eraseToAnyPublisher()
    }
}

// 에러 확장으로 기본 에러를 처리합니다.
private extension Error {
    var underlyingError: Error? {
        let nsError = self as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == -1009 {
            log.debug("The Internet connection appears to be offline.")
            // "The Internet connection appears to be offline."
            return self
        }
        return nsError.userInfo[NSUnderlyingErrorKey] as? Error
    }
}

// Subscribers.Completion 확장으로 에러를 가져옵니다.
extension Subscribers.Completion {
    var error: Failure? {
        switch self {
        case let .failure(error): return error
        default: return nil
        }
    }
}
