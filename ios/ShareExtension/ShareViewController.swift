import MobileCoreServices
import Social
import TwoCentsInternal
import UIKit
import UniformTypeIdentifiers
import FirebaseCore
import FirebaseAuth

let APP_GROUP = "432WVK3797.com.twocentsapp.newcents.keychain-group"
let groups: [UUID] = [UUID(uuidString: "b343342a-d41b-4c79-a8a8-7e0b142be6da")!]
// The share extension view controller.
class ShareViewController: SLComposeServiceViewController {

    // Array to store the shared items (images, videos, text, links)
    var sharedItems: [Any] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        FirebaseApp.configure()
        do {
            try Auth.auth().useUserAccessGroup(APP_GROUP)
        } catch {
            let message = "Error changing user access group \(error.localizedDescription)"
            print(error)
        }

        // Process the extension’s input items.
        if let extensionItems = self.extensionContext?.inputItems
            as? [NSExtensionItem]
        {
            let dispatchGroup = DispatchGroup()
            for item in extensionItems {
                if let attachments = item.attachments {
                    for provider in attachments {
                        // Check and load an image.
                        if provider.hasItemConformingToTypeIdentifier(
                            UTType.image.identifier)
                        {
                            dispatchGroup.enter()
                            provider.loadItem(
                                forTypeIdentifier: UTType.image.identifier,
                                options: nil
                            ) { (data, error) in
                                if let error = error {
                                        print("Error loading image: \(error)")
                                        return
                                    }
                                if let image = data as? UIImage {
                                    DispatchQueue.main.async {
                                        self.sharedItems.append(image)
                                    }
                                } else if let url = data as? URL {
                                    if let image = UIImage(contentsOfFile: url.path) {
                                        DispatchQueue.main.async {
                                            self.sharedItems.append(image)
                                        }
                                    } else {
                                        print("Unable to create UIImage from URL.")
                                    }
                                } else {
                                    print("Unexpected type returned: \(String(describing: data))")
                                }
                                dispatchGroup.leave()
                            }
                        }
                        // Check and load a video.
                        else if provider.hasItemConformingToTypeIdentifier(
                            UTType.movie.identifier)
                        {
                            dispatchGroup.enter()
                            provider.loadItem(
                                forTypeIdentifier: UTType.movie.identifier,
                                options: nil
                            ) { (data, error) in
                                if let url = data as? URL {
                                    DispatchQueue.main.async {
                                        print("added")
                                        self.sharedItems.append(url)
                                    }
                                    dispatchGroup.leave()
                                }
                            }
                        }
                        // Check and load text.
                        else if provider.hasItemConformingToTypeIdentifier(
                            UTType.text.identifier)
                        {
                            dispatchGroup.enter()
                            provider.loadItem(
                                forTypeIdentifier: UTType.text.identifier,
                                options: nil
                            ) { (data, error) in
                                if let text = data as? String {
                                    DispatchQueue.main.async {
                                        print("added")
                                        self.sharedItems.append(text)
                                    }
                                    dispatchGroup.leave()
                                }
                            }
                        }
                        // Check and load a URL (link).
                        else if provider.hasItemConformingToTypeIdentifier(
                            UTType.url.identifier)
                        {
                            dispatchGroup.enter()
                            provider.loadItem(
                                forTypeIdentifier: UTType.url.identifier,
                                options: nil
                            ) { (data, error) in
                                if let url = data as? URL {
                                    DispatchQueue.main.async {
                                        print("added")
                                        self.sharedItems.append(url)
                                    }
                                    dispatchGroup.leave()
                                }
                            }
                        }
                    }
                }
            }
            dispatchGroup.notify(queue: .main) {
                // Enable the Post button or update the UI as needed.
            }
        }
    }

    // Validate the content before enabling the Post button.
    override func isContentValid() -> Bool {
        // Optionally, add your own validation logic here.
        return true
    }

    // Called when the user taps Post.
    override func didSelectPost() {
        // Immediately complete the extension request.

        Task {
            // Step 1. Determine the media type.
            // For this example, we’ll use the first shared item as a reference.
            guard let firstItem = sharedItems.first else {
                print("No first item")
                self.extensionContext?.completeRequest(
                    returningItems: nil, completionHandler: nil)
                return
            }

            let media: Media = {
                if firstItem is UIImage {
                    return .IMAGE
                } else if firstItem is String {
                    return .TEXT
                } else if let url = firstItem as? URL {
                    // Here we check the file extension to decide if it's a video.
                    let videoExtensions = ["mov", "mp4", "m4v"]
                    if videoExtensions.contains(url.pathExtension.lowercased())
                    {
                        return .VIDEO
                    } else {
                        return .LINK
                    }
                }
                return .OTHER
            }()

            // Step 2. Build a PostRequest.
            // You can pass additional details (e.g. groups) as needed.
            let caption = self.contentText
            let postRequest = PostRequest(
                media: media, caption: caption, groups: groups)

            print("GROUPS")
            print(groups)
            do {
                // Step 3. Upload the post and decode the response into a Post object.
                let post = try await PostManager.uploadPost(
                    postRequest: postRequest)

                // Step 4. Depending on the media type, upload the corresponding media data.
                switch media {
                case .IMAGE:
                    await handleImage(post: post)
                case .VIDEO:
                    await handleVideo(post: post)
                case .LINK:
                    await handleLink(post: post)
                case .TEXT:
                    await handleText(post: post)
                default:
                    break
                }
            } catch {
                print("Error during post upload: \(error)")
            }

            // Finally, complete the extension request.
            self.extensionContext?.completeRequest(
                returningItems: nil, completionHandler: nil)
        }
        // Optionally, if you wish to display the shared content before closing,
        // you can instantiate and present SharedContentViewController instead.
        //
        // let contentVC = SharedContentViewController()
        // contentVC.sharedItems = self.sharedItems
        // let navVC = UINavigationController(rootViewController: contentVC)
        // self.present(navVC, animated: true, completion: nil)
    }

    // Return configuration options if needed (optional).
    override func configurationItems() -> [Any]! {
        return []
    }

    func handleLink(post: Post) async {
        for item in sharedItems {
            guard let linkURL = item as? URL else {
                continue
            }
            let body = [
                "mediaUrl": linkURL.absoluteString,
                "postId": post.id.uuidString
            ]
            guard let data = try? TwoCentsEncoder().encode(body) else {
                continue
            }
            print(post.id)
            _ = try? await PostManager.uploadMediaPost(post: post, data: data)
        }
    }
    func handleText(post: Post) async {
        print("Not implemented yet")
        for item in sharedItems {
            guard let text = item as? String else {
                continue
            }
            let body = [
                "text": text,
                "postId": post.id.uuidString
            ]
            guard let data = try? TwoCentsEncoder().encode(body) else {
                continue
            }
            _ = try? await PostManager.uploadMediaPost(post: post, data: data)
        }
    }

    func handleVideo(post: Post) async {
        print("VIDEO")
        for item in sharedItems {
            guard let videoURL = item as? URL else {
                continue
            }
            guard let data = try? Data(contentsOf: videoURL) else {
                continue
            }
            _ = try? await PostManager.uploadMediaPost(post: post, data: data)
        }
    }
    func handleImage(post: Post) async {
        for item in sharedItems {
            guard let image = item as? UIImage else {
                continue
            }
            let data = image.jpegData(compressionQuality: 1.0)
            if let data {
                _ = try? await PostManager.uploadMediaPost(
                    post: post, data: data)
            }
        }
    }

}

