//
//  PaddedLabel.swift
//  Loan Tracker
//
//  Created by Joe on 2020-05-13.
//  Copyright © 2020 Joe. All rights reserved.
//

import UIKit

@IBDesignable class PaddedLabel: UILabel {
    var topInset : CGFloat = 0
    var leftInset : CGFloat = 0
    var bottomInset : CGFloat = 0
    var rightInset : CGFloat = 0
    
    func setTop(_ padding: CGFloat){
        topInset = padding
    }
    
    func setLeft(_ padding: CGFloat){
        leftInset = padding
    }
    
    func setBottom(_ padding: CGFloat){
        bottomInset = padding
    }
    
    func setRight(_ padding: CGFloat){
        rightInset = padding
    }
    
    public override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }
}
