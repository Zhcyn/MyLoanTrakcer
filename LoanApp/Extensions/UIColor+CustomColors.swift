//
//  Extensions.swift
//  Loan Tracker
//
//  Created by Joe on 2020-05-12.
//  Copyright © 2020 Joe. All rights reserved.
//

import UIKit

extension UIColor {
    class var bg: UIColor {
        return UIColor.rgb(fromHex: 0x2c215c)
    }
    
    class var mainGreen: UIColor {
        return UIColor.rgb(fromHex: 0x2ec7bf)
    }
    
    class var mainRed: UIColor {
        return UIColor.rgb(fromHex: 0xfd9072)
    }
    
    class var neutral: UIColor {
        return UIColor.rgb(fromHex: 0x40327d)
    }
    
    class var entry: UIColor {
        
        return UIColor.rgb(fromHex: 0x201163)
    }
    
    class var text: UIColor {
        return UIColor.white
    }
    
//    class var header: UIColor {
//        return UIColor.white
//    }
    
    class func rgb(fromHex: Int) -> UIColor {
        let red =   CGFloat((fromHex & 0xFF0000) >> 16) / 0xFF
        let green = CGFloat((fromHex & 0x00FF00) >> 8) / 0xFF
        let blue =  CGFloat(fromHex & 0x0000FF) / 0xFF
        let alpha = CGFloat(1.0)
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}


