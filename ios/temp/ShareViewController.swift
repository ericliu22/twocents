import SwiftUI
import UIKit

// The share extension view controller.
class ShareViewController: UIViewController {

    // Array to store the shared items (images, videos, text, links)
    override func viewDidLoad() {
        super.viewDidLoad()

        guard
            let extensionItems = extensionContext?.inputItems
                as? [NSExtensionItem]
        else {
            self.extensionContext?.completeRequest(
                returningItems: [], completionHandler: nil)
            return
        }
        
        let contentView = UIHostingController(rootView: ShareExtensionView(items: extensionItems))
                                self.addChild(contentView)
                                self.view.addSubview(contentView.view)
                                
                                // set up constraints
                                contentView.view.translatesAutoresizingMaskIntoConstraints = false
                                contentView.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
                                contentView.view.bottomAnchor.constraint (equalTo: self.view.bottomAnchor).isActive = true
                                contentView.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
                                contentView.view.rightAnchor.constraint (equalTo: self.view.rightAnchor).isActive = true
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("close"), object: nil, queue: nil) { _ in
            DispatchQueue.main.async {
                self.close()
            }
        }
    }

    func close() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
