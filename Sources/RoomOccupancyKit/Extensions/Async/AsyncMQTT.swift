////
////  AsyncMQTT.swift
////
////
////  Created by Emory Dunn on 11/20/21.
////
//
import Foundation
import MQTT
import NIOSSL

public class AsyncMQTTClient {
    public let client: MQTTClient
    
    var packetContinuation: AsyncThrowingStream<MQTTPacket, Error>.Continuation?
    var stateContinuation: AsyncStream<ConnectionState>.Continuation?
    
    public init(client: MQTTClient) {
        self.client = client
        self.client.delegate = self
    }
    
    public convenience init(
        host: String,
        port: Int,
        clientID: String = "",
        cleanSession: Bool,
        keepAlive: UInt16 = 30,
        willMessage: PublishMessage? = nil,
        username: String? = nil,
        password: String? = nil,
        tlsConfiguration: TLSConfiguration? = nil,
        connectTimeout: Int64 = 5
    ) {
        self.init(client: MQTTClient(host: host,
                                     port: port,
                                     clientID: clientID,
                                     cleanSession: cleanSession,
                                     keepAlive: keepAlive,
                                     willMessage: willMessage,
                                     username: username,
                                     password: password,
                                     tlsConfiguration: tlsConfiguration,
                                     connectTimeout: connectTimeout))
    }
    
    public var packets: AsyncThrowingStream<MQTTPacket, Error> {
        AsyncThrowingStream { continuation in
            self.packetContinuation = continuation
        }
    }
    
    public var state: AsyncStream<ConnectionState> {
        AsyncStream { continuation in
            self.stateContinuation = continuation
        }
    }
}

public extension AsyncMQTTClient {
    
    
    /// Connect to the MQTT server and await the connection acknowledgment packet.
    func connect() async throws {
        
        client.connect()

        _ = try await packets.first { $0 is ConnAckPacket }
        
    }
    
    func disconnect() {
        client.disconnect()
    }
    
    func subscribe(topic: String, qos: QoS, identifier: UInt16? = nil) {
        client.subscribe(topic: topic, qos: qos, identifier: identifier)
    }
    
    func publish(topic: String, retain: Bool, qos: QoS, payload: DataEncodable, identifier: UInt16? = nil) {
        client.publish(topic: topic, retain: retain, qos: qos, payload: payload, identifier: identifier)
    }
    
}

extension AsyncMQTTClient: MQTTClientDelegate {
    public func mqttClient(_ client: MQTTClient, didChange state: ConnectionState) {
        self.stateContinuation?.yield(state)
    }
    
    public func mqttClient(_ client: MQTTClient, didReceive packet: MQTTPacket) {
        self.packetContinuation?.yield(packet)
    }
    
    public func mqttClient(_ client: MQTTClient, didCatchError error: Error) {
        self.packetContinuation?.finish(throwing: error)
    }
}
