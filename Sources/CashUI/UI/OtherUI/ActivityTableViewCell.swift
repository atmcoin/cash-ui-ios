// 
//  ActivityTableViewCell.swift
//
//  Created by Giancarlo Pacheco on 5/22/20.
//
//  See the LICENSE file at the project root for license information.
//

import UIKit
import CashCore

class ActivityTableViewCell: UITableViewCell {
    
    private var _transaction: CoreTransaction!
    var transaction: CoreTransaction! {
        set {
            _transaction = newValue
            populateView(from: _transaction)
        }
        get {
            return _transaction
        }
    }
    
    /// UIView is displayed when cell open
    @IBOutlet open var closedView: UIView!
    @IBOutlet open var closedViewTop: NSLayoutConstraint!
    @IBOutlet open var dateLabel: UILabel!
    @IBOutlet open var timeLabel: UILabel!
    @IBOutlet open var fundedLabel: UILabel!
    @IBOutlet open var rightView: UIView!
    @IBOutlet open var atmMachineNameLabel: UILabel!
    @IBOutlet open var streetLabel: UILabel!
    @IBOutlet open var stateLabel: UILabel!
    @IBOutlet open var amountTitleLabel: UILabel!
    @IBOutlet open var amountLabel: UILabel!
    @IBOutlet open var leftView: UIView!    
    
    /// UIView whitch display when cell close
    @IBOutlet open var openedView: UIView!
    @IBOutlet open var openedViewTop: NSLayoutConstraint!
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        
        commonInit()
    }
    
    @objc open func commonInit() {
        
        selectionStyle = .none
        closedView.layer.cornerRadius = 10
        closedView.layer.masksToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.frame = self.contentView.frame.inset(by: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
    }
    
    private func populateView(from transaction: CoreTransaction) {
        if let atm = transaction.atm {
            self.atmMachineNameLabel.text = atm.addressDesc
            if let addressString = AtmHelper.cityStateZip(for: atm) {
                self.stateLabel.text = addressString
            }
            if let street = atm.street {
                self.streetLabel.text = street
            }
        }
        self.amountLabel.text = (transaction.code?.btcAmount ?? "0") + " BTC"
        self.fundedLabel.numberOfLines = transaction.status == CoreTransactionStatus.Awaiting ? 2 : 1
        self.fundedLabel.text = transaction.status.displayValue
        self.leftView.backgroundColor = UIColor.fromHex(transaction.color)
        self.dateLabel.text = Date().dateString(from: transaction.timestamp)
        self.timeLabel.text = Date().timeString(from: transaction.timestamp)
    }
    
    static func heightForTableViewCell() -> CGFloat {
        return 199
    }
    
}
