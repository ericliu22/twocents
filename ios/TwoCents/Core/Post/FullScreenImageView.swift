//
//  FullScreenImageView.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/8.
//
import SwiftUI

struct FullScreenImageView: View {
    let selectedMedia: SelectedMedia
    let onDelete: () -> Void
    let onDismiss: () -> Void
    

        var body: some View {
            NavigationView {
                ZStack {
                    Color.white.ignoresSafeArea()
                    
                    if let uiImage = UIImage(contentsOfFile: selectedMedia.url.path) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                    } else {
                        Text("Unable to load image")
                            .foregroundColor(.white)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    // Top-leading close button
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.title2)
                        }
                        .buttonBorderShape(.circle)
                        .buttonStyle(.bordered)
                    }
                    
                    // Bottom toolbar delete button
                    ToolbarItem(placement: .bottomBar) {
                        
                        Button(action: {
                            
                        
                            onDelete()
                        }, label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Remove Image")
                            }
                            
                        })
                        
                       
                    }
                }
            }
        }
  

}
