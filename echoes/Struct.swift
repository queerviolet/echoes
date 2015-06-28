//
//  Struct.swift
//  echoes
//
//  Created by Ashi Krishnan on 6/26/15.
//  Copyright © 2015 Ashi Krishnan. All rights reserved.
//

import Foundation

func writeStruct<T>(toFile file: NSFileHandle, obj: T) {
    let mirror = reflect(obj)
    let sz = sizeofValue(obj)
    
    // Super complex record format:
    // [size of struct: UInt32 (4 bytes)]
    // [the struct (next (size of struct) bytes)]
    var bytes:[UInt8] = [UInt8](count: sz + 4, repeatedValue: 0)
    var offset:Int = 0
    
    func writeInt32(val: UInt32) {
        let swapped = CFSwapInt32HostToBig(val)
        bytes[offset++] = UInt8((swapped >> 3) & 0xFF)
        bytes[offset++] = UInt8((swapped >> 2) & 0xFF)
        bytes[offset++] = UInt8((swapped >> 1) & 0xFF)
        bytes[offset++] = UInt8(swapped & 0xFF)
    }
    
    func writeFloat64(val: Float64) {
        let swapped = CFConvertFloat64HostToSwapped(val)
        bytes[offset++] = UInt8((swapped.v >> 7) & 0xFF)
        bytes[offset++] = UInt8((swapped.v >> 6) & 0xFF)
        bytes[offset++] = UInt8((swapped.v >> 5) & 0xFF)
        bytes[offset++] = UInt8((swapped.v >> 4) & 0xFF)
        bytes[offset++] = UInt8((swapped.v >> 3) & 0xFF)
        bytes[offset++] = UInt8((swapped.v >> 2) & 0xFF)
        bytes[offset++] = UInt8((swapped.v >> 1) & 0xFF)
        bytes[offset++] = UInt8(swapped.v & 0xFF)
    }
    
    // Header.
    writeInt32(UInt32(sz))
    
    // Fields.
    // Maybe I'll want to not use reflection for this at some
    // point.
    for var i = 0; i != mirror.count; ++i {
        let (_, mirror) = mirror[i]
        if (mirror.valueType is Float64.Type) {
            writeFloat64(mirror.value as! Float64)
        } else if (mirror.valueType is Int32.Type) {
            writeInt32(UInt32(mirror.value as! Int32))
        }
    }

    // Write the record.
    file.writeData(NSData(bytes: bytes, length: sz))
}