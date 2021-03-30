
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
                let errorCode = Int(error.code)
                var message = "Something went wrong! Please try again."
                if errorCode == CashCoreErrorCode.wrongVerificationCode.rawValue {
                    self.tokenTextView.errorText = "Verification word incorrect! Please review and enter it again."
                    break
                }
                if (errorCode == CashCoreErrorCode.verificationCodeExpired.rawValue) {
                    message = "Verification word has expired! Please request it again."
                }
                if (errorCode == CashCoreErrorCode.tooManyVerificationCodeAttempts.rawValue) {
                    message = "Too many wrong retries! Please request a verification word again."
                }
                self.view.endEditing(true)
                self.showAlert(title: "Error", message: message, completion: nil)
                self.hideView()
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
