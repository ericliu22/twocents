//
//  LinkView.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/17.
//
import TwoCentsInternal
import SwiftUI
import LinkPresentation

struct LinkView: PostView {
    
    let post: Post
    @State var link: LinkDownload?
    
    init(post: Post) {
        self.post = post
    }
    
    var body: some View {
        Group {
            if let link {
                if let url = URL(string: link.mediaUrl) {
                    LinkPreview(url: url)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            // Fetch media data asynchronously
            guard let data = try? await PostManager.getMedia(post: post) else {
                return
            }
            let links = try? JSONDecoder().decode([LinkDownload].self, from: data)
            // Ensure state updates are performed on the main thread.
            await MainActor.run {
                link = links?.first
            }
        }
    }
}

// Mark the UIViewRepresentable as @MainActor to guarantee its methods run on the main thread.
@MainActor
struct LinkPresentationView: UIViewRepresentable {
    var previewURL: URL

    func makeUIView(context: Context) -> UIView {
        // Create a container view
        let containerView = UIView()
        containerView.backgroundColor = .clear

        // Create the LPLinkView with the preview URL
        let linkView = LPLinkView(url: previewURL)
        linkView.translatesAutoresizingMaskIntoConstraints = false

        // Add LPLinkView to the container
        containerView.addSubview(linkView)

        // Pin linkView to all edges of containerView
        NSLayoutConstraint.activate([
            linkView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            linkView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            linkView.topAnchor.constraint(equalTo: containerView.topAnchor),
            linkView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        // Fetch metadata and update the link view without sizeToFit
        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: previewURL) { (metadata, error) in
            Task { @MainActor in
                guard let metadata = metadata, error == nil else { return }
                linkView.metadata = metadata
                // Invalidate and re-evaluate the layout on the main actor.
                linkView.setNeedsLayout()
                linkView.layoutIfNeeded()
                // Optionally, if you need to capture the new size:
                let newSize = linkView.intrinsicContentSize
                // You can then update a SwiftUI state or binding if required.
            }
        }

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // No update logic needed in this case.
    }
}


struct LinkPreview: View {
    let url: URL

    var body: some View {
        VStack {
            LinkPresentationView(previewURL: url)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
    }

}
