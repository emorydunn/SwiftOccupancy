//
//  WebSocketTaskPublisher.swift
//  
//
//  Created by Emory Dunn on 5/23/21.
//

import Foundation
import Combine

extension URLSession {
    
    /// Returns a publisher that wraps a URL session WebSocket task for a given URL.
    /// 
    /// The provided URL must have a `ws` or `wss` scheme.
    /// - Parameter url: The WebSocket URL with which to connect.
    func webSocketTaskPublisher(for url: URL) -> WebSocketTaskPublisher {
        WebSocketTaskPublisher(with: url, session: self)
    }
}

/// A publisher that delivers the messages from a WebSocket.
public struct WebSocketTaskPublisher: Publisher {
    
    public typealias Output = URLSessionWebSocketTask.Message
    
    public typealias Failure = Error
    
    let task: URLSessionWebSocketTask
    
    /// Creates a WebSocket task publisher from the provided URL and URL session.
    ///
    /// The provided URL must have a `ws` or `wss` scheme.
    /// - Parameters:
    ///   - url: The WebSocket URL with which to connect.
    ///   - session: The URLSession to create the WebSocket task.
    public init(with url: URL, session: URLSession = URLSession.shared) {
        self.task = session.webSocketTask(with: url)
    }
    
//    /// Reads a WebSocket message and passes the result to the subscriber.
//    ///
//    /// This method calls itself when finished to repeatedly read messages.
//    ///
//    /// - Parameter subscriber: The subscriber to forward the message to.
//    func receiveMessage<S>(with subscriber: S) where S : Subscriber, Error == S.Failure, URLSessionWebSocketTask.Message == S.Input {
//        task.receive { result in
//            self.passResult(result, to: subscriber)
//            self.receiveMessage(with: subscriber)
//        }
//    }
//    
//    /// Pass either the message or error to the subscriber.
//    /// - Parameters:
//    ///   - result: Result of a WebSocket
//    ///   - subscriber: The subscriber to forward the message to.
//    func passResult<S>(_ result: Result<URLSessionWebSocketTask.Message, Error>, to subscriber: S) where S : Subscriber, Error == S.Failure, URLSessionWebSocketTask.Message == S.Input {
//        switch result {
//        case let .success(message):
//            subscriber.receive(message)
//        case let .failure(error):
//            subscriber.receive(completion: .failure(error))
//        }
//    }
//    
    public func receive<S>(subscriber: S) where S : Subscriber, Error == S.Failure, URLSessionWebSocketTask.Message == S.Input {
        
        let subscrption = Subscription(task: task, target: subscriber)
        subscriber.receive(subscription: subscrption)
        
        

        // Receive the first method
//        task.receive { firstMessage in
//            self.passResult(firstMessage, to: subscriber)
//            self.receiveMessage(with: subscriber)
//
//        }
        
    }
    
}

extension WebSocketTaskPublisher {
    class Subscription<Target: Subscriber>: Combine.Subscription where Target.Input == Output, Target.Failure == Error {
        
        let task: URLSessionWebSocketTask
        var target: Target?
        
        var isRunning: Bool = false
        
        init(task: URLSessionWebSocketTask, target: Target) {
            self.task = task
            self.target = target
        }
        
        func request(_ demand: Subscribers.Demand) {
            var demand = demand
            
            // Resume the task
            task.resume()

            while let target = target, demand > 0 {
                if !isRunning {
                    
                    isRunning = true

                    self.task.receive { result in
                        switch result {
                        case let .success(message):
                            demand -= 1
                            demand += target.receive(message)
                        case let .failure(error):
                            target.receive(completion: .failure(error))
                        }
                        
                        self.isRunning = false

                    }
                }
                
            }
        }
        
        func cancel() {
            task.cancel()
            target = nil
        }
    }
}
