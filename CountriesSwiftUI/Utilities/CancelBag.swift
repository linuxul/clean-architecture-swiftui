//
//  CancelBag.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 04.04.2020.
//  Copyright © 2020 Alexey Naumov. All rights reserved.
//

import Combine

final class CancelBag {
    fileprivate(set) var subscriptions = Set<AnyCancellable>()
    private let equalToAny: Bool
    
    init(equalToAny: Bool = false) {
        log.debug("equalToAny = \(equalToAny)")
        self.equalToAny = equalToAny
    }
    
    func isEqual(to other: CancelBag) -> Bool {
        log.debug("other = \(other)")
        return other === self || other.equalToAny || self.equalToAny
    }
    
    func cancel() {
        log.verbose("+")
        subscriptions.removeAll()
    }
    
    func collect(@Builder _ cancellables: () -> [AnyCancellable]) {
        log.verbose("+")
        subscriptions.formUnion(cancellables())
    }

    @resultBuilder
    struct Builder {
        static func buildBlock(_ cancellables: AnyCancellable...) -> [AnyCancellable] {
            log.verbose("cancellables = \(cancellables)")
            return cancellables
        }
    }
}

extension AnyCancellable {
    
    func store(in cancelBag: CancelBag) {
        log.verbose("cancelBag = \(cancelBag)")
        cancelBag.subscriptions.insert(self)
    }
}
