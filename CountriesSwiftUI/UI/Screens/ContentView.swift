//
//  ContentView.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 23.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import SwiftUI
import Combine
import EnvironmentOverrides

struct ContentView: View {
    
    private let container: DIContainer
    private let isRunningTests: Bool
    
    init(container: DIContainer, isRunningTests: Bool = ProcessInfo.processInfo.isRunningTests) {
        log.debug("+")
        
        self.container = container
        self.isRunningTests = isRunningTests
    }
    
    var body: some View {
        Group {
            if isRunningTests {
                Text("Running unit tests")
            } else {
                CountriesList()
                    .attachEnvironmentOverrides(onChange: onChangeHandler)
                    .inject(container)
            }
        }
    }
    
    var onChangeHandler: (EnvironmentValues.Diff) -> Void {
        log.debug("+")
        
        return { diff in
            if !diff.isDisjoint(with: [.locale, .sizeCategory]) {
                self.container.appState[\.routing] = AppState.ViewRouting()
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(container: .preview)
    }
}
#endif
