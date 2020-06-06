//
//  PaddedTextfield.swift
//  Loan Tracker
//
//  Created by Joe on 2020-05-13.
//  Copyright © 2020 Joe. All rights reserved.
//

import UIKit

extension UITextField {
    func setLeftPadding(_ amount: CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}
