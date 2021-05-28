//
//  File.swift
//  
//
//  Created by Emory Dunn on 5/27/21.
//

import Foundation

extension Int {
    var personUnitCount: String {
        self == 1 ? "person" : "people"
    }
    
    var icon: String {
        switch self {
        case 0:
            return "mdi:account-outline"
        case 1:
            return "mdi:account"
        case 2:
            return "mdi:account-multiple"
        default:
            return "mdi:account-group"
        }
    }
}
