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
    
    static let haAddOn = HAConfig(url: URL(string: "http://supervisor/core/api")!,
                                  token: supervisorToken)
    
    static var supervisorToken: String {
        guard let token = ProcessInfo.processInfo.environment["SUPERVISOR_TOKEN"] else {
            assertionFailure("SUPERVISOR_TOKEN was not found in the environment")
            return "missing env"
        }
        
        return token
    }

}
