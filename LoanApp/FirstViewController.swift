//
//  FirstViewController.swift
//  Loan Tracker
//
//  Created by Joe on 2020-04-29.
//  Copyright © 2020 Joe. All rights reserved.
//

import UIKit
import SQLite3

class FirstViewController: UIViewController {
    
    var db: OpaquePointer? // Database
    @IBOutlet weak var defaultLabel: UILabel! // Displays if no contacts
    @IBOutlet weak var contactStack: UIStackView! // Contains contacts
    
    /* Static view labels */
    @IBOutlet weak var givenLabel: UILabel!
    @IBOutlet weak var takenLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    
    /* Contact creation form */
    var contactForm: UIStackView!
    var nameText: UITextField!
    var detailsText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /* Initialize databases */
        createTable()
        populateContacts()

        /* Initialize UI */
        view.backgroundColor = UIColor.bg
        defaultLabel.textColor = UIColor.neutral
        styleNavBar()
        styleLabels()
        updateLabels()
    }
    
    func styleLabels() {
        givenLabel.clipsToBounds = true
        givenLabel.layer.cornerRadius = 5
        givenLabel.textColor = UIColor.text
        givenLabel.backgroundColor = UIColor.mainGreen
        
        takenLabel.clipsToBounds = true
        takenLabel.layer.cornerRadius = 5
        takenLabel.textColor = UIColor.text
        takenLabel.backgroundColor = UIColor.mainRed
        
        balanceLabel.clipsToBounds = true
        balanceLabel.layer.cornerRadius = 5
        balanceLabel.textAlignment = .center
        balanceLabel.textColor = UIColor.text
        balanceLabel.backgroundColor = UIColor.neutral
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        for view in contactStack.subviews {
            view.removeFromSuperview()
        }
        populateContacts()
        updateLabels()
        if (numContacts() == 0) {
            defaultLabel.isHidden = false
        } else {
            defaultLabel.isHidden = true
        }
    }
    
    /**************** BEGIN QUERIES ****************/
    func createTable() {
            let fileURL = try!
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("data.sqlite")
            if (sqlite3_open(fileURL.path, &db) != SQLITE_OK){
                print("Database error")
            }
            
            let query = "CREATE TABLE IF NOT EXISTS Contacts (name TEXT, email TEXT, balance CURRENCY, id INT);"
            
            if (sqlite3_exec(db, query, nil, nil, nil) != SQLITE_OK) {
                print("Error creating table")
            }
        }
    
    func populateContacts() {
        var query : OpaquePointer?
        let queryStr = "SELECT * FROM Contacts"
        if (sqlite3_prepare(db, queryStr, -1, &query, nil) == SQLITE_OK) {
            while (sqlite3_step(query) == SQLITE_ROW){
                guard let name = sqlite3_column_text(query, 0) else {
                  print("Name query result is nil")
                  return
                }
                
                let nameStr = String(cString: name)
                let balance = sqlite3_column_double(query, 2)
                let id = sqlite3_column_int(query, 3)

                addContactButton(id, nameStr, balance)
            }
        }
        sqlite3_finalize(query)
    }
    
    func numContacts() -> Int32 {
        let queryStr = "SELECT COUNT(*) FROM Contacts"
        var query: OpaquePointer?
        var count = Int32(0)

        if sqlite3_prepare(db, queryStr, -1, &query, nil) == SQLITE_OK {
            if (sqlite3_step(query) == SQLITE_ROW){
                count = sqlite3_column_int(query, 0)
            }
            sqlite3_finalize(query)
        } else {
            print("Error preparing query [numContacts()]")
        }
        return count
    }
    
    func getLoansGiven() -> Double {
        var query : OpaquePointer?
        let queryStr = "SELECT balance FROM Contacts WHERE balance > 0"
        var totalGiven = 0.0
        if (sqlite3_prepare(db, queryStr, -1, &query, nil) == SQLITE_OK) {
            while (sqlite3_step(query) == SQLITE_ROW){
                totalGiven += sqlite3_column_double(query, 0)
            }
        }
        sqlite3_finalize(query)
        return totalGiven
    }
    
    func getLoansTaken() -> Double {
        var query : OpaquePointer?
        let queryStr = "SELECT balance FROM Contacts WHERE balance < 0"
        var totalTaken = 0.0
        if (sqlite3_prepare(db, queryStr, -1, &query, nil) == SQLITE_OK) {
            while (sqlite3_step(query) == SQLITE_ROW){
                totalTaken += sqlite3_column_double(query, 0)
            }
        }
        sqlite3_finalize(query)
        return abs(totalTaken)
    }
    
    func insert() {
        /* New entry for contact */
        let queryStr = "INSERT INTO Contacts (name, email, balance, id) VALUES (?, ?, ?, ?);"
        var query: OpaquePointer?
        let id = getMaxId() + 1

        if sqlite3_prepare(db, queryStr, -1, &query, nil) == SQLITE_OK {
            let name: NSString = nameText.text! as NSString
            let details: NSString = detailsText.text! as NSString
            let balance = Double(0)

            sqlite3_bind_text(query, 1, name.utf8String, -1, nil)
            sqlite3_bind_text(query, 2, details.utf8String, -1, nil)
            sqlite3_bind_double(query, 3, balance)
            sqlite3_bind_int(query, 4, id)

            addContactButton(id, String(name), balance)
            defaultLabel.isHidden = true
            
            if sqlite3_step(query) != SQLITE_DONE {
                print("Error inserting row")
            }
            
            sqlite3_finalize(query)
        } else {
            print("Error preparing query")
        }
        
        /* Loan table for contact */
        let fileURL = try!
        FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("data.sqlite")
        if (sqlite3_open(fileURL.path, &db) != SQLITE_OK){
            print("Database error")
        }
        
        let tableQuery = "CREATE TABLE IF NOT EXISTS Table\(id) (loan CURRENCY);"
        
        if (sqlite3_exec(db, tableQuery, nil, nil, nil) != SQLITE_OK) {
            print("Error creating table")
        }
    }
    
    func getMaxId() -> Int32 {
        let queryStr = "SELECT MAX(id) FROM Contacts"
        var query: OpaquePointer?
        var maxId = Int32(0)

        if sqlite3_prepare(db, queryStr, -1, &query, nil) == SQLITE_OK {
            if (sqlite3_step(query) == SQLITE_ROW){
                maxId = sqlite3_column_int(query, 0)
            }
            sqlite3_finalize(query)
        } else {
            print("Error preparing query [getMaxId()]")
        }
        return maxId
    }
    /**************** END QUERIES ****************/
    
    /**************** BEGIN MAIN UI ****************/
    func updateLabels() {
        let attr = [ NSAttributedString.Key.font: UIFont(name: "Helvetica", size: 16.0)! ]
        let given = getLoansGiven()
        let taken = getLoansTaken()
        let balance = given - taken
        var balanceStr : NSMutableAttributedString!
        
        let givenStr = NSMutableAttributedString(string: String(format: "$%.2f", given))
        var str = NSAttributedString(string: "\nLoans Given", attributes: attr )
        givenStr.append(str)
        givenLabel.attributedText = givenStr
        
        let takenStr = NSMutableAttributedString(string: String(format: "$%.2f", taken))
        str = NSAttributedString(string: "\nLoans Taken", attributes: attr )
        takenStr.append(str)
        takenLabel.attributedText = takenStr
        
        if (balance > 0) {
            balanceStr = NSMutableAttributedString(string: "Your balance is ")
            let attrStr = NSAttributedString(string: String(format: "$%.2f", balance))
            balanceStr.append(attrStr)
            let range = NSRange(location: 16, length: attrStr.length)
            balanceStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.mainGreen, range: range)
        } else if (balance < 0) {
            balanceStr = NSMutableAttributedString(string: "Your balance is ")
            let attrStr = NSAttributedString(string: String(format: "$%.2f", abs(balance)))
            balanceStr.append(attrStr)
            let range = NSRange(location: 16, length: attrStr.length)
            balanceStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.mainRed, range: range)
        } else {
            balanceLabel.text = "No outstanding loans"
            return
        }

        balanceLabel.attributedText = balanceStr
    }
    
    func styleNavBar() {
        /* Customizing navigation bar */
        navigationController?.navigationBar.tintColor = UIColor.text
        navigationController?.navigationBar.titleTextAttributes = [ NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 22), NSAttributedString.Key.foregroundColor: UIColor.text]
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "add"), style: .plain, target: self, action: #selector(self.showForm))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    func addContactButton(_ id: Int32, _ name: String, _ balance: Double) {
        let balanceStr = String(format: "%.2f", balance)
        
        let newContact = UIButton()
        newContact.tag = Int(id)
        newContact.addTarget(self, action: #selector(contactEntry), for: .touchUpInside)
        newContact.contentHorizontalAlignment = .left;
        newContact.clipsToBounds = true
        newContact.layer.cornerRadius = 5
        newContact.backgroundColor = UIColor.entry
        newContact.setTitleColor(UIColor.text, for: .normal)
        newContact.titleLabel?.lineBreakMode = .byWordWrapping
        newContact.titleEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        newContact.contentEdgeInsets = UIEdgeInsets(top: 15, left: 20, bottom: 15, right: 0)
                
        if (balance > 0) {
            let btnImage = UIImage(named: "positive")
            let tintedImage = btnImage?.withRenderingMode(.alwaysTemplate)
            newContact.setImage(tintedImage, for: .normal)
            newContact.tintColor = UIColor.mainGreen
            newContact.setTitle("\(name)\nThey owe $\(balanceStr)", for: .normal)
        } else if (balance < 0) {
            let btnImage = UIImage(named: "negative")
            let tintedImage = btnImage?.withRenderingMode(.alwaysTemplate)
            newContact.setImage(tintedImage, for: .normal)
            newContact.tintColor = UIColor.mainRed
            newContact.setTitle("\(name)\nYou owe $\(String(format: "%.2f", abs(balance)))", for: .normal)
        } else {
            let btnImage = UIImage(named: "check")
            let tintedImage = btnImage?.withRenderingMode(.alwaysTemplate)
            newContact.setImage(tintedImage, for: .normal)
            newContact.tintColor = UIColor.neutral
            newContact.setTitle("\(name)\nNo loans", for: .normal)
        }
        
        contactStack.addArrangedSubview(newContact)
    }

    @objc func contactEntry(_ sender: Any) {
           performSegue(withIdentifier: "showContactEntry", sender: sender)
    }
       
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destVC = segue.destination as! ContactEntryController
        destVC.db = self.db
        if let senderBtn = sender as? UIButton {
            destVC.id = Int32(senderBtn.tag)
        }
    }
    /**************** END MAIN UI ****************/
    
    /**************** BEGIN CONTACT FORM ****************/
    @objc func showForm(_ sender: Any) {
        let title = UILabel()
        title.text = "Create Contact"
        title.textColor = UIColor.bg
        title.font = UIFont.systemFont(ofSize: 35)
        title.textAlignment = .center
        
        nameText = UITextField()
        nameText.placeholder = "Name"
        nameText.font = UIFont(name: "Helvetica", size: 18)
        nameText.borderStyle = .roundedRect
        nameText.backgroundColor = UIColor(red: 227/255, green: 227/255, blue: 227/255, alpha: 1)
        nameText.setLeftPadding(10)
        
        detailsText = UITextField()
        detailsText.placeholder = "Email/phone number"
        
        detailsText.font = UIFont(name: "Helvetica", size: 18)
        detailsText.borderStyle = .roundedRect
        detailsText.backgroundColor = UIColor(red: 227/255, green: 227/255, blue: 227/255, alpha: 1)
        detailsText.setLeftPadding(10)
        
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

        /* Background for contact form */
        let background = UIView()
        background.backgroundColor = UIColor.text
        background.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        contactForm = UIStackView()
        contactForm.axis = .vertical
        contactForm.distribution = .fill
        contactForm.alignment = UIStackView.Alignment.fill
        contactForm.spacing = 15
        contactForm.isLayoutMarginsRelativeArrangement = true
        contactForm.widthAnchor.constraint(equalToConstant: 330).isActive = true
        contactForm.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 60, trailing: 20)
        contactForm.insertSubview(background,at: 0)
        contactForm.addArrangedSubview(title)
        contactForm.addArrangedSubview(nameText)
        contactForm.addArrangedSubview(detailsText)
        contactForm.addArrangedSubview(buttonView)
        
        /* Shadow background for pop-up form */
        let shadow = UIView()
        shadow.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
       
        navigationController?.view.addSubview(shadow)
        shadow.frame.size.height = view.bounds.height
        shadow.frame.size.width = view.bounds.width

        shadow.addSubview(contactForm)
        contactForm.translatesAutoresizingMaskIntoConstraints = false
        contactForm.centerXAnchor.constraint(equalTo: shadow.centerXAnchor).isActive = true
        contactForm.centerYAnchor.constraint(equalTo: shadow.centerYAnchor).isActive = true
    }
    
    @objc func closeForm (_ sender: UIButton) {
        contactForm.superview?.removeFromSuperview()
    }
    
    @objc func submitForm (_ sender: UIButton) {
        insert()
        contactForm.superview?.removeFromSuperview()
    }
    /**************** END CONTAT FORM ****************/
}
