//
//  ListViewController.swift
//
//  Created by Giancarlo Pacheco on 5/14/20.
//
//  See the LICENSE file at the project root for license information.
//

import UIKit
import CashCore

class ListViewController: UIViewController, ATMListFilter {
    
    private let reusableIdentifier = "ListTableCellReusableIdentifier"

    public var filteredList: [AtmMachine]?
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noResultsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "ListViewTableViewCell", bundle: nil), forCellReuseIdentifier: reusableIdentifier)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        view.backgroundColor = .white
        tableView.backgroundColor = .clear
        addConstraints()
        
        let parent = self.parent as! AtmLocationsViewController
        parent.searchBackgroundView.backgroundColor = .white
        parent.myLocationButton.isHidden = true
    }
    
    func addConstraints() {
        let parent = self.parent as! AtmLocationsViewController
        view.constrain([
            view.topAnchor.constraint(equalTo: parent.searchBackgroundView.bottomAnchor, constant: 0),
            view.leadingAnchor.constraint(equalTo: parent.containerView.leadingAnchor, constant: 0),
            view.trailingAnchor.constraint(equalTo: parent.containerView.trailingAnchor, constant: 0),
            view.bottomAnchor.constraint(equalTo: parent.containerView.bottomAnchor, constant: 0.0)
        ])
        tableView.constrain([
            tableView.topAnchor.constraint(equalTo: parent.searchBackgroundView.bottomAnchor, constant: 0),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0.0)
        ])

    }
    
    @objc public func containerViewTapped(_ sender: Any) {
        view.endEditing(true)
        let parent = self.parent as! AtmLocationsViewController
        parent.searchBar.resignFirstResponder()
    }
}

// MARK: Map Filtering
extension ListViewController {
    func update(_ atms: [AtmMachine]?) {
        filteredList = atms
        tableView?.isHidden = filteredList?.count == 0
        noResultsLabel?.isHidden = !(filteredList?.count == 0)
        tableView?.reloadData()
    }
}

extension ListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reusableIdentifier, for: indexPath) as! ListViewTableViewCell
        let atm = self.filteredList![indexPath.row] as AtmMachine
        cell.atm = atm
        cell.presentationController = self
        
        return cell
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let atm = self.filteredList![indexPath.row] as AtmMachine
        if atm.redemption!.boolValue {
            return indexPath
        } else {
            return nil  // returning nil indicates do not select
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        containerViewTapped(tableView)
        let atm = self.filteredList![indexPath.row] as AtmMachine
        let parent = self.parent as! AtmLocationsViewController
        parent.sendVerificationVC?.setAtmInfo(atm)
        parent.verifyCashCodeVC?.atmMachineTitleLabel.text = atm.addressDesc
        parent.sendVerificationVC?.showView()
        parent.verifyCashCodeVC!.atm = atm
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76
    }
}

extension ListViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let list = self.filteredList {
            return list.count
        }
        return 0
    }
}
