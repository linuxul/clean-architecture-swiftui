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
        log.debug("context = \(context)")
        
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        return searchBar
    }
    
    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
        log.debug("uiView = \(uiView), context = \(context)")
        
        uiView.text = text
    }
    
    func makeCoordinator() -> SearchBar.Coordinator {
        log.verbose("+")
        
        return Coordinator(text: $text)
    }
}

extension SearchBar {
    final class Coordinator: NSObject, UISearchBarDelegate {
        
        let text: Binding<String>
        
        init(text: Binding<String>) {
            log.debug("text = \(text)")
            
            self.text = text
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            log.debug("searchBar = \(searchBar), searchText = \(searchText)")
            
            text.wrappedValue = searchText
        }
        
        func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
            log.debug("searchBar = \(searchBar)")
            
            searchBar.setShowsCancelButton(true, animated: true)
            return true
        }
        
        func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
            log.debug("searchBar = \(searchBar)")
            
            searchBar.setShowsCancelButton(false, animated: true)
            return true
        }
        
        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            log.debug("searchBar = \(searchBar)")
            
            searchBar.endEditing(true)
            searchBar.text = ""
            text.wrappedValue = ""
        }
    }
}
