//
//  Double.swift
//  
//
//  Created by Emory Dunn on 9/7/21.
//

import Foundation
import Silica

extension Double {
    /// Normalize the temperature to a value between `0` and `1`
    /// - Parameters:
    ///   - min: Min temp (`0`)
    ///   - max: Max temp (`1`)
    /// - Returns: Normalized temp
    public func normalize(_ min: Double, _ max: Double) -> Double {
        (self - min) / (max - min)
    }

    public func temp(_ min: Double, _ max: Double) -> Int {
        let hue = normalize(min, max) * 360
        
        var newHue = hue + 90
        if newHue > 360 {
            newHue -= 360
        }
        
        return Int(newHue)
    }

}

extension Float {
    
    /// Normalize the temperature to a value between `0` and `1`
    /// - Parameters:
    ///   - min: Min temp (`0`)
    ///   - max: Max temp (`1`)
    /// - Returns: Normalized temp
    public func normalize(_ minValue: Self, _ maxValue: Self, extend: Bool = false) -> Self {
        
        let minValue = extend ? min(minValue, self) : minValue
        let maxValue = extend ? max(maxValue, self) : maxValue
        
        return (self - minValue) / (maxValue - minValue)
    }
    
    public func mapHue(_ min: Self, _ max: Self) -> Self {
        let hue = normalize(min, max, extend: true) * 360
        
        var newHue = hue + 90
        if newHue > 360 {
            newHue -= 360
        }
        
        return newHue / 360
    }

    public func mapHue(_ min: Self, _ max: Self) -> Int {
        let hue = normalize(min, max, extend: true) * 360
        
        var newHue = hue + 90
        if newHue > 360 {
            newHue -= 360
        }
        
        return Int(newHue)
    }
    
    func mapColor(into gradient: [Self: Color], _ minValue: Self, _ maxValue: Self) -> Color {
        let value = self.normalize(minValue, maxValue)
        
        // Check if the value is exact
        if let color = gradient[value] {
            return color
        }

        // Pick the two colors the value is between
        var gradStops = Array(gradient.keys)
        gradStops.append(value)
        gradStops.sort()

        let index = gradStops.firstIndex(of: value)!

        let firstStop = gradStops[index - 1]
        let lastStop = gradStops[index + 1]
  
        let gradStart = gradient[firstStop]!
        let gradEnd = gradient[lastStop]!

        let red: Self =     0.2 * gradStart.red     /   lastStop + 0.8 * gradEnd.red
        let green: Self =   0.2 * gradStart.green   /   lastStop + 0.8 * gradEnd.green
        let blue: Self =    0.2 * gradStart.blue    /   lastStop + 0.8 * gradEnd.blue
        
        return Color(red: red, green: green, blue: blue)
        
    }
    
    /// From https://gist.github.com/mjackson/5311256
    public func tempColor(_ min: Self, _ max: Self) -> Silica.CGColor {
        let hue: Float = mapHue(min, max)
        let sat: Float = 1.0
        let light: Float = 0.5
        
        let q = light < 0.5 ? light * (1 + sat) : light + sat - light * sat
        let p = 2 * light - q
        
        let r = hue2RGB(p: p, q: q, t: hue + 1 / 3)
        let g = hue2RGB(p: p, q: q, t: hue)
        let b = hue2RGB(p: p, q: q, t: hue - 1 / 3)
        
        return Silica.CGColor(red: CGFloat(r),
                green: CGFloat(g),
                blue: CGFloat(b),
                alpha: 1)
    }
    
    func hue2RGB(p: Self, q: Self, t: Self) -> Self {
        var t = t
        
        if t < 0 { t += 1 }
        if t > 1 { t -= 1 }
        
        if t < 1/6 { return p + (q - p) * 6 * t }
        if t < 1/2 { return q }
        if t < 2/3 { return p + (q - p) * (2 / 3 - t) * 6 }
        
        return p
    }

}
