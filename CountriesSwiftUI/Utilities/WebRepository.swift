//
//  WebRepository.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 23.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import Foundation
import Combine

// WebRepository 프로토콜은 웹 서비스를 사용하기 위한 인터페이스를 정의합니다.
protocol WebRepository {
    var session: URLSession { get }
    var baseURL: String { get }
    var bgQueue: DispatchQueue { get }
}

extension WebRepository {
    // call 함수는 주어진 API 엔드포인트를 호출하고 Decodable 응답을 반환합니다.
    func call<Value>(endpoint: APICall, httpCodes: HTTPCodes = .success) -> AnyPublisher<Value, Error>
    where Value: Decodable {
        log.debug("+")
        
        do {
            // API 호출에 대한 URLRequest를 생성합니다.
            let request = try endpoint.urlRequest(baseURL: baseURL)
            // URLSession의 dataTaskPublisher를 사용하여 API 요청을 실행하고 JSON 응답을 처리합니다.
            log.debug("request = \(request)")
            return session
                .dataTaskPublisher(for: request)
                .requestJSON(httpCodes: httpCodes)
        } catch let error {
            return Fail<Value, Error>(error: error).eraseToAnyPublisher()
        }
    }
}

// MARK: - Helpers

extension Publisher where Output == URLSession.DataTaskPublisher.Output {
    // requestData는 주어진 HTTP 응답 코드 범위 내의 데이터를 반환하는 AnyPublisher를 생성합니다.
    func requestData(httpCodes: HTTPCodes = .success) -> AnyPublisher<Data, Error> {
        log.debug("+")
        
        return tryMap {
            assert(!Thread.isMainThread)
            // HTTPURLResponse에서 응답 코드를 가져옵니다.
            guard let code = ($0.1 as? HTTPURLResponse)?.statusCode else {
                throw APIError.unexpectedResponse
            }
            // HTTP 응답 코드가 지정된 범위에 포함되어 있는지 확인합니다.
            guard httpCodes.contains(code) else {
                throw APIError.httpCode(code)
            }
            
            log.debug("$0 = \($0)")
            return $0.0
        }
        .extractUnderlyingError()
        .eraseToAnyPublisher()
    }
}

// URLSession.DataTaskPublisher.Output 출력을 가지는 Publisher에 대한 private 확장입니다.
private extension Publisher where Output == URLSession.DataTaskPublisher.Output {
    // requestJSON 함수는 requestData를 사용하여 데이터를 가져온 후, JSONDecoder를 사용하여 해당 데이터를 Decodable 객체로 변환합니다.
    func requestJSON<Value>(httpCodes: HTTPCodes) -> AnyPublisher<Value, Error> where Value: Decodable {
        log.debug("+")
        
        return requestData(httpCodes: httpCodes)
            .decode(type: Value.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
