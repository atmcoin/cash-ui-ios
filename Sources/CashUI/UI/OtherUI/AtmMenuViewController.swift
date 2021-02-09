// 
//  MenuViewController.swift
//  breadwallet
//
//  Created by Gardner von Holt on 5/29/20.
//  Copyright © 2020 Breadwinner AG. All rights reserved.
//
//  See the LICENSE file at the project root for license information.
//

import UIKit
import CashCore

public class AtmMenuViewController: UIViewController {

    @IBOutlet weak var labelMainTitle: UILabel!
    @IBOutlet weak var containerView: UIView!

    private var activityViewController: ActivityViewController?
    var cellHeights: [CGFloat] = []
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: "MenuView", bundle: .module)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "ATM Cash Redemption"
        view.backgroundColor = Theme.primaryBackground

        setupActivityView()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        activityViewController?.tableView.reloadData()
    }
    
    func setupActivityView() {
        activityViewController = ActivityViewController(nibName: "ActivityView", bundle: .module)
        activityViewController?.shouldShowCloseButton = false
        containerView.addSubview(activityViewController!.view)
    }

    @IBAction func showMap(_ sender: Any) {
        let vc = AtmLocationsViewController(nibName: "AtmLocationsView", bundle: .module)
        navigationController?.pushViewController(vc, animated: true)
    }

}
