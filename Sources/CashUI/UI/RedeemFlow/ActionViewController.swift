// 
//  ActionViewController.swift
//
//  Created by Giancarlo Pacheco on 5/13/20.
//
//  See the LICENSE file at the project root for license information.
//

import UIKit
import CashCore

class ActionViewController: UIViewController {
    
    public var atm: CashCore.AtmMachine?
    
    public var listenForKeyboard = false
    public var keyboardShown = false
    public var actionCallback: ActionProtocol?
    
    var closeButton: UIButton!
    var infoButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        roundViews()
        addCloseButton()
//        addInfoButton()
    }
    
    func roundViews() {
        view.layer.cornerRadius = 10
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowRadius = 10.0
        view.layer.shadowOpacity = 1.0
        view.layer.shadowOffset = CGSize(width: 1, height: 1)
        view.layer.masksToBounds = false
    }
    
    func getConstraint() -> NSLayoutConstraint? {
        guard let controllerClass: AnyClass = NSClassFromString("CashUI.SendVerificationCodeViewController"), let parent = self.parent as? AtmLocationsViewController else { return nil }
        let index = self.isKind(of: controllerClass) ? 0 : 1
        let constraint = parent.redeeemFlowAnimatableTopConstraints[index]
        return constraint
    }
    
    func showAnimated() {
        view.isHidden = false
        guard let constraint = getConstraint() else { return }
        constraint.constant = -view.frame.height
        UIView.animate(withDuration: 0.35, animations: {
            self.view.superview?.layoutIfNeeded()
        })
    }
    
    func hideAnimated() {
        guard let constraint = getConstraint() else { return }
        constraint.constant = 0.0
        UIView.animate(withDuration: 0.35, animations: {
            self.view.superview?.layoutIfNeeded()
        }) { _ in
            self.view.isHidden = true
        }
    }
    
    public func showView() {
        showAnimated()
        
        // Observe keyboard change
        NotificationCenter.default.addObserver(self, selector:#selector(adjustForKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc public func hideView() {
        if (!keyboardShown) {
            self.hideAnimated()
        }
        self.view.endEditing(true)
        NotificationCenter.default.removeObserver(self)
    }
    
    public func clearViews() {
    }
    
    public func addCloseButton() {
        let image = UIImage(named: "Close", in: .module, compatibleWith: nil)
        closeButton = UIButton.icon(image: image!, accessibilityLabel: "Close")
        self.view.addSubview(closeButton)
        closeButton.constrain([
            closeButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0),
            closeButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0),
            closeButton.heightAnchor.constraint(equalToConstant: 40),
            closeButton.widthAnchor.constraint(equalToConstant: 40)
        ])
        
        closeButton.addTarget(self, action: #selector(hideView), for: .touchUpInside)
    }
    
    public func addInfoButton() {
        let image = UIImage(named: "Faq", in: .module, compatibleWith: nil)
        infoButton = UIButton.icon(image:image!, accessibilityLabel: "Info")
        self.view.addSubview(infoButton)
        infoButton.constrain([
            infoButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0),
            infoButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0),
            infoButton.heightAnchor.constraint(equalToConstant: 40),
            infoButton.widthAnchor.constraint(equalToConstant: 40)
        ])
        
        closeButton.addTarget(self, action: #selector(hideView), for: .touchUpInside)
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        if !listenForKeyboard {
            return
        }
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardSize = keyboardValue.cgRectValue.size

        if notification.name == UIResponder.keyboardWillHideNotification {
            keyboardShown = false
        }
        else {
            if keyboardShown {return}
            keyboardShown = true
        }
        
        let userInfo = notification.userInfo
        let duration:TimeInterval = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        
        guard let constraint = getConstraint() else { return }
        constraint.constant = keyboardShown ? -view.frame.height - keyboardSize.height : 0
        UIView.animate(withDuration: duration, animations: {
            self.view.superview?.layoutIfNeeded()
        }) { _ in
            if !self.keyboardShown {
                self.view.isHidden = true
            }
        }
    }
    
    func textDidChange(_ sender: Any) {
        
    }
}

extension UIViewController {
    
    func showAlert(title: String, message: String, buttonLabel: String = "OK", cancelButtonLabel: String = "Cancel", completion: ((UIAlertAction) -> Void)?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: buttonLabel, style: .default) { (action) in
            completion?(action)
        })
//        alertController.addAction(UIAlertAction(title: cancelButtonLabel, style: .cancel) { (action) in
//            completion(action)
//        })
        present(alertController, animated: true, completion: nil)
    }
}
