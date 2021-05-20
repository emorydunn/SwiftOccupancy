//
//  MinValueWrapper.swift
//  ThermalViewer
//
//  Created by Emory Dunn on 5/16/21.
//

import Foundation
import SwiftUI

@propertyWrapper
struct MinValue {
    
    @State
    var value: Int
    
    init(wrappedValue value: Int) {
        self.value = value
    }
    
    var wrappedValue: Int {
        get { value }
        set {
            value = max(0, value)
        }
    }
}
