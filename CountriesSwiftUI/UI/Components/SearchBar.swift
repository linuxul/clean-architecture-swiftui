//
//  SearchBar.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 14.01.2020.
//  Copyright © 2020 Alexey Naumov. All rights reserved.
//

import UIKit
import SwiftUI

struct SearchBar: UIViewRepresentable {

    @Binding var text: String

    func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        log.debug("+")
        
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
        log.debug("+")
        
        uiView.text = text
    }
    
    func makeCoordinator() -> SearchBar.Coordinator {
        log.debug("+")
        
        return Coordinator(text: $text)
    }
}

extension SearchBar {
    final class Coordinator: NSObject, UISearchBarDelegate {
        
        let text: Binding<String>
        
        init(text: Binding<String>) {
            log.debug("+")
            
            self.text = text
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            log.debug("+")
            
            text.wrappedValue = searchText
        }
        
        func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
            log.debug("+")
            
            searchBar.setShowsCancelButton(true, animated: true)
            return true
        }
        
        func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
            log.debug("+")
            
            searchBar.setShowsCancelButton(false, animated: true)
            return true
        }
        
        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            log.debug("+")
            
            searchBar.endEditing(true)
            searchBar.text = ""
            text.wrappedValue = ""
        }
    }
}
