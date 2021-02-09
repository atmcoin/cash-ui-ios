
import UIKit
import MapKit
import CashCore

private let kAtmAnnotationViewReusableIdentifier = "kAtmAnnotationViewReusableIdentifier"

class WithdrawalStatusViewController: ActionViewController {
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var atmMapView: MKMapView!
    @IBOutlet weak var atmLocationDescription: UILabel!
    @IBOutlet weak var atmStateLabel: UILabel!
    @IBOutlet weak var atmStreetLabel: UILabel!
    @IBOutlet weak var amountUSDLabel: UILabel!
    @IBOutlet weak var amountBTCLabel: UILabel!
    @IBOutlet weak var addressTitleLabel: UILabel!
    @IBOutlet weak var addressLabel: CopyableLabel!
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var qrCodeImageView: UIImageView!
    @IBOutlet weak var redeemCodeLabel: UILabel!
    @IBOutlet weak var redeemView: UIView!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    
    var transaction: CoreTransaction!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialData()
        setMapLocation()
        
        NotificationCenter.default.addObserver(self, selector: #selector(transactionDidUpdate), name: .CoreTransactionDidChange, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        update()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func initialData() {
        atmMapView.register(AtmAnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        atmMapView.delegate = self
        
        if let atm = transaction.atm, let latitude = atm.latitude,
            let longitude = atm.longitude {
            let atmLocation = CLLocation(latitude: (latitude as NSString).doubleValue, longitude: (longitude as NSString).doubleValue)
            atmMapView.centerToLocation(atmLocation)
            self.atmLocationDescription.text = transaction.atm?.addressDesc
            if let addressString = AtmHelper.cityStateZip(for: atm) {
                self.atmStateLabel.text = addressString
            }
            
            if let street = atm.street {
                self.atmStreetLabel.text = street
            }
        }
        
        if let code = transaction.code {
            let btcAmount = (code.btcAmount! as NSString).doubleValue
            let usdAmount = (code.usdAmount! as NSString).doubleValue
            
            setQRCode(from:code.address!, amount:btcAmount)
        
            self.amountUSDLabel.text = String(format: "$%.2f", usdAmount)
            self.amountBTCLabel.text = "\(code.btcAmount!)"
            self.addressLabel.text = code.address
        }
    }
    
    private func update() {
        if let code = transaction.pCode {
            let components = code.components(separatedBy: "-")
            let regularAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 35),
                                     NSAttributedString.Key.foregroundColor: UIColor.gray]
            let largeAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 35, weight: .heavy)]
            let codeString = NSMutableAttributedString(string: "Code: ", attributes: regularAttributes)
            let pinString = NSAttributedString(string: "\nPIN: ", attributes: regularAttributes)
            let codeValueString = NSAttributedString(string: components[0], attributes: largeAttributes)
            let pinValueString = NSAttributedString(string: components[1], attributes: largeAttributes)
        
            codeString.append(codeValueString)
            codeString.append(pinString)
            codeString.append(pinValueString)
            
            self.redeemCodeLabel.attributedText = codeString
        }
        self.updateStatus(transaction.status)
    }
    
    func updateStatus(_ status: CoreTransactionStatus) {
        self.qrCodeImageView.isHidden = true
        self.sendButton.isHidden = true
        
        self.addressLabel.isHidden = true
        self.addressTitleLabel.isHidden = true
        
        self.stateLabel.isHidden = false
        self.stateLabel.text = status.displayValue
        
        self.redeemView.isHidden = true
        
        switch status {
        case .Awaiting, .FundedNotConfirmed:
            // To the server there is no difference
            self.addressLabel.isHidden = false
            self.addressTitleLabel.isHidden = false
            break
        case .Funded:
            // Show Code to redeem
            self.stateLabel.isHidden = true
            self.redeemView.isHidden = false
            break
        case .Withdrawn, .Cancelled, .VerifyPending, .Error:
            break
        case .SendPending:
            self.qrCodeImageView.isHidden = false
            self.addressLabel.isHidden = false
            self.addressTitleLabel.isHidden = false
            self.sendButton.isHidden = false
            
            self.stateLabel.isHidden = true
            break
        }
    }
    
    private func setQRCode(from address: String, amount btc: Double) {
        let finalAddress = "bitcoin:\(address)?amount=\(btc)"
        guard let data = finalAddress.data(using: .utf8) else { return }
        self.qrCodeImageView.image = UIImage
            .qrCode(data: data)!
            .resize(self.qrCodeImageView.frame.size)
    }
    
    private func setMapLocation() {
        let annotation = AtmAnnotation.init(atm: transaction.atm!)
        self.atmMapView.addAnnotation(annotation)
    }
    
    @objc override public func hideView() {
        super.hideView()
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func transactionDidUpdate(_ notification: Notification) {
        let t = notification.object as! CoreTransaction
        if (t == self.transaction) {
            update()
        }
    }
    
    @IBAction func sendCoin(_ sender: Any) {
        AtmLocationsViewController.sendCoin(amount: (transaction.code?.btcAmount)!, address: (transaction.code?.address)!, completion: {
            CoreTransactionManager.updateTransaction(status: .Awaiting, address: (self.transaction.code?.address)!)
            self.update()
        })
    }
    
    @IBAction func showMapDirections(_ sender: Any) {
        guard let atm = transaction.atm else { return }
        MapHelper.openMapActionSheet(for: atm, presentation: self)
    }
}

extension WithdrawalStatusViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation { return nil }
        
        var annotationView = atmMapView.dequeueReusableAnnotationView(withIdentifier: kAtmAnnotationViewReusableIdentifier)
        
        if annotationView == nil {
            annotationView = AtmAnnotationView(annotation: annotation, reuseIdentifier: kAtmAnnotationViewReusableIdentifier)
            annotationView?.image = UIImage(named: "atmWhite", in: .module, compatibleWith: nil)
        } else {
            annotationView!.annotation = annotation
        }
        
        return annotationView
    }
}
