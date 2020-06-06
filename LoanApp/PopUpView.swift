//
//  PopUpView.swift
//  Loan Tracker
//
//  Created by Joe on 2020-05-01.
//  Copyright © 2020 Joe. All rights reserved.
//

import UIKit

class PopUpView: UIView {

    var contactStack : UIStackView!
    var title: UILabel!
    var name : UITextField!
    var details: UITextField!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .lightGray
        
        contactStack = UIStackView()
        contactStack.axis = .vertical
        
        title = UILabel()
        title.text = "Create Contact"
        title.textColor = .black
        
        name = UITextField()
        name.text = "Name"
        name.textColor = .black
        
        details = UITextField()
        details.text = "Email/phone number"
        details.textColor = .black
        
//        contactStack.addArrangedSubview(title)
//        contactStack.addArrangedSubview(name)
//        contactStack.addArrangedSubview(details)
//        addSubview(contactStack)
        addSubview(title)
        addSubview(name)
        addSubview(details)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
