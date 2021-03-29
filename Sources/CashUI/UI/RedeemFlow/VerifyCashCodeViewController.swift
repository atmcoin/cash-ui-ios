
import UIKit
import CashCore

class VerifyCashCodeViewController: ActionViewController {
    
    @IBOutlet weak var atmMachineTitleLabel: UILabel!
    @IBOutlet weak var tokenTextView: CustomTextField!
    @IBOutlet weak var confirmButton: UIButton!
    
    public var amount: String?
    public var phoneNumber: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.confirmButton.isEnabled = false
    }
    
    @IBAction func sendCashCode(_ sender: Any) {
        guard let atmId = atm?.atmId, let amnt = amount, let token = tokenTextView.text else { return }
        CoreSessionManager.shared.client!.createCashCode(String(atmId), amnt, token, result: { (result) in
            switch result {
            case .success(let response):
                self.view.endEditing(true)
                guard let cashCode = response.data?.items?.first else {
                    self.showAlert(title: "Error", message: "Something went wrong! Please try again.", completion: nil)
                    break
                }
                self.actionCallback?.withdrawal(requested: cashCode)
                
                let transaction = CoreTransaction(status: .SendPending,
                                                 atm: self.atm,
                                                 code: cashCode)
                CoreTransactionManager.store(transaction)
                
                self.actionCallback?.actiondDidComplete(action: .cashCodeVerification)
                break
            case .failure(let error):
                let errorCode = error.code
                var message = "Something went wrong! Please try again."
                if errorCode.isEmpty {
                    self.view.endEditing(true)
                    self.showAlert(title: "Error", message: message, completion: nil)
                    break
                }
                let cashErrorCode = CashCoreErrorCode(rawValue: Int(errorCode)!)!
                if cashErrorCode == .wrongVerificationCode {
                    message = "Verification word incorrect! Please review and enter it again."
                    self.tokenTextView.errorText = message
                }
                else {
                    if (cashErrorCode == .verificationCodeExpired) {
                        message = "Verification word has expired! Please request it again."
                    }
                    self.hideView()
                    self.showAlert(title: "Error", message: "Too many wrong retries! Please request a verification word again.", completion: nil)
                }
                break
            }
            
            self.clearViews()
        })
    }
    
    override public func clearViews() {
        super.clearViews()
        self.tokenTextView.text = ""
        self.textDidChange(self.tokenTextView as Any)
    }
    
    override func showView() {
        super.showView()
        self.listenForKeyboard = true
    }
    
    @IBAction override func textDidChange(_ sender: Any) {
        let code = self.tokenTextView.text
        if (code != "") {
            self.tokenTextView.errorText = ""
            self.confirmButton.isEnabled = true
        }
        else {
            self.confirmButton.isEnabled = false
        }
    }
}
