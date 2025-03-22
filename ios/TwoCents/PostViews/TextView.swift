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
    @State var lines: [String]?
    var body: some View {
        Group {
            if let lines {
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading) {
                        ForEach(lines, id: \.self) { line in
                            Text(line)
                                .padding(.vertical, 2)
                        }
                    }
                }
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
            lines = text?.text.components(separatedBy: .newlines)
        }
    }
}
