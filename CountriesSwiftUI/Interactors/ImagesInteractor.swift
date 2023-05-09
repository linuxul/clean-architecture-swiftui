//
//  ImagesInteractor.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 09.11.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

// 이미지 로딩과 관련된 인터랙션 프로토콜
protocol ImagesInteractor {
    func load(image: LoadableSubject<UIImage>, url: URL?)
}

// 실제 웹 리포지토리를 사용하여 이미지를 로드하는 인터랙터
struct RealImagesInteractor: ImagesInteractor {
    
    let webRepository: ImageWebRepository
    
    init(webRepository: ImageWebRepository) {
        log.debug("+")
        
        self.webRepository = webRepository
    }
    
    // 이미지 로드를 시작하는 메소드
    func load(image: LoadableSubject<UIImage>, url: URL?) {
        log.debug("+")
        
        // URL이 유효하지 않은 경우 notRequested 상태로 설정
        guard let url = url else {
            image.wrappedValue = .notRequested; return
        }
        let cancelBag = CancelBag()
        image.wrappedValue.setIsLoading(cancelBag: cancelBag)
        webRepository.load(imageURL: url)
            .sinkToLoadable {
                // LoadableSubject에 결과 할당
                image.wrappedValue = $0
            }
            .store(in: cancelBag)
    }
}

// 이미지 인터랙터의 스텁 구현. 이미지를 로드하지 않고 메서드 호출만 기록함.
struct StubImagesInteractor: ImagesInteractor {
    func load(image: LoadableSubject<UIImage>, url: URL?) {
        log.debug("+")
        
    }
}
