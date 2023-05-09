//
//  DependencyInjector.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 28.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import SwiftUI
import Combine

// MARK: - DIContainer
/*
 위 코드는 SwiftUI 프로젝트에서 의존성 주입(Dependency Injection)을 위한 코드입니다.
 
 `DIContainer` 구조체는 `EnvironmentKey`를 채택하여 `EnvironmentValues`에 주입될 수 있도록 합니다.
 `appState`는 앱 전역의 상태를 관리하는 `Store` 객체이고, `interactors`는 앱의 인터랙터(Interactor) 객체를 담고 있는 구조체입니다.
 
 `init` 메소드는 `appState`와 `interactors`를 매개변수로 받아 초기화합니다.
 이때 `appState`를 `Store`로 감싸주는 이유는, `Store`는 불변성을 유지하기 때문입니다.
 즉, `Store` 객체에 값을 할당하려면 해당 `Store` 객체를 복제한 뒤 값을 할당해야 합니다.
 
 `EnvironmentValues`의 `injected` 프로퍼티는 `DIContainer`를 반환하고,
 `inject` 메소드는 `appState`와 `interactors`를 받아 `DIContainer` 객체를 생성한 뒤 `inject` 메소드를 호출합니다.
 `inject` 메소드는 `RootViewAppearance` 뷰 모디파이어를 추가하고, `EnvironmentValues`에 `DIContainer`를 주입합니다.
 
 마지막으로 `DIContainer` 구조체의 `preview` 프로퍼티는 미리보기(Preview) 기능에서 사용됩니다.
 미리보기에서는 `AppState.preview` 값을 가지는 `AppState` 객체와
 `Interactors.stub` 값을 가지는 `Interactors` 객체를 사용하여 `DIContainer` 객체를 생성합니다.
 
 이렇게 주입된 `DIContainer` 객체를 통해 뷰의 상태 및 인터랙터 객체에 접근할 수 있으며, 이를 통해 의존성을 관리할 수 있습니다.
 */

// EnvironmentKey 프로토콜을 채택하여 EnvironmentValues에 주입될 수 있도록 하는 DIContainer 구조체
struct DIContainer: EnvironmentKey {
    
    // 앱의 전역 상태를 관리하는 Store 객체와 인터랙터 객체를 담는 구조체
    let appState: Store<AppState>
    let interactors: Interactors
    
    // 주어진 매개변수로 DIContainer 객체를 초기화하는 initializer
    init(appState: Store<AppState>, interactors: Interactors) {
        log.debug("+")
        
        self.appState = appState
        self.interactors = interactors
    }
    
    // 주어진 매개변수로 Store 객체를 초기화하는 initializer
    // appState를 Store로 감싸주는 이유는 불변성을 유지하기 위해서이다.
    init(appState: AppState, interactors: Interactors) {
        log.debug("+")
        
        self.init(appState: Store<AppState>(appState), interactors: interactors)
    }
    
    // EnvironmentValues의 defaultValue로 사용할 DIContainer 객체를 반환
    static var defaultValue: Self { Self.default }
    
    // DIContainer의 기본값으로 사용할 DIContainer 객체
    private static let `default` = Self(appState: AppState(), interactors: .stub)
}

// EnvironmentValues에 DIContainer를 주입하기 위한 프로퍼티
extension EnvironmentValues {
    var injected: DIContainer {
        get { self[DIContainer.self] }
        set { self[DIContainer.self] = newValue }
    }
}

#if DEBUG
// 미리보기 기능에서 사용될 DIContainer를 반환하는 프로퍼티
extension DIContainer {
    static var preview: Self {
        .init(appState: .init(AppState.preview), interactors: .stub)
    }
}
#endif

// MARK: - Injection in the view hierarchy
// 뷰 계층구조에서 DIContainer를 주입하기 위한 extension
extension View {
    
    // 주어진 appState와 interactors를 사용하여 DIContainer를 생성하고 주입하는 메소드
    func inject(_ appState: AppState,
                _ interactors: DIContainer.Interactors) -> some View {
        log.debug("+")
        
        let container = DIContainer(appState: .init(appState),
                                    interactors: interactors)
        return inject(container)
    }
    
    // 주어진 DIContainer를 사용하여 EnvironmentValues에 DIContainer를 주입하는 메소드
    func inject(_ container: DIContainer) -> some View {
        log.debug("+")
        
        return self
            .modifier(RootViewAppearance())
            .environment(\.injected, container)
    }
}
