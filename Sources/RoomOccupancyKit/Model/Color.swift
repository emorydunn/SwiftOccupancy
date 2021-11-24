//
//  File.swift
//  
//
//  Created by Emory Dunn on 11/24/21.
//

import Foundation
import Silica

public struct Color {
    let red: Float
    let green: Float
    let blue: Float
    
    var cgColor: Silica.CGColor {
        CGColor(red: CGFloat(red) / 255,
                green: CGFloat(green) / 255,
                blue: CGFloat(blue) / 255,
                alpha: 1)
        
    }
}
