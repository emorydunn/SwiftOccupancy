//
//  XMLElement.swift
//  
//
//  Created by Emory Dunn on 9/7/21.
//

import Foundation

#if canImport(FoundationXML)
import FoundationXML
#endif

extension XMLElement {

    /// Adds an attribute node to the receiver.
    /// - Parameters:
    ///   - value: The value to be converted into a string
    ///   - key: Name of the attribute
    public func addAttribute(_ value: CustomStringConvertible, forKey key: String) {
        let attr = XMLNode(kind: .attribute)
        attr.name = key
        attr.stringValue = String(describing: value)

        addAttribute(attr)
    }
}
