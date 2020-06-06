//
//  ContactEntryController.swift
//  Loan Tracker
//
//  Created by Joe on 2020-05-04.
//  Copyright © 2020 Joe. All rights reserved.
//

import SQLite3
import UIKit

class ContactEntryController: UIViewController {

    
    var db: OpaquePointer? // Database
    @IBOutlet weak var loanStack: UIStackView! // Contains loans
    @IBOutlet weak var defaultLabel: UILabel! // Display if no loans
    var loanType : Double! // -1 or 1 depending on who's paying
    
    /* Contact attributes */
    var id : Int32!
    var balance : Double!
    
    /* Payment form */
    var paymentForm: UIStackView!
    var amountText : UITextField!
    
    /* Static view labels */
    @IBOutlet weak var nameLabel: PaddedLabel!
    @IBOutlet weak var detailLabel: PaddedLabel!
    @IBOutlet weak var letterLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Initialize UI */
        view.backgroundColor = UIColor.bg
        populateEntry()
        updateBalance()
        styleLabels()
        styleNavigationBar()
        if (numLoans() == 0) {
            defaultLabel.isHidden = false
        } else {
            defaultLabel.isHidden = true
        }
        
        loanType = 1 // Payment is user giving loan by default
    }
    
    /**************** BEGIN QUERIES ****************/
    func numLoans() -> Int32 {
        var queryStr = ""
        if let tempId = id {
            queryStr = "SELECT COUNT(*) FROM Table\(tempId)"
        }
        
        var query: OpaquePointer?
        var count = Int32(0)
        
        if sqlite3_prepare(db, queryStr, -1, &query, nil) == SQLITE_OK {
            if (sqlite3_step(query) == SQLITE_ROW){
                count = sqlite3_column_int(query, 0)
            }
            sqlite3_finalize(query)
        } else {
            print("Error preparing query [numLoans()]")
        }
        return count
    }
    
    func populateEntry() {
        var contactQuery = ""
        var loanQuery = ""
        if let tempId = id {
            contactQuery = "SELECT * FROM Contacts WHERE id = \(tempId)"
            loanQuery = "SELECT * FROM Table\(tempId)"
        } else {
            print("Invalid id")
            return
        }

        var query: OpaquePointer?

        if sqlite3_prepare(db, contactQuery, -1, &query, nil) == SQLITE_OK {
            if (sqlite3_step(query) == SQLITE_ROW){
                guard let name = sqlite3_column_text(query, 0) else {
                  print("Name query result is nil")
                  return
                }

                let nameStr = String(cString: name)

                guard let details = sqlite3_column_text(query, 1) else {
                    print("Details query result is nil")
                    return
                }
                let detailStr = String(cString: details)

                balance = sqlite3_column_double(query, 2)
                var balanceStr = String(format: "$%.2f", balance)
                
                if (balance > 0) {
                    balanceLabel.text = "\(nameStr) owes you \(balanceStr)"
                } else if (balance < 0) {
                    balanceStr = String(format: "$%.2f", abs(balance))
                    balanceLabel.text = "You owe \(nameStr) \(balanceStr)"
                } else {
                    balanceLabel.text = "You have no loans with \(balanceStr)"
                }
                
                nameLabel.text = nameStr
                nameLabel.setTop(10)
                
                detailLabel.text = detailStr
                detailLabel.setBottom(20)
                
                letterLabel.text = String(nameStr.prefix(1))
                letterLabel.clipsToBounds = true
                letterLabel.layer.cornerRadius = letterLabel.frame.height/2
                letterLabel.backgroundColor = UIColor.text
                letterLabel.textAlignment = .center
            }
        } else {
            print("Error preparing query [populateEntry()]")
        }
        sqlite3_finalize(query)
        
        if (sqlite3_prepare(db, loanQuery, -1, &query, nil) == SQLITE_OK) {
            while (sqlite3_step(query) == SQLITE_ROW){
                let loan = sqlite3_column_double(query, 0)
                addLoanLabel(loan)
            }
        }
        sqlite3_finalize(query)
    }
    
    func insert(_ loan: Double) {
        /* Update contacts table */
        var queryStr = ""
        var insertStr = ""
        if let tempId = id {
            if let tempBalance = balance {
                queryStr = "UPDATE Contacts set balance = \(tempBalance) WHERE id = \(tempId)"
                insertStr = "INSERT INTO Table\(tempId) (loan) VALUES (?);"
            }
        } else {
            print("Invalid id")
            return
        }
        
        var query: OpaquePointer?
        if sqlite3_prepare(db, queryStr, -1, &query, nil) == SQLITE_OK {
            if sqlite3_step(query) != SQLITE_DONE {
                print("Error updating row")
            }
            
            sqlite3_finalize(query)
        } else {
            print("Error preparing query")
        }
        
        /* Update loan table */
        if sqlite3_prepare(db, insertStr, -1, &query, nil) == SQLITE_OK {
            sqlite3_bind_double(query, 1, loan)
            
            if sqlite3_step(query) != SQLITE_DONE {
                print("Error inserting row")
            } else {
                addLoanLabel(loan)
            }
            sqlite3_finalize(query)
        } else {
            print("Error preparing query")
        }
        
        defaultLabel.isHidden = true
    }
    
    @objc func deleteEntry(_ sender: Any) {
        var queryStr = ""
        var deleteQuery = ""
        if let tempId = id {
            queryStr = "DELETE FROM Contacts WHERE id = \(tempId)"
            deleteQuery = "DROP TABLE IF EXISTS Table\(tempId)"
        } else {
            print("Invalid id")
            return
        }
        
        /* Delete entry from Contacts */
        var query: OpaquePointer?
        if sqlite3_prepare(db, queryStr, -1, &query, nil) == SQLITE_OK {
            if sqlite3_step(query) != SQLITE_DONE {
                print("Error deleting entry")
            }
            sqlite3_finalize(query)
        } else {
            print("Error preparing query")
        }
        
        /* Delete loan table from db */
        if (sqlite3_exec(db, deleteQuery, nil, nil, nil) != SQLITE_OK) {
            print("Error deleting table")
        } else {
            print("Table Deleted")
        }

        navigationController?.popToRootViewController(animated: true)
    }
    /**************** END QUERIES ****************/
    
    /**************** BEGIN MAIN UI ****************/
    func styleNavigationBar() {
        let dollarBtn = UIBarButtonItem( image: UIImage(named: "dollar"), style: .plain, target: self, action: #selector(showForm))
        let trashBtn = UIBarButtonItem( image: UIImage(named: "trash"), style: .plain, target: self, action: #selector(deleteEntry))
        trashBtn.imageInsets = UIEdgeInsets(top: 0.0, left: 40, bottom: 0, right: 0);
        navigationItem.setRightBarButtonItems([dollarBtn, trashBtn], animated: true)
    }
    
    func styleLabels() {
        letterLabel.textColor = UIColor.bg
        nameLabel.textColor = UIColor.text
        detailLabel.textColor = UIColor.text
        defaultLabel.textColor = UIColor.neutral
        balanceLabel.backgroundColor = UIColor.neutral
        balanceLabel.textColor = UIColor.text
    }
    
    func updateBalance() {
        balanceLabel.clipsToBounds = true
        balanceLabel.layer.cornerRadius = 5
        balanceLabel.textAlignment = .center
        var balanceStr : NSMutableAttributedString!
                
        if (balance > 0) {
            if let nameStr = nameLabel.text {
                balanceStr = NSMutableAttributedString(string: "\(nameStr) owes you ")
            } else {
                print("Invalid name")
                return
            }

            let attrStr = NSAttributedString(string: String(format: "$%.2f", balance))
            let range = NSRange(location: balanceStr.length, length: attrStr.length)
            balanceStr.append(attrStr)
            balanceStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.mainGreen, range: range)
        } else if (balance < 0) {
            if let nameStr = nameLabel.text {
                balanceStr = NSMutableAttributedString(string: "You owe \(nameStr) ")
            } else {
                print("Invalid name")
                return
            }
            
            let attrStr = NSAttributedString(string: String(format: "$%.2f", abs(balance)))
            let range = NSRange(location: balanceStr.length, length: attrStr.length)
            balanceStr.append(attrStr)
            balanceStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.mainRed, range: range)
        } else {
            balanceLabel.text = "You have no outstanding payments."
            return
        }

        balanceLabel.attributedText = balanceStr
    }
    
    func addLoanLabel(_ loan: Double) {
        let loanStr = String(format: "%.2f", loan)
        let newLoan = PaddedLabel()
        newLoan.setLeft(50)
        newLoan.backgroundColor = UIColor.entry
        newLoan.clipsToBounds = true
        newLoan.layer.cornerRadius = 5
        
        var loanImg : UIImageView!
        
        if let nameStr = nameLabel.text {
            if (loan > 0) {
                let img = UIImage(named: "positive-plain")?.withRenderingMode(.alwaysTemplate)
                loanImg = UIImageView(image: img)
                loanImg.tintColor = UIColor.mainGreen
                newLoan.text = "You paid \(nameStr) $\(loanStr)"
            } else if (loan < 0) {
                let img = UIImage(named: "negative-plain")?.withRenderingMode(.alwaysTemplate)
                loanImg = UIImageView(image: img)
                loanImg.tintColor = UIColor.mainRed
                newLoan.text = "\(nameStr) paid you $\(String(format: "%.2f", abs(loan)))"
            } else {
                return
            }
        }
        
        newLoan.textColor = UIColor.text
        loanImg.frame = CGRect(x: 17,y: 17,width: 20,height: 20)
        
        newLoan.addSubview(loanImg)
        newLoan.heightAnchor.constraint(equalToConstant: 55).isActive = true
        loanStack.addArrangedSubview(newLoan)
    }
    /**************** END MAIN UI ****************/

    /**************** BEGIN PAYMENT FORM ****************/
    @objc func showForm(_ sender: Any) {
        let titleView = UIStackView()
        let selfLabel = UILabel()
        selfLabel.text = "You"
        selfLabel.font = UIFont.systemFont(ofSize: 30)
        let contactLabel = UILabel()
        contactLabel.text = nameLabel.text
        contactLabel.font = UIFont.systemFont(ofSize: 30)
        let payDirection = UIButton() //replace if possible
        payDirection.addTarget(self, action: #selector(changeDirection), for: .touchUpInside)
        payDirection.setTitle(" \u{2192} ", for: .normal)
        payDirection.setTitleColor(UIColor.mainGreen, for: .normal)
        payDirection.titleLabel?.font = UIFont.systemFont(ofSize: 30)
        titleView.addArrangedSubview(selfLabel)
        titleView.addArrangedSubview(payDirection)
        titleView.addArrangedSubview(contactLabel)
        
        let paymentView = UIStackView()
        let dollarLabel = UILabel()
        dollarLabel.text = "$"
        amountText = UITextField()
        amountText.placeholder = "0.00"
        paymentView.distribution = .fill
        paymentView.addArrangedSubview(dollarLabel)
        paymentView.addArrangedSubview(amountText)
        dollarLabel.font = UIFont.systemFont(ofSize: 25)
        amountText.font = UIFont.systemFont(ofSize: 25)
        
        let cancelBtn = UIButton()
        cancelBtn.setTitle("Cancel", for: .normal)
        cancelBtn.backgroundColor = UIColor.entry
        cancelBtn.layer.cornerRadius = 5
        cancelBtn.addTarget(self, action: #selector(closeForm), for: .touchUpInside)
        
        let doneBtn = UIButton()
        doneBtn.setTitle("Done", for: .normal)
        doneBtn.backgroundColor = UIColor.entry
        doneBtn.layer.cornerRadius = 5
        doneBtn.addTarget(self, action: #selector(submitForm), for: .touchUpInside)
        
        let buttonView = UIStackView()
        buttonView.distribution = .fillEqually
        buttonView.spacing = 8
        buttonView.addArrangedSubview(cancelBtn)
        buttonView.addArrangedSubview(doneBtn)
        buttonView.widthAnchor.constraint(equalToConstant: 250).isActive = true
        
        /* Background for contact form */
        let background = UIView()
        background.backgroundColor = .white
        background.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                
        paymentForm = UIStackView()
        paymentForm.axis = .vertical
        paymentForm.distribution = .fill
        paymentForm.alignment = UIStackView.Alignment.center
        paymentForm.spacing = 20
        paymentForm.isLayoutMarginsRelativeArrangement = true
        paymentForm.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        paymentForm.widthAnchor.constraint(equalToConstant: 270).isActive = true
        paymentForm.insertSubview(background,at: 0)
        paymentForm.addArrangedSubview(titleView)
        paymentForm.addArrangedSubview(paymentView)
        paymentForm.addArrangedSubview(buttonView)
        
        /* Shadow background for pop-up form */
        let shadow = UIView()
        shadow.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        
        navigationController?.view.addSubview(shadow)
        shadow.frame.size.height = view.bounds.height
        shadow.frame.size.width = view.bounds.width

        shadow.addSubview(paymentForm)
        paymentForm.translatesAutoresizingMaskIntoConstraints = false
        paymentForm.centerXAnchor.constraint(equalTo: shadow.centerXAnchor).isActive = true
        paymentForm.centerYAnchor.constraint(equalTo: shadow.centerYAnchor).isActive = true
    }
    
    @objc func changeDirection(_ sender: UIButton) {
        if (loanType == 1) {
            sender.setTitle(" \u{2190} ", for: .normal)
            sender.setTitleColor(UIColor.mainRed, for: .normal)
            loanType = -1
        } else {
            sender.setTitle(" \u{2192} ", for: .normal)
            sender.setTitleColor(UIColor.mainGreen, for: .normal)
            loanType = 1
        }
    }
    
    @objc func closeForm (_ sender: UIButton) {
        paymentForm.superview?.removeFromSuperview()
    }
    
    @objc func submitForm (_ sender: UIButton) {
        let loanStr : String = amountText.text! as String
        
        if let loan = Double(loanStr) {
            balance += (loanType)*loan
            insert(loanType*loan)
            updateBalance()
        } else {
            print("Please enter a valid integer")
        }

        paymentForm.superview?.removeFromSuperview()
        return
    }
    /**************** END PAYMENT FORM ****************/
}
