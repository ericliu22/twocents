//
//  TextView.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/17.
//
import SwiftUI
import TwoCentsInternal

struct TextView: PostView {
    
    let post: PostWithMedia
    @State var text: TextDownload?
    
    init(post: PostWithMedia) {
        self.post = post
        let texts = post.download as? [TextDownload]
        text = texts?.first
        lines = text?.text.components(separatedBy: .newlines)
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
    }
}
