//
//  ThirdViewController.swift
//  SampleApp
//
//  Created by Giancarlo Pacheco on 2/11/21.
//  Copyright © 2021 Giancarlo Pacheco. All rights reserved.
//

import UIKit
import CashUI

class ThirdViewController: UIViewController {
    
    @IBAction func showActivity(_ sender: Any) {
        let vc = ActivityViewController()
        self.present(vc, animated: true, completion: nil)
    }
}
