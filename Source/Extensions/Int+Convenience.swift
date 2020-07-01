//
//  Int+Convenience.swift
//  Flexapp
//
//  Created by John Coates on 11/9/16.
//  Copyright © 2016 John Coates. All rights reserved.
//

import Foundation

extension BinaryInteger {
    var hex: String {
        return String.init(self, radix: 16, uppercase: false)
    }
}

extension UInt64 {
    var untaggedPointer: UInt64 {
        // superclass example: 0x40080000000009e2
        return self & 0xFFFFFFFFFF
    }
}
