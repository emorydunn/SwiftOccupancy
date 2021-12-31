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
    let count: Int
    
    var buffer: Int
    
    init(count: Int) {
        self.count = count
        self.buffer = count
    }
    
    var wrappedValue: Value? {
        get { bufferedValue }
        
        set {

            // If the new value isn't nil, set it
            if let newValue = newValue {
                self.bufferedValue = newValue
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
