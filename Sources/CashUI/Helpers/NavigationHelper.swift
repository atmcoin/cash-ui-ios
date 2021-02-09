
import Foundation
import UIKit

public class NavigationHelper {
    
    public static func colorNavigationController(_ navController: UINavigationController) {
        navController.view.tintColor = UIColor(white: 1, alpha: 0.65)
        navController.navigationBar.barTintColor = Theme.primaryBackground
        navController.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
    }
    
    public static func addCloseBarButtonItem(_ controller: UIViewController, target: Any?, action: Selector) {
        guard let closeImage = UIImage(named: "Close", in: .module, compatibleWith: nil) else { return }
        let closeButton = UIButton.icon(image: closeImage, accessibilityLabel: "Close")
        closeButton.tintColor = .white
        closeButton.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 40, height: 40))
        closeButton.addTarget(target, action: action, for: .touchUpInside)
        let buttonItem = UIBarButtonItem(customView: closeButton)
        controller.navigationItem.rightBarButtonItem = buttonItem
    }
}
