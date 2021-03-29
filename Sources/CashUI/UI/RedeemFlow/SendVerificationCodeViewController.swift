// 
//  SendVerificationCodeViewController.swift
//
//  Created by Giancarlo Pacheco on 5/12/20.
//
//  See the LICENSE file at the project root for license information.
//

import UIKit
import CashCore

class SendVerificationCodeViewController: ActionViewController {
    
    // IBOutlets
    @IBOutlet weak var atmMachineTitleLabel: UILabel!
    @IBOutlet weak var amountToWithdrawTextField: CustomTextField!
    @IBOutlet weak var infoAboutMachineLabel: UILabel!
    @IBOutlet weak var phoneNumberTextField: CustomTextField!
    @IBOutlet weak var firstNameTextField: CustomTextField!
    @IBOutlet weak var lastNameTextField: CustomTextField!
    @IBOutlet weak var getAtmCodeButton: UIButton!

    var validFields: Bool {
        return amountToWithdrawTextField.isValid && phoneNumberTextField.isValid && firstNameTextField.isValid && lastNameTextField.isValid
    }

    static let defaultMinAmountLimit: Int = 20
    static let defaultMaxAmountLimit: Int = 300
    static let defaultAllowedBills: Int = 20
    
    var minAmountLimit = defaultMinAmountLimit
    var maxAmountLimit = defaultMaxAmountLimit
    var allowedBills = defaultAllowedBills

    override func viewDidLoad() {
        super.viewDidLoad()
        self.getAtmCodeButton.isEnabled = false
    }
    
    @IBAction func getVerificationCodeAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        let firstName = firstNameTextField.text!
        let lastName = self.lastNameTextField.text!
        let phoneNumber = self.phoneNumberTextField.text!
        CoreSessionManager.shared.client!.sendVerificationCode(first: firstName,
                                                               surname: lastName,
                                                               phoneNumber: phoneNumber,
                                                               email: "",
                                                               result: { (result) in
                                                                switch result {
                                                                case .success(_):
                                                                    self.actionCallback?.withdraw(amount: self.amountToWithdrawTextField.text!)
                                                                    self.actionCallback?.actiondDidComplete(action: .sendVerificationCode)
                                                                case .failure(_):
                                                                    self.showAlert(title: "Error", message: "Something went wrong! Please try again", completion: nil)
                                                                }
                                                                self.hideView()
                                                                self.clearViews()
        })
        
        saveUserInfo(firstName: firstName, lastName: lastName, phoneNumber: phoneNumber)
    }

    public func setAtmInfo(_ atm: CashCore.AtmMachine) {
//        let transaction = CoreTransaction(status: .VerifyPending,
//                                         atm: atm)
//        CoreTransactionManager.shared.store(transaction)
        
        var value = (atm.min! as NSString).integerValue
        minAmountLimit = value > 0 ? value : SendVerificationCodeViewController.defaultMinAmountLimit
        value = (atm.max! as NSString).integerValue
        maxAmountLimit = value > 0 ? value : SendVerificationCodeViewController.defaultMaxAmountLimit
        value = (atm.bills! as NSString).integerValue
        allowedBills = value > 0 ? value : SendVerificationCodeViewController.defaultAllowedBills
        
        self.atmMachineTitleLabel.text = atm.addressDesc!
        self.atmMachineTitleLabel.setNeedsDisplay()
        self.infoAboutMachineLabel.text = "Min $\(String(describing: minAmountLimit)), Max $\(String(describing: maxAmountLimit)). Multiple of $\(String(describing: allowedBills))"

        self.infoAboutMachineLabel.setNeedsDisplay()
        self.listenForKeyboard = true
        
        populateUserInfo()
    }

    override public func clearViews() {
        super.clearViews()
        self.amountToWithdrawTextField.text = ""
        self.infoAboutMachineLabel.text = ""
        self.phoneNumberTextField.text = ""
        self.firstNameTextField.text = ""
        self.lastNameTextField.text = ""
        self.view.setNeedsDisplay()
    }

    @IBAction func textFieldEditingDidChange(_ textField: UITextField) {
        let text = textField.text!
        switch textField {
        case amountToWithdrawTextField:
            if let errorMessage = text.validateAmount(lowerBound: minAmountLimit, upperBound: maxAmountLimit, allowedBills: allowedBills) {
                amountToWithdrawTextField.errorText = errorMessage
            }
        case phoneNumberTextField:
            if let errorMessage = text.validatePhoneNumber() {
                phoneNumberTextField.errorText = errorMessage
            }
        case firstNameTextField:
            if let errorMessage = text.validateName() {
                firstNameTextField.errorText = errorMessage
            }
        case lastNameTextField:
            if let errorMessage = text.validateName() {
                lastNameTextField.errorText = errorMessage
            }
        default: break
        }
        
        if validFields {
            getAtmCodeButton.isEnabled = true
        } else {
            getAtmCodeButton.isEnabled = false
        }
    }
}

extension SendVerificationCodeViewController {
    
    private func populateUserInfo() {
        guard let data = CoreSessionManager.shared.client!.getData() else {
            return
        }
        firstNameTextField.text = data[kFirstName]
        lastNameTextField.text = data[kLastName]
        phoneNumberTextField.text = data[kPhoneNumber]
    }
    
    private func saveUserInfo(firstName: String, lastName: String, phoneNumber: String) {
//        let user = CoreUser(firstName: firstName, lastName: lastName, phone: phoneNumber)
//        do {
//            try UserDefaults.standard.setUser(user)
//        } catch {}
    }
    
}
