// 
//  AtmLocationsViewController.swift
//
//  Created by Giancarlo Pacheco on 5/14/20.
//
//  See the LICENSE file at the project root for license information.
//

import UIKit
import CashCore

struct FilterObject {
    var filterAction: FilterActions
    var filterButton: UIButton
}

enum ActionStrings: String {
    case list = "List"
    case map = "Map"
    case send = "Send"
    case details = "Details"
}

enum FilterActions: Int {
    case all
    case redeem
    case purchase
    case favorite
}

public enum Action {
    case sendVerificationCode
    case cashCodeVerification
}

protocol ActionProtocol {
    func actiondDidComplete(action: Action?)
    func withdraw(amount: String)
    func withdrawal(requested cashCode: CashCore.CashCode)
    func sendCashCode(_ cashCode: CashCore.CashCode)
}

protocol ATMListFilter {
    func update(_ atms: [AtmMachine]?)
}

class AtmLocationsViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var myLocationButton: UIButton!
    
    @IBOutlet weak var searchBackgroundView: UIView!
    @IBOutlet weak var showAllATMsButton: UIButton!
    @IBOutlet weak var redeemOnlyATMsButton: UIButton!
    @IBOutlet weak var purchaseOnlyATMsButton: UIButton!
    @IBOutlet weak var favoriteATMsButton: UIButton!
    
    // Filter
    @IBOutlet var filterButtonsTopConstraints: [NSLayoutConstraint]!
    private var filterButtonsOpen: Bool = false
    private var filterObjectSelected: FilterObject?
    private var filterButtons: [UIButton] {
        return [showAllATMsButton, redeemOnlyATMsButton, purchaseOnlyATMsButton, /*favoriteATMsButton*/]
    }
    private var _filterObjects: [FilterObject] = []
    private var filterObjects: [FilterObject] {
        get {
            if _filterObjects.isEmpty {
                var objects: [FilterObject] = []
                objects.append(FilterObject(filterAction: .all, filterButton: showAllATMsButton))
                objects.append(FilterObject(filterAction: .redeem, filterButton: redeemOnlyATMsButton))
                objects.append(FilterObject(filterAction: .purchase, filterButton: purchaseOnlyATMsButton))
                objects.append(FilterObject(filterAction: .favorite, filterButton: favoriteATMsButton))
                _filterObjects = objects
            }
            return _filterObjects
        }
    }
    
    private var textField: UITextField?
    private var rightBarbuttonItem: UIBarButtonItem?
    
    private var atmList: [AtmMachine]?
    private var filteredList: [AtmMachine]?
    
    var sendVerificationVC: SendVerificationCodeViewController?
    var verifyCashCodeVC: VerifyCashCodeViewController?
    // TODO: make this one a key-value pair with instance - constraint
    var redeeemFlowAnimatableTopConstraints: [NSLayoutConstraint] = []
    
    var currentContainerViewVC: UIViewController?
    
    private lazy var mapVC: MapViewController = {
        var viewController = MapViewController()
        return viewController
    }()
    
    private lazy var listVC: ListViewController = {
        var viewController = ListViewController.init(nibName: "ListView", bundle: .module)
        return viewController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addToggleNavigationItem()
        add(asChildViewController: mapVC)
        
        self.title = "ATM Cash Locations"
        view.backgroundColor = Theme.primaryBackground
        
        setRoundBackgroundOnButtons()
        showAllATMsButton.isSelected = true
        filterObjectSelected = filterObjects.first
        
        // By now, we should already have a session
        getAtmList()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        addSendVerificationView()
        addVerifyCashCodeView()
    }
    
    override func didMove(toParent parent: UIViewController?) {
        setTextFieldAppearance()
    }
    
    // MARK: Actions
    @objc func toggleTapped() {
        if (rightBarbuttonItem?.title == ActionStrings.list.rawValue) {
            // Show tableview
            rightBarbuttonItem?.title = ActionStrings.map.rawValue
            remove(asChildViewController: mapVC)
            add(asChildViewController: listVC)
        }
        else {
            // Show Map
            rightBarbuttonItem?.title = ActionStrings.list.rawValue
            remove(asChildViewController: listVC)
            add(asChildViewController: mapVC)
        }
    }
    
    @IBAction func filterButtonTapped(_ sender: UIButton) {
        if (filterButtonsOpen) {
            // close
            filterObjectSelected = self.filterObjects.first(where: { $0.filterButton == sender } )!
            self.filterButtonsTopConstraints.forEach({ (constraint) in
                constraint.constant = 10
            })
            
            filterButtons.forEach { (button) in
                UIView.animate(withDuration: 0.35, animations: {
                    button.alpha = self.filterObjectSelected?.filterButton == button ? 1 : 0
                    button.isSelected = self.filterObjectSelected?.filterButton == button
                    button.superview?.layoutIfNeeded()
                }) { _ in
                    button.isHidden = !(self.filterObjectSelected?.filterButton == button)
                    
                }
            }
            
            self.doFilter()
        }
        else {
            // open
            filterButtons.forEach { (button) in
                guard let idx = self.filterButtonsTopConstraints.firstIndex(where: { $0.firstItem as! UIButton == button }) else { return }
                self.filterButtonsTopConstraints[idx].constant = 10 + (button.frame.height + 10) * CGFloat(idx)
                
                button.isHidden = false
                UIView.animate(withDuration: 0.35, animations: {
                    button.alpha = 1
                    button.superview?.layoutIfNeeded()
                })
            }
        }
        filterButtonsOpen = !filterButtonsOpen
    }
    
    @IBAction func locationButtonTapped(_ sender: UIButton) {
        self.mapVC.locationButtonTapped(sender)
    }
    
    // MARK: Additioanl views configure
    func addToggleNavigationItem() {
        rightBarbuttonItem = UIBarButtonItem(title: ActionStrings.list.rawValue, style: .plain, target: self, action: #selector(toggleTapped))
        self.navigationItem.rightBarButtonItem = rightBarbuttonItem
    }
    
    func addSheetView(controller: UIViewController) {
        self.addChild(controller)
        self.view.addSubview(controller.view)
        controller.didMove(toParent: self)
        
        if (controller.isKind(of: ActionViewController.self)) {
            (controller as! ActionViewController).actionCallback = self
        }

        let height = controller.view.frame.height
        let width  = view.frame.width
        let v = controller.view
        let topConstraint = v!.topAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        v!.constrain([
            v!.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            v!.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            topConstraint,
            v!.heightAnchor.constraint(equalToConstant: height),
            v!.widthAnchor.constraint(equalToConstant: width)
        ])
        v!.isHidden = true
        redeeemFlowAnimatableTopConstraints.append(topConstraint)
    }
    
    func addSendVerificationView() {
        sendVerificationVC = SendVerificationCodeViewController.init(nibName: "SendVerificationView", bundle: .module)
        addSheetView(controller: sendVerificationVC!)
    }
    
    func addVerifyCashCodeView() {
        verifyCashCodeVC = VerifyCashCodeViewController.init(nibName: "VerifyCashCodeView", bundle: .module)
        addSheetView(controller: verifyCashCodeVC!)
    }
    
    // MARK: Server Calls
    func getAtmList() {
        CoreSessionManager.shared.client!.getAtmList(result: { (result) in
            switch result {
            case .success(let response):
                if var items = response.data?.items {
                    // Filter out ATMs with no purchase or redeem
                    items = items.filter( { $0.redemption!.boolValue || $0.purchase!.boolValue })
                    self.atmList = items
                    self.update(items)
                }
                break
            case .failure(_):
                break
            }
        })
    }
    
}

