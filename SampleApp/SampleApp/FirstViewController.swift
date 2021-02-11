
import UIKit
import CashUI

class FirstViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        CoreSessionManager.shared.start(url: .Staging)
        CoreSessionManager.shared.delegate = self
    }
    
    @IBAction func showMenu(_ sender: Any) {
        let navigationController = UINavigationController()
        let menuController = AtmMenuViewController()
        navigationController.addChild(menuController)
        self.present(navigationController, animated: true) {}
    }
}

extension FirstViewController : CoreSessionManagerDelegate {
    func sendCoin(amount: String, address: String, completion: @escaping (() -> Void)) {
        print("Send \(amount) for Address : \(address)")
    }
}
