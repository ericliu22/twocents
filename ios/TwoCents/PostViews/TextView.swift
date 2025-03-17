//
//  TextView.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/17.
//
import SwiftUI
import TwoCentsInternal

struct TextView: PostView {
    
    let post: Post
    @State var text: TextDownload?
    
    init(post: Post) {
        self.post = post
    }
    
    var body: some View {
        Group {
            if let text {
                Text(text.text)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView().progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            guard let data = try? await PostManager.getMedia(post: post) else {
                return
            }
            let texts = try? JSONDecoder().decode([TextDownload].self, from: data)
            text = texts?.first
        }
    }
}