// MARK: Appearance
extension AtmLocationsViewController {
    func setRoundBackgroundOnButtons() {
        // Set Filter button and My Location Button Appearance
        filterButtons.forEach { (button) in
            setViewAppearance(for: button)
        }
        setViewAppearance(for: myLocationButton)
    }
    
    func setViewAppearance(for view: UIView) {
        setLayerAppearance(for: view.layer)
        view.layer.cornerRadius = view.bounds.height/2
    }
    
    func setLayerAppearance(for layer: CALayer) {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.35
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 2
    }
    
    func setTextFieldAppearance() {
        textField = searchBar.textFld
        searchBar.clearBackgroundColor()
        textField!.textColor = .black
        
        self.setLayerAppearance(for: textField!.layer)
    }
}

// MARK: Map Filtering
extension AtmLocationsViewController {
    func update(_ atms: [AtmMachine]?) {
        self.mapVC.update(atms)
        self.listVC.update(atms)
    }
    
    func filter(by string: String = "") {
        var filter = filteredList
        if (!string.isEmpty) {
            filter = filter?.filter { (atm: AtmMachine) -> Bool in
                let stringLowercased = string.lowercased()
                return (atm.addressDesc?.lowercased().contains(stringLowercased))!
                    || (atm.city?.lowercased().contains(stringLowercased))!
                    || (atm.street?.lowercased().contains(stringLowercased))!
            }
            filteredList = filter
        }
    }
    
