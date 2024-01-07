//
//  CountriesList.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 24.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import SwiftUI
import Combine

struct CountriesList: View {
    
    @ObservedObject private(set) var viewModel: ViewModel
    @Environment(\.locale) private var locale: Locale
    let inspection = Inspection<Self>()
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                self.content
                    .navigationBarItems(trailing: self.permissionsButton)
                    .navigationBarTitle("Countries")
                    .navigationBarHidden(self.viewModel.countriesSearch.keyboardHeight > 0)
                    .animation(.easeOut(duration: 0.3))
            }
            .navigationViewStyle(DoubleColumnNavigationViewStyle())
        }
        .modifier(viewModel.localeReader)
        .onReceive(inspection.notice) { self.inspection.visit(self, $0) }
    }
    
    @ViewBuilder private var content: some View {
        switch viewModel.countries {
        case .notRequested:
            notRequestedView
        case let .isLoading(last, _):
            loadingView(last)
        case let .loaded(countries):
            loadedView(countries, showSearch: true, showLoading: false)
        case let .failed(error):
            failedView(error)
        }
    }
    
    private var permissionsButton: some View {
        Group {
            if viewModel.canRequestPushPermission {
                Button(action: viewModel.requestPushPermission, label: { Text("Allow Push") })
            } else {
                EmptyView()
            }
        }
    }
}

// MARK: - Loading Content

private extension CountriesList {
    var notRequestedView: some View {
        log.verbose("+")
        
        return Text("").onAppear(perform: self.viewModel.reloadCountries)
    }
    
    func loadingView(_ previouslyLoaded: LazyList<Country>?) -> some View {
        log.debug("previouslyLoaded = \(String(describing: previouslyLoaded))")
        
        if let countries = previouslyLoaded {
            return AnyView(loadedView(countries, showSearch: true, showLoading: true))
        } else {
            return AnyView(ActivityIndicatorView().padding())
        }
    }
    
    func failedView(_ error: Error) -> some View {
        return ErrorView(error: error, retryAction: {
            log.verbose("+")
            
            self.viewModel.reloadCountries()
        })
    }
}

// MARK: - Displaying Content

private extension CountriesList {
    func loadedView(_ countries: LazyList<Country>, showSearch: Bool, showLoading: Bool) -> some View {
        log.debug("countries = \(String(describing: countries))")
        
        return VStack {
            if showSearch {
                SearchBar(text: $viewModel.countriesSearch.searchText.onSet({ _ in
                    self.viewModel.reloadCountries()
                }))
            }
            if showLoading {
                ActivityIndicatorView().padding()
            }
            List(countries) { country in
                NavigationLink(
                    destination: self.detailsView(country: country),
                    tag: country.alpha3Code,
                    selection: self.$viewModel.routingState.countryDetails) {
                        CountryCell(country: country)
                    }
            }
        }.padding(.bottom, bottomInset)
    }
    
    func detailsView(country: Country) -> some View {
        log.debug("country = \(String(describing: country))")
        
        return CountryDetails(viewModel: .init(container: viewModel.container, country: country))
    }
    
    var bottomInset: CGFloat {
        if #available(iOS 14, *) {
            return 0
        } else {
            return self.viewModel.countriesSearch.keyboardHeight
        }
    }
}

// MARK: - Preview

#if DEBUG
struct CountriesList_Previews: PreviewProvider {
    static var previews: some View {
        CountriesList(viewModel: .init(container: .preview))
    }
}
#endif
