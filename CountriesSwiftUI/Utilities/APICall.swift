//
//  APICall.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 23.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import Foundation

// APICall 프로토콜은 API 요청에 필요한 정보를 정의합니다.
protocol APICall {
    var path: String { get }
    var method: String { get }
    var headers: [String: String]? { get }
    func body() throws -> Data?
}

// APIError 열거형은 API 호출에서 발생할 수 있는 오류 유형을 정의합니다.
enum APIError: Swift.Error {
    case invalidURL
    case httpCode(HTTPCode)
    case unexpectedResponse
    case imageDeserialization
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case let .httpCode(code): return "Unexpected HTTP code: \(code)"
        case .unexpectedResponse: return "Unexpected response from the server"
        case .imageDeserialization: return "Cannot deserialize image from Data"
        }
    }
}

// APICall 프로토콜의 URLRequest를 생성하는 기능을 추가합니다.
extension APICall {
    // 경로를 기반으로 URL을 생성하고, 유효하지 않은 경우 APIError.invalidURL를 throw합니다.
    func urlRequest(baseURL: String) throws -> URLRequest {
        log.verbose("+")
        
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        // URLRequest를 생성하고 설정합니다.
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers
        request.httpBody = try body()
        return request
    }
}

typealias HTTPCode = Int
typealias HTTPCodes = Range<HTTPCode>

// HTTPCodes를 확장하여 성공하는 HTTP 응답 코드 범위를 정의합니다.
extension HTTPCodes {
    static let success = 200 ..< 300
}
