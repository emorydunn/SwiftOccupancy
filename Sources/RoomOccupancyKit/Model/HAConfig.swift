//
//  HAConfig.swift
//  ThermalViewer
//
//  Created by Emory Dunn on 5/20/21.
//

import Foundation
//import MQTT

public struct HAConfig: Codable {
    public let url: URL
    public let token: String
    
    public init(url: URL, token: String) {
        self.url = url
        self.token = token
    }
    
    public static let haAddOn = HAConfig(url: URL(string: "http://supervisor/core/api")!,
                                  token: supervisorToken)
    
    static var supervisorToken: String {
        guard let token = ProcessInfo.processInfo.environment["SUPERVISOR_TOKEN"] else {
//            assertionFailure("SUPERVISOR_TOKEN was not found in the environment")
            return "missing env"
        }
        
        return token
    }

}

public struct HAMQTTConfig: Decodable {
    
    public let host: String
    public let port: Int
    public let username: String?
    public let password: String?
    
    public init(host: String = "homeassistant.local", port: Int = 1883, username: String?, password: String?) {
        self.host = host
        self.port = port
        self.username = username
        self.password = password
    }
    
//    func makeClient() -> MQTTClient {
//        MQTTClient(host: host,
//                   port: port,
//                   clientID: "SwiftOccupancy-\(ProcessInfo.processInfo.hostName)-\(ProcessInfo.processInfo.processIdentifier)",
//                   cleanSession: true,
//                   keepAlive: 30,
//                   username: username,
//                   password: password)
//    }
    
}
