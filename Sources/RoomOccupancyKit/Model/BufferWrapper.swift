//
//  File.swift
//  
//
//  Created by Emory Dunn on 12/31/21.
//

import Foundation

@propertyWrapper
struct Buffer<Value> {
    var bufferedValue: Value?
    let bufferSize: Int
    
    var buffer: Int
    
    init(bufferSize: Int) {
        self.bufferSize = bufferSize
        self.buffer = bufferSize
    }

    var wrappedValue: Value? {
        get { bufferedValue }
        
        set {
            // If the new value isn't nil, store and reset the buffer
            if let newValue = newValue {
                self.bufferedValue = newValue
                buffer = bufferSize
            } else if buffer == 0 {
                // If the buffer is at 0, clear the value
                self.bufferedValue = nil
            } else {
                // Decrement the buffer
                buffer -= 1
            }

        }
        
    }
}
