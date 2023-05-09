//
//  DIContainer.Interactors.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 24.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

// DIContainer의 Interactors 부분을 확장합니다.
extension DIContainer {
    // Interactors 구조체를 정의합니다.
    // 이 구조체에는 국가, 이미지, 사용자 권한 상호작용자가 포함됩니다.
    struct Interactors {
        let countriesInteractor: CountriesInteractor
        let imagesInteractor: ImagesInteractor
        let userPermissionsInteractor: UserPermissionsInteractor
        
        // 생성자를 정의합니다.
        // 각 상호작용자를 초기화하고 구조체의 속성에 할당합니다.
        init(countriesInteractor: CountriesInteractor,
             imagesInteractor: ImagesInteractor,
             userPermissionsInteractor: UserPermissionsInteractor) {
            log.debug("+")
            
            self.countriesInteractor = countriesInteractor
            self.imagesInteractor = imagesInteractor
            self.userPermissionsInteractor = userPermissionsInteractor
        }
        
        // 스텁(Stub) 인터랙터를 정의합니다.
        // 테스트 및 미리보기에 사용되는 가짜 인터랙터를 제공합니다.
        static var stub: Self {
            .init(countriesInteractor: StubCountriesInteractor(),
                  imagesInteractor: StubImagesInteractor(),
                  userPermissionsInteractor: StubUserPermissionsInteractor())
        }
    }
}
