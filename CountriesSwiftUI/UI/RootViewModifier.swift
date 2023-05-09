//
//  RootViewModifier.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 09.11.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//
/*
 RootViewAppearance은 SwiftUI의 ViewModifier 프로토콜을 구현하는 구조체입니다.
 이 구조체는 뷰를 가리는 흐림(blur) 효과를 적용하고, Safe Area를 무시하도록 설정합니다.
 또한 appState에서 system.isActive 속성을 구독하여 isActive 상태를 업데이트합니다.
 
 stateUpdate 변수는 injected.appState에서 system.isActive 속성을 구독하여, 해당 속성이 변경될 때마다 Bool 값을 방출하는 AnyPublisher를 생성합니다.
 isActive 상태를 업데이트하는 데 사용됩니다.
 
 inspection 속성은 SwiftUI 라이브러리에서 제공하는 Inspection 객체입니다.
 이 객체를 사용하여 View 검사를 수행하고, View의 내부 상태를 테스트할 수 있습니다.
 
 RootViewAppearance 구조체는 SwiftUI의 뷰 수정자(View Modifier)를 구현하는 데 사용됩니다.
 이 구조체를 뷰에 적용하면, 해당 뷰가 가려진 흐림(blur) 효과와 Safe Area를 무시하는 효과를 가지게 됩니다.
 */
import SwiftUI
import Combine

// MARK: - RootViewAppearance
// ViewModifier 구조체 정의
struct RootViewAppearance: ViewModifier {
    
    // DIContainer에서 appState 속성을 가져와서 injected에 할당합니다.
    @Environment(\.injected) private var injected: DIContainer
    // RootView가 활성화된 경우 true, 비활성화된 경우 false를 나타내는 상태 속성입니다.
    @State private var isActive: Bool = false
    // View 검사를 수행하는 데 사용되는 Inspection 객체입니다.
    internal let inspection = Inspection<Self>()
    
    func body(content: Content) -> some View {
        // ViewModifier가 적용될 View의 body 함수입니다.
        
        content
            .blur(radius: isActive ? 0 : 10)    // isActive이 true이면 blur 효과를 제거하고, false이면 10의 blur radius를 가진 효과를 적용합니다.
            .ignoresSafeArea()                  // Safe Area를 무시하도록 합니다.
            .onReceive(stateUpdate) { self.isActive = $0 }      // appState의 isActive 속성이 변경될 때마다 isActive 값을 업데이트합니다.
            .onReceive(inspection.notice) { self.inspection.visit(self, $0) }   // Inspection 객체가 View 검사를 수행합니다.
    }
    
    // appState에서 system.isActive 속성이 변경될 때마다 Bool 값을 방출하는 AnyPublisher를 생성합니다.
    private var stateUpdate: AnyPublisher<Bool, Never> {
        injected.appState.updates(for: \.system.isActive)
    }
}
