//
//  CountriesInteractor.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 23.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

// CountriesInteractor 프로토콜
protocol CountriesInteractor {
    // 나라 목록을 새로고침하는 메소드
    func refreshCountriesList() -> AnyPublisher<Void, Error>
    // 나라 목록을 로드하는 메소드
    func load(countries: LoadableSubject<LazyList<Country>>, search: String, locale: Locale)
    // 특정 나라의 상세 정보를 로드하는 메소드
    func load(countryDetails: LoadableSubject<Country.Details>, country: Country)
}

// 실제로 나라 목록과 나라 상세 정보를 가져오는 인터랙터
struct RealCountriesInteractor: CountriesInteractor {
    
    // 웹 리포지토리, 데이터베이스 리포지토리, 앱 전역 상태 관리 객체
    let webRepository: CountriesWebRepository
    let dbRepository: CountriesDBRepository
    let appState: Store<AppState>
    
    init(webRepository: CountriesWebRepository, dbRepository: CountriesDBRepository, appState: Store<AppState>) {
        log.debug("+")
        
        self.webRepository = webRepository
        self.dbRepository = dbRepository
        self.appState = appState
    }

    // 나라 목록을 로드하는 메소드
    func load(countries: LoadableSubject<LazyList<Country>>, search: String, locale: Locale) {
        log.debug("+")
        
        let cancelBag = CancelBag()
        countries.wrappedValue.setIsLoading(cancelBag: cancelBag)
        
        // 데이터베이스에서 나라 목록을 로드할 수 있는지 확인한다.
        Just<Void>
            .withErrorType(Error.self)
            .flatMap { [dbRepository] _ -> AnyPublisher<Bool, Error> in
                dbRepository.hasLoadedCountries()
            }
            .flatMap { hasLoaded -> AnyPublisher<Void, Error> in
                // 나라 목록을 로드한 적이 있다면 바로 반환하고,
                // 그렇지 않으면 refreshCountriesList() 메소드를 호출하여 나라 목록을 가져온다.
                if hasLoaded {
                    return Just<Void>.withErrorType(Error.self)
                } else {
                    return self.refreshCountriesList()
                }
            }
            .flatMap { [dbRepository] in
                // 데이터베이스에서 나라 목록을 로드한다.
                dbRepository.countries(search: search, locale: locale)
            }
            .sinkToLoadable { countries.wrappedValue = $0 } // 결과를 LoadableSubject에 할당한다.
            .store(in: cancelBag)
    }
    
    // 나라 목록을 새로고침하는 메소드
    func refreshCountriesList() -> AnyPublisher<Void, Error> {
        log.debug("+")
        
        // 웹 리포지토리에서 나라 목록을 가져와 데이터베이스에 저장한다.
        return webRepository
            .loadCountries()
            .ensureTimeSpan(requestHoldBackTimeInterval)
            .flatMap { [dbRepository] in
                dbRepository.store(countries: $0)
            }
            .eraseToAnyPublisher()
    }

    // 특정 나라의 상세 정보를 로드하는 메소드
    func load(countryDetails: LoadableSubject<Country.Details>, country: Country) {
        log.debug("+")
        
        let cancelBag = CancelBag()
        countryDetails.wrappedValue.setIsLoading(cancelBag: cancelBag)

        dbRepository
            .countryDetails(country: country)
            .flatMap { details -> AnyPublisher<Country.Details?, Error> in
                // 데이터베이스에서 나라 상세 정보를 가져올 수 있다면, 그 값을 바로 반환하고,
                // 그렇지 않으면 loadAndStoreCountryDetailsFromWeb 메소드를 호출하여 웹 리포지토리에서 나라 상세 정보를 가져온다.
                if details != nil {
                    return Just<Country.Details?>.withErrorType(details, Error.self)
                } else {
                    return self.loadAndStoreCountryDetailsFromWeb(country: country)
                }
            }
            .sinkToLoadable { countryDetails.wrappedValue = $0.unwrap() }
            .store(in: cancelBag)
    }
    
    // 웹 리포지토리에서 나라 상세 정보를 가져와 데이터베이스에 저장하는 메소드
    private func loadAndStoreCountryDetailsFromWeb(country: Country) -> AnyPublisher<Country.Details?, Error> {
        log.debug("+")
        
        return webRepository
            .loadCountryDetails(country: country)
            .ensureTimeSpan(requestHoldBackTimeInterval)
            .flatMap { [dbRepository] in
                dbRepository.store(countryDetails: $0, for: country)
            }
            .eraseToAnyPublisher()
    }
    
    // 테스트 시간과 프로덕션 시간을 조절하기 위한 시간 간격 반환
    private var requestHoldBackTimeInterval: TimeInterval {
        return ProcessInfo.processInfo.isRunningTests ? 0 : 0.5
    }
}

// Stub 데이터를 사용하여 나라 목록과 나라 상세 정보를 가져오는 인터랙터
struct StubCountriesInteractor: CountriesInteractor {
    
    // 나라 목록을 새로고침하는 메소드
    func refreshCountriesList() -> AnyPublisher<Void, Error> {
        log.debug("+")
        
        return Just<Void>.withErrorType(Error.self)
    }
    
    // 나라 목록을 로드하는 메소드
    func load(countries: LoadableSubject<LazyList<Country>>, search: String, locale: Locale) {
        log.debug("+")
        
    }
    
    // 특정 나라의 상세 정보를 로드하는 메소드
    func load(countryDetails: LoadableSubject<Country.Details>, country: Country) {
        log.debug("+")
        
    }
}
