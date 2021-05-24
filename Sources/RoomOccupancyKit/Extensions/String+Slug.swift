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
    /// 1. Strpped of diacritics
    /// 2. Lower-cased
    /// 3. Spaces are replaced with hyphens
    var slug: String {
        let normString = self.applyingTransform(.stripDiacritics, reverse: false)?
            .applyingTransform(.stripCombiningMarks, reverse: false) ?? self
        
        return normString
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
    }
}
