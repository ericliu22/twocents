import MobileCoreServices
import Social
import TwoCentsInternal
import UIKit
import UniformTypeIdentifiers
import FirebaseCore
import FirebaseAuth

// MARK: – Constants  ────────────────────────────────────────────────

let APP_GROUP       = "432WVK3797.com.twocentsapp.newcents.keychain-group"


var HARDCODED_DATE: Date {
    var dateComponents = DateComponents()
    dateComponents.year = 2025
    dateComponents.month = 3
    dateComponents.day = 8
    return Calendar.current.date(from: dateComponents)!
}

let env = ProcessInfo.processInfo.environment["ENVIRONMENT"] ?? "PRODUCTION"

let HARDCODED_GROUP: FriendGroup = {
    switch env.uppercased() {
      case "DEBUG":
        return FriendGroup(id: UUID(uuidString: "e16269de-b7a5-4916-8689-35e5787ad028")!, name: "Dev", dateCreated: HARDCODED_DATE, ownerId: UUID(uuidString: "bb444367-e219-41e0-bfe5-ccc2038d0492")!)
      case "PRODUCTION":
        return FriendGroup(id: UUID(uuidString: "b343342a-d41b-4c79-a8a8-7e0b142be6da")!, name: "TwoCents", dateCreated: HARDCODED_DATE, ownerId: UUID(uuidString: "bb444367-e219-41e0-bfe5-ccc2038d0492")!)
      default:
        return FriendGroup(id: UUID(uuidString: "b343342a-d41b-4c79-a8a8-7e0b142be6da")!, name: "TwoCents", dateCreated: HARDCODED_DATE, ownerId: UUID(uuidString: "bb444367-e219-41e0-bfe5-ccc2038d0492")!)
    }
}()

// MARK: – Share extension VC  ───────────────────────────────────────

class ShareViewController: SLComposeServiceViewController {

    private var sharedItems: [Any] = []

    // ───────────────────────────────────────────────────────────────

    override func viewDidLoad() {
        super.viewDidLoad()

        FirebaseApp.configure()
        try? Auth.auth().useUserAccessGroup(APP_GROUP)

        // Collect attachments (images, videos, text, links).
        if let items = extensionContext?.inputItems as? [NSExtensionItem] {
            let group = DispatchGroup()
            for item in items {
                item.attachments?.forEach { provider in
                    loadItem(of: provider, group: group)
                }
            }
            group.notify(queue: .main) { /* enable Post button if needed */ }
        }
    }

    // MARK: – Posting logic  ────────────────────────────────────────

    override func didSelectPost() {
        Task {
            defer {
                extensionContext?.completeRequest(returningItems: nil,
                                                  completionHandler: nil)
            }

            guard let first = sharedItems.first else { return }

            // 1️⃣   Detect media + build request.
            let media: Media = classify(item: first)
            let caption = contentText
            let postReq = PostRequest(media: media,
                                      caption: caption,
                                      groups: [HARDCODED_GROUP.id])

            // 2️⃣   Build *one* secondary payload part.
            let payload = try buildPayload(for: media)

            // 3️⃣   Fire single multipart request.
            do {
                _ = try await PostManager.createPostMultipart(request: postReq,
                                                              payload: payload)
            } catch {
                print("❌ Share upload failed:", error)
            }
        }
    }

    // MARK: – Helpers  ──────────────────────────────────────────────

    private func classify(item: Any) -> Media {
        switch item {
        case is UIImage: return .IMAGE
        case is String:  return .TEXT
        case let url as URL:
            let videoExt = ["mov", "mp4", "m4v"]
            return videoExt.contains(url.pathExtension.lowercased()) ? .VIDEO : .LINK
        default:        return .OTHER
        }
    }

    /// Converts `sharedItems` → `PostPayload` understood by the backend.
    private func buildPayload(for media: Media) throws -> PostPayload {
        switch media {

        case .IMAGE:
            guard
                let image = sharedItems.first(where: { $0 is UIImage }) as? UIImage,
                let data  = image.jpegData(compressionQuality: 0.95)
            else { return .none }
            return .file(data: data,
                         mimeType: "image/jpeg",
                         filename: "share.jpg")

        case .VIDEO:
            guard
                let url  = sharedItems.first(where: { $0 is URL }) as? URL,
                let data = try? Data(contentsOf: url)
            else { return .none }
            return .file(data: data,
                         mimeType: "video/mp4",
                         filename: url.lastPathComponent)

        case .LINK:
            guard
                let url = sharedItems.first(where: { $0 is URL }) as? URL
            else { return .none }
            let json = try TwoCentsEncoder().encode(["mediaUrl": url.absoluteString])
            return .json(json)

        case .TEXT:
            guard
                let text = sharedItems.first(where: { $0 is String }) as? String
            else { return .none }
            let json = try TwoCentsEncoder().encode(["text": text])
            return .json(json)

        case .OTHER:
            return .none
        }
    }

    // MARK: – Attachment loading  ──────────────────────────────────

    private func loadItem(of provider: NSItemProvider, group: DispatchGroup) {
        func load(_ utType: UTType) {
            group.enter()
            provider.loadItem(forTypeIdentifier: utType.identifier,
                              options: nil) { data, error in
                defer { group.leave() }
                switch (data, utType) {
                case (let url as URL, .image),
                     (let url as URL, .movie):
                    if let image = UIImage(contentsOfFile: url.path) {
                        self.sharedItems.append(image)
                    } else {
                        self.sharedItems.append(url)
                    }
                case (let img as UIImage, .image):
                    self.sharedItems.append(img)
                case (let txt as String, .text):
                    self.sharedItems.append(txt)
                case (let url as URL, .url):
                    self.sharedItems.append(url)
                default:
                    break
                }
            }
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            load(.image)
        } else if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            load(.movie)
        } else if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
            load(.text)
        } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            load(.url)
        }
    }

    // MARK: – SLCompose hooks we leave unchanged  ──────────────────

    override func isContentValid() -> Bool { true }
    override func configurationItems() -> [Any]! { [] }
}
