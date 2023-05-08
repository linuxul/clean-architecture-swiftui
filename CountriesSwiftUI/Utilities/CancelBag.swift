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
    
    func cancel() {
        log.debug("+")
        subscriptions.removeAll()
    }
}

extension AnyCancellable {
    
    func store(in cancelBag: CancelBag) {
        log.debug("+")
        cancelBag.subscriptions.insert(self)
    }
}
