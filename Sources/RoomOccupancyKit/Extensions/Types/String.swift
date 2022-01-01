//
//  String+Slug.swift
//  
//
//  Created by Emory Dunn on 5/24/21.
//

import Foundation

extension String {
    /// The normalized URL slug.
    ///
    /// The title of the gallery is:
    /// 1. Stripped of diacritics
    /// 2. Lower-cased
    /// 3. Spaces are replaced with hyphens
    var slug: String {
        let normString = self.applyingTransform(.stripDiacritics, reverse: false)?
            .applyingTransform(.stripCombiningMarks, reverse: false) ?? self
        
        return normString
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
    }
    
    /// Tests if receiver matches the specified regular expression
    /// - Parameter regex: The regular expression to match against
    func matches(regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression) != nil
    }
}
