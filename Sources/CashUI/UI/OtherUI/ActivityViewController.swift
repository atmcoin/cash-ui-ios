// 
//  ActivityViewController.swift
//
//  Created by Giancarlo Pacheco on 5/22/20.
//
//  See the LICENSE file at the project root for license information.
//

import UIKit
import CashCore

let kReusableIdentifier = "kTableViewCellReuseIdentifier"

public class ActivityViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    
    var transactions: [CoreTransaction] {
        get {
            let trans = CoreTransactionManager.getTransactions()
            return trans.reversed()
        }
    }
    @IBOutlet open var tableView: UITableView!
    @IBOutlet open var navigationBar: UIView!
    @IBOutlet weak var refreshButton: LoadingButton!
    @IBOutlet weak var closeButton: UIButton!
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:#selector(refreshHandler),
                                 for: UIControl.Event.valueChanged)
        refreshControl.tintColor = UIColor.white
        
        return refreshControl
    }()
    
    public var shouldShowCloseButton: Bool = true
    
    private func commonInit() {
        closeButton.tintColor = Theme.color(.icon)
        closeButton.imageEdgeInsets = UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: "ActivityView", bundle: .module)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
        setup()
        setupNavigationBar();
        
        if !shouldShowCloseButton {
            closeButton.isHidden = true
        }
        NotificationCenter.default.addObserver(self, selector: #selector(transactionDidUpdate), name: .CoreTransactionDidChange, object: nil)
        
        refreshHandler(tableView as Any)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // TODO table view needs refreshing after any presentation controller dismisses
        refreshHandler(tableView as Any)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupNavigationBar() {
        navigationBar.layer.cornerRadius = 8
        navigationBar.clipsToBounds = true
        navigationBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    
    private func refresh(_ sender: Any) {
        CoreTransactionManager.pollImmediately()
    }

    
    // MARK: Helpers
    private func setup() {
        self.view.backgroundColor = Theme.tertiaryBackground
        let cellNib = UINib(nibName: "ActivityTableViewCell", bundle: .module)
        tableView.register(cellNib, forCellReuseIdentifier: kReusableIdentifier)
        tableView.backgroundColor = Theme.tertiaryBackground
        tableView.estimatedRowHeight = 199
        tableView.rowHeight = UITableView.automaticDimension
        tableView.refreshControl = refreshControl
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var frame = self.tableView.frame
        frame.size = CGSize(width: frame.width, height: (self.view.superview?.frame.height)! - self.tableView.frame.origin.y)
        self.tableView.frame = frame
    }
    
    @IBAction func refreshHandler(_ sender: Any) {
        self.refreshButton.showLoading()
        let deadlineTime = DispatchTime.now() + .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: { [weak self] in
            if #available(iOS 10.0, *) {
                self?.refresh(sender)
                self?.refreshButton.hideLoading()
                self?.refreshControl.endRefreshing()
            }
            self?.tableView.reloadData()

        })
    }
    
    @objc func transactionDidUpdate(_ notification: Notification) {
        self.tableView.reloadData()
    }
    
    @IBAction func closeView(_ sender: Any) {
        self.dismiss(animated: true)
    }
}

extension ActivityViewController: UITableViewDataSource, UITableViewDelegate {

    public func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return self.transactions.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: kReusableIdentifier, for: indexPath) as! ActivityTableViewCell
        cell.transaction = self.transactions[indexPath.row]
        return cell
    }

    public func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ActivityTableViewCell.heightForTableViewCell()
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let transaction = transactions[indexPath.row]

        let withdrawalStatusVC = WithdrawalStatusViewController.init(nibName: "WithdrawalStatusView", bundle: .module)
        withdrawalStatusVC.transaction = transaction
        self.present(withdrawalStatusVC, animated: true, completion: nil)
    }
    
    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let transaction = self.transactions[indexPath.row]
        if transaction.status == .Cancelled {
            return true
        }
        return false
    }
    
    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let transaction = self.transactions[indexPath.row]
        if editingStyle == .delete {
            CoreTransactionManager.remove(transaction)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
