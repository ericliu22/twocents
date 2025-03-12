//
//  ShareExtensionView.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/11.
//
import SwiftUI

struct ShareExtensionView: View {
    
    @State var viewModel: ShareExtensionViewModel
    
    init(items: [NSExtensionItem]) {
        self.viewModel = ShareExtensionViewModel(items: items)
    }
    
    var body: some View {
        Button {
            
            viewModel.close()
        } label: {
            Text("Post")
        }
    }
    
}
