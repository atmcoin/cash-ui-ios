// 
//  WACMenuViewController.swift
//  breadwallet
//
//  Created by Gardner von Holt on 5/29/20.
//  Copyright © 2020 Breadwinner AG. All rights reserved.
//
//  See the LICENSE file at the project root for license information.
//

import UIKit
import WacSDK

public class WACMenuViewController: UIViewController {

    @IBOutlet weak var labelMainTitle: UILabel!
    @IBOutlet weak var containerView: UIView!

    private var activityViewController: WACActivityViewController?
    var cellHeights: [CGFloat] = []

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
        let bundle = Bundle.init(for: WACActivityViewController.self)
        activityViewController = WACActivityViewController(nibName: "WACActivityView", bundle: bundle)
        containerView.addSubview(activityViewController!.view)
    }

    @IBAction func showMap(_ sender: Any) {
        let bundle = Bundle.init(for: WACAtmLocationsViewController.self)
        let vc = WACAtmLocationsViewController(nibName: "WACAtmLocationsView", bundle: bundle)
        navigationController?.pushViewController(vc, animated: true)
    }

}
