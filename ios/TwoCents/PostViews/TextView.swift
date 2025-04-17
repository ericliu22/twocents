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
    var lines: [String]? {
        let texts = post.download as? [TextDownload]
        let text = texts?.first
        return text?.text.components(separatedBy: .newlines)
    }
    
    init(post: PostWithMedia) {
        self.post = post
    }
    
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
