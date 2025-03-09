import UIKit
import Social
import MobileCoreServices

// The share extension view controller.
class ShareViewController: SLComposeServiceViewController {

    // Array to store the shared items (images, videos, text, links)
    var sharedItems: [Any] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Process the extension’s input items.
        if let extensionItems = self.extensionContext?.inputItems as? [NSExtensionItem] {
            for item in extensionItems {
                if let attachments = item.attachments {
                    for provider in attachments {
                        // Check and load an image.
                        if provider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                            provider.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil) { (data, error) in
                                if let image = data as? UIImage {
                                    self.sharedItems.append(image)
                                }
                            }
                        }
                        // Check and load a video.
                        else if provider.hasItemConformingToTypeIdentifier(kUTTypeMovie as String) {
                            provider.loadItem(forTypeIdentifier: kUTTypeMovie as String, options: nil) { (data, error) in
                                if let url = data as? URL {
                                    self.sharedItems.append(url)
                                }
                            }
                        }
                        // Check and load text.
                        else if provider.hasItemConformingToTypeIdentifier(kUTTypeText as String) {
                            provider.loadItem(forTypeIdentifier: kUTTypeText as String, options: nil) { (data, error) in
                                if let text = data as? String {
                                    self.sharedItems.append(text)
                                }
                            }
                        }
                        // Check and load a URL (link).
                        else if provider.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                            provider.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { (data, error) in
                                if let url = data as? URL {
                                    self.sharedItems.append(url)
                                }
                            }
                        }
                    }
                }
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
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        
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
}


// An optional view controller that displays the shared content in a table view.
// Use this if you want to preview the shared items before completing the extension.
class SharedContentViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

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
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(close))
    }

    @objc func close() {
        // Dismiss this view controller and complete the extension.
        self.dismiss(animated: true) {
            if let shareVC = self.presentingViewController as? ShareViewController {
                shareVC.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            }
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sharedItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
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
