// 
//  AtmInfoView.swift
//
//  Created by Giancarlo Pacheco on 5/12/20.
//

import UIKit
import CashCore

protocol AtmInfoViewDelegate: class {
    func detailsRequestedForAtm(atm: CashCore.AtmMachine)
}

class AtmInfoView: UIView {
    
    @IBOutlet weak var atmIdLabel: UILabel!
    @IBOutlet weak var atmPurchaseOnlyLabel: UILabel!
    @IBOutlet weak var streetLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var redeemButton: UIButton!
    @IBOutlet weak var purchaseButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var directionsButton: UIButton!
    
    public var atm: CashCore.AtmMachine!
    weak var delegate: AtmInfoViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.cornerRadius = 5
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowRadius = 10.0
        self.layer.shadowOpacity = 1.0
        self.layer.shadowOffset = CGSize(width: 1, height: 1)
        self.layer.masksToBounds = false
    }
    
    func configureWithAtm(atm: CashCore.AtmMachine) {
        self.atm = atm
        
//        self.atmPurchaseOnlyLabel.isHidden = atm.redemption!.boolValue
        self.redeemButton.isSelected = atm.redemption!.boolValue
        self.purchaseButton.isSelected = atm.purchase!.boolValue
        atmIdLabel.text = getDetails(atm:atm)
        if let addressString = AtmHelper.cityStateZip(for: atm) {
            self.stateLabel.text = addressString
        }
        if let street = atm.street {
            self.streetLabel.text = street
        }
    }

    private func getDetails(atm : AtmMachine) -> String {
        guard let addressDesc = atm.addressDesc else { return "" }
        return addressDesc
    }
    
    // MARK: - Hit test. We need to override this to detect hits in our custom callout.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Check if it hit our annotation detail view components.
        if (self.directionsButton.frame.contains(point)) {
            return self.directionsButton
        }
        if self.bounds.contains(point) {
            if atm.redemption!.boolValue {
                delegate?.detailsRequestedForAtm(atm: self.atm)
                delegate = nil
            }
            return self
        }
        return nil
    }
    
    @IBAction func showMapDirections(_ sender: Any) {
        guard let atm = atm else { return }
        MapHelper.openMapActionSheet(for: atm, presentation: delegate as! UIViewController)
    }
}
