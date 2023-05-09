//
//  LazyList.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 18.04.2020.
//  Copyright © 2020 Alexey Naumov. All rights reserved.
//

import Foundation

// LazyList는 성능 최적화를 위해 원소에 대한 접근을 최소화하고 선택적으로 캐싱을 사용하는 컬렉션입니다.
struct LazyList<T> {
    
    // Access 클로저는 해당 인덱스의 원소에 대한 접근을 제공합니다.
    typealias Access = (Int) throws -> T?
    private let access: Access
    private let useCache: Bool
    private var cache = Cache()
    
    let count: Int
    
    // 초기화 메서드에서는 원소 개수, 캐시 사용 여부, 및 접근 클로저를 전달받습니다.
    init(count: Int, useCache: Bool, _ access: @escaping Access) {
        log.debug("+")
        
        self.count = count
        self.useCache = useCache
        self.access = access
    }
    
    // 지정한 인덱스의 원소를 가져옵니다. 캐시를 사용하면 캐시된 값을 반환하고, 그렇지 않으면 access 클로저를 호출하여 원소를 가져옵니다.
    func element(at index: Int) throws -> T {
        log.debug("+")
        
        guard useCache else {
            return try get(at: index)
        }
        return try cache.sync { elements in
            if let element = elements[index] {
                return element
            }
            let element = try get(at: index)
            elements[index] = element
            return element
        }
    }
    
    // 지정한 인덱스의 원소를 가져옵니다. access 클로저를 호출하여 원소를 가져옵니다.
    private func get(at index: Int) throws -> T {
        log.debug("+")
        
        guard let element = try access(index) else {
            throw Error.elementIsNil(index: index)
        }
        return element
    }
    
    // 비어 있는 LazyList를 생성합니다.
    static var empty: Self {
        return .init(count: 0, useCache: false) { index in
            throw Error.elementIsNil(index: index)
        }
    }
}

// Cache 클래스는 캐시된 원소를 저장하고 동기화된 방식으로 접근을 관리합니다.
private extension LazyList {
    class Cache {
        
        private var elements = [Int: T]()
        
        func sync(_ access: (inout [Int: T]) throws -> T) throws -> T {
            log.debug("+")
            
            guard Thread.isMainThread else {
                var result: T!
                try DispatchQueue.main.sync {
                    result = try access(&elements)
                }
                return result
            }
            return try access(&elements)
        }
    }
}

// LazyList를 Sequence 프로토콜을 따르도록 확장합니다.
extension LazyList: Sequence {
    
    // 원소가 nil인 경우 발생하는 에러를 정의합니다.
    enum Error: LocalizedError {
        case elementIsNil(index: Int)
        
        var localizedDescription: String {
            switch self {
            case let .elementIsNil(index):
                return "Element at index \(index) is nil"
            }
        }
    }
    
    // LazyList의 Iterator를 정의합니다.
    struct Iterator: IteratorProtocol {
        typealias Element = T
        private var index = -1
        // list는 순회할 LazyList를 참조합니다.
        private var list: LazyList<Element>
        
        // Iterator를 초기화할 때, 순회할 LazyList를 전달받습니다.
        init(list: LazyList<Element>) {
            self.list = list
        }
        
        // 다음 원소를 반환하거나, 순회가 끝났을 경우 nil을 반환합니다.
        mutating func next() -> Element? {
            log.debug("+")
            
            index += 1
            guard index < list.count else {
                return nil
            }
            do {
                return try list.element(at: index)
            } catch _ {
                return nil
            }
        }
    }
    
    // LazyList의 Iterator를 생성합니다.
    func makeIterator() -> Iterator {
        log.debug("+")
        
        return .init(list: self)
    }
    
    // 원소 개수에 대한 추정값을 반환합니다.
    var underestimatedCount: Int { count }
}

// LazyList를 RandomAccessCollection 프로토콜을 따르도록 확장합니다.
extension LazyList: RandomAccessCollection {
    
    typealias Index = Int
    var startIndex: Index { 0 }
    var endIndex: Index { count }
    
    // 지정한 인덱스의 원소를 반환하거나 에러가 발생하면 앱을 종료합니다.
    subscript(index: Index) -> Iterator.Element {
        log.debug("+")
        
        do {
            return try element(at: index)
        } catch let error {
            fatalError("\(error)")
        }
    }
    
    // 주어진 인덱스의 다음 인덱스를 반환합니다.
    public func index(after index: Index) -> Index {
        log.debug("+")
        
        return index + 1
    }
    
    // 주어진 인덱스의 이전 인덱스를 반환합니다.
    public func index(before index: Index) -> Index {
        log.debug("+")
        
        return index - 1
    }
}

// LazyList를 Equatable 프로토콜을 따르도록 확장합니다.
extension LazyList: Equatable where T: Equatable {
    static func == (lhs: LazyList<T>, rhs: LazyList<T>) -> Bool {
        log.debug("+")
        
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).first(where: { $0 != $1 }) == nil
    }
}

// LazyList를 CustomStringConvertible 프로토콜을 따르도록 확장합니다.
extension LazyList: CustomStringConvertible {
    var description: String {
        let elements = self.reduce("", { str, element in
            if str.count == 0 {
                return "\(element)"
            }
            return str + ", \(element)"
        })
        return "LazyList<[\(elements)]>"
    }
}

// RandomAccessCollection에 lazyList 속성을 추가하여 현재 컬렉션을 LazyList로 반환합니다.
extension RandomAccessCollection {
    var lazyList: LazyList<Element> {
        return .init(count: self.count, useCache: false) {
            guard $0 < self.count else { return nil }
            let index = self.index(self.startIndex, offsetBy: $0)
            return self[index]
        }
    }
}
