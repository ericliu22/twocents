import PhotosUI
//
//  PostTest.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/3.
//
import SwiftUI

struct PostTest: View {
    @State var loading: Bool = false
    @State var selectedPhoto: PhotosPickerItem?
    @State var latestImage: UIImage?
    @State var mediaUrl: URL?
    @State var caption: String?

    var body: some View {
        VStack {

            Group {
                if loading {
                    ProgressView()
                        .progressViewStyle(
                            CircularProgressViewStyle(tint: .primary)
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .background(.thinMaterial)
                        .cornerRadius(20)

                } else {
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .any(of: [.images]),
                        photoLibrary: .shared()
                    ) {
                        ZStack {
                            if let image = latestImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(
                                        width: 250,
                                        height: 250
                                    )
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 20))
                            } else {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.thinMaterial)
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }
                }
            }
            
            if let mediaUrl {
                AsyncImage(url: mediaUrl)
                    .scaledToFill()
                    .frame(
                        width: 250,
                        height: 250
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 20))
            }
                

            Button {
                Task {
                    do {
                        guard let data = try await selectedPhoto?.loadTransferable(type: Data.self) else { return }
                        let imageData = try await PostManager.uploadMediaPost(media: .IMAGE, data: data, caption: "Hello World")
                        let image: ImageDownload = try JSONDecoder().decode(ImageDownload.self, from: imageData)
                        mediaUrl = URL(string: image.mediaUrl)
                    } catch let error {
                        print(error)
                    }
                }
            } label: {
                Text("Upload")
            }

        }
    }
}
