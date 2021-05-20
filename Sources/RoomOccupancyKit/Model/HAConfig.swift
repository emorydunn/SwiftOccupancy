//
//  HAConfig.swift
//  ThermalViewer
//
//  Created by Emory Dunn on 5/20/21.
//

import Foundation

public struct HAConfig: Codable {
    public let url: URL
    public let token: String
    
    public init(url: URL, token: String) {
        self.url = url
        self.token = token
    }
}
