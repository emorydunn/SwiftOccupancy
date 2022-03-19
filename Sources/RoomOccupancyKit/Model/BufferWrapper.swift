//
//  Buffer.swift
//  
//
//  Created by Emory Dunn on 12/31/21.
//

import Foundation

/// Buffers a value against being set as `nil` for the specified number of attempts.
/// ```
/// @Buffer(bufferSize: 5)
/// var buffered = "A Value"
///
/// buffered = nil // 5. buffered = "A Value"
/// buffered = nil // 4. buffered = "A Value"
/// buffered = nil // 3. buffered = "A Value"
/// buffered = nil // 2. buffered = "A Value"
/// buffered = nil // 1. buffered = "A Value"
/// buffered = nil // 0. buffered = nil
/// ```
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
