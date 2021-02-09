
import Foundation
import CashCore
import UIKit

public class SupportManager: NavigationControllerProtocol {
        
    public static let shared: SupportManager = {
        let instance = SupportManager()
        return instance
    }()
    
    public var filename: String = "support" {
        didSet {
            client.loadJson(fileName: filename)
        }
    }
    
    private let navigationController = UINavigationController()
    
    public var client: ServerEndpoints
    
    init() {
        client = ServerEndpoints.init()
        client.loadJson(fileName: "support")
    }
    
    public func supportTopic(for topicId: String) -> TopicDetailViewController? {
        let storyboard = UIStoryboard(name: "SupportListStoryboard", bundle: .module)
        let vc: TopicDetailViewController = storyboard.instantiateViewController(withIdentifier: "TopicDetailViewController") as! TopicDetailViewController
        vc.topic = client.support?.topic(for: topicId)
        return vc
    }
    
    public func presentSupportTopic(for topicId: String, from controller: UIViewController) {
        guard let vc = supportTopic(for: topicId) else { return }
        navigationController.addChild(vc)
        colorNavigationController(navigationController)
        addCloseBarButtonItem(vc, target: SupportManager.shared, action: #selector(SupportManager.shared.dismissController))
        controller.present(navigationController, animated: true, completion: nil)
    }
    
    public func supportCategories() -> SupportListViewController? {
        let storyboard = UIStoryboard(name: "SupportListStoryboard", bundle: .module)
        let vc: SupportListViewController = storyboard.instantiateViewController(withIdentifier: "SupportListViewController") as! SupportListViewController
        vc.client = client
        return vc
    }
    
    @objc private func dismissController() {
        navigationController.dismiss(animated: true)
    }
}