    func filterByAction() {
        var filter: [AtmMachine]? = filteredList
        if self.filterObjectSelected?.filterAction == .all {
            filteredList = filter
            return
        }
        if self.filterObjectSelected?.filterAction == .redeem {
            filter = filter?.filter( { $0.redemption!.boolValue })
        }
        else if self.filterObjectSelected?.filterAction == .purchase {
            filter = filter?.filter( { $0.purchase!.boolValue })
        }
        filteredList = filter
    }
    
    func doFilter() {
        filteredList = atmList
        filter(by: textField!.text!)
        filterByAction()
        update(filteredList)
    }
}

extension AtmLocationsViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        doFilter()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if filterButtonsOpen {
            filterButtonTapped((filterObjectSelected?.filterButton)!)
            filterButtonsOpen = false
        }
        doFilter()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Show all
        doFilter()
    }
    
    class func sendCoin(amount: String, address: String, completion: @escaping (() -> Void)) {
        let delegate = CoreSessionManager.shared.delegate!
        delegate.sendCoin(amount: amount, address: address, completion: completion)
    }
}

extension AtmLocationsViewController: ActionProtocol {
    
    func sendCashCode(_ cashCode: CashCode) {
        // Overriding the server state .AWAITING to be .SendPending in the UI so the user does not have to perform the whole flow.
        // The Server and the UI will be at sync once the user sends successfully.
        // NOTE: send can be performed somewhere else. For that case, the server sync will update the UI
        CoreTransactionManager.updateTransaction(status: .SendPending, address: cashCode.address!, code: cashCode.secureCode)
        
        AtmLocationsViewController.sendCoin(amount: cashCode.btcAmount!, address: cashCode.address!, completion: {
            [weak self] in
            guard let `self` = self else { return }
            
            CoreTransactionManager.updateTransaction(status: .Awaiting, address: cashCode.address!)
            
            let withdrawalStatusVC = WithdrawalStatusViewController.init(nibName: "WithdrawalStatusView", bundle: .module)
            withdrawalStatusVC.transaction = CoreTransactionManager.getTransaction(for: cashCode.address!)
            self.present(withdrawalStatusVC, animated: true, completion: nil)
        })
        actiondDidComplete(action: .cashCodeVerification)
    }
    
    func withdrawal(requested cashCode: CashCode) {
        showAlert(title: "Withdrawal Requested",
                  message: "Please send the amount of \(String(describing: cashCode.btcAmount!)) BTC to the ATM",
            buttonLabel: ActionStrings.send.rawValue,
            completion: { (action) in
                if (action.title == ActionStrings.send.rawValue) {
                    self.sendCashCode(cashCode)
                }
                else {
                    print("Show Details view")
                }
        })
    }
    
    func withdraw(amount: String) {
        self.verifyCashCodeVC!.amount = amount
    }
    
    func actiondDidComplete(action: Action?) {
        switch action {
        case .sendVerificationCode:
            self.sendVerificationVC!.view.endEditing(true)
            self.sendVerificationVC!.hideView()
            self.verifyCashCodeVC!.showView()
            break
        case .cashCodeVerification:
            self.verifyCashCodeVC!.view.endEditing(true)
            self.verifyCashCodeVC!.hideView()
            break
        default:
            break
        }
    }
    
    func add(asChildViewController viewController: UIViewController) {
        currentContainerViewVC = viewController
        addChild(viewController)
        containerView.addSubview(viewController.view)

        viewController.view.frame = view.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.didMove(toParent: self)
    }
    
    func remove(asChildViewController viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
}

extension UISearchBar {
    public var textField: UITextField {
        if #available(iOS 13.0, *) {
            return searchTextField
        }

        guard let firstSubview = subviews.first else {
            fatalError("Could not find text field")
        }

        for view in firstSubview.subviews {
            if let textView = view as? UITextField {
                return textView
            }
        }

       fatalError("Could not find text field")
    }
}