// An optional view controller that displays the shared content in a table view.
// Use this if you want to preview the shared items before completing the extension.
class SharedContentViewController: UIViewController, UITableViewDataSource,
    UITableViewDelegate
{

    var sharedItems: [Any] = []
    let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Shared Content"
        view.backgroundColor = .white

        // Set up the table view.
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        // Add a Close button to dismiss the view and complete the extension.
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Close", style: .done, target: self, action: #selector(close)
        )
    }

    @objc func close() {
        // Dismiss this view controller and complete the extension.
        self.dismiss(animated: true) {
            if let shareVC = self.presentingViewController
                as? ShareViewController
            {
                shareVC.extensionContext?.completeRequest(
                    returningItems: nil, completionHandler: nil)
            }
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)
        -> Int
    {
        return sharedItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "cell", for: indexPath)
        let item = sharedItems[indexPath.row]

        // Configure the cell based on the type of the shared item.
        if let image = item as? UIImage {
            cell.imageView?.image = image
            cell.textLabel?.text = "Image"
        } else if let url = item as? URL {
            cell.textLabel?.text = "URL: \(url.absoluteString)"
        } else if let text = item as? String {
            cell.textLabel?.text = "Text: \(text)"
        } else {
            cell.textLabel?.text = "Unknown item"
        }
        return cell
    }

    // MARK: - UITableViewDelegate
    // Add UITableViewDelegate methods here if needed.
}
