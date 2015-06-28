//
//  Struct.swift
//  echoes
//
//  Created by Ashi Krishnan on 6/26/15.
//  Copyright © 2015 Ashi Krishnan. All rights reserved.
//

import Foundation

func toByteArray<T>(var value: T) -> [UInt8] {
    return withUnsafePointer(&value) {
        Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(T)))
    }
}

func toNSData<T>(var value: T) -> NSData {
    return withUnsafePointer(&value) {
        NSData(bytes: UnsafePointer<UInt8>($0), length: sizeof(T))
    }
}

func writeStruct<T>(toFile file: NSFileHandle, obj: T) {
    file.writeData(toNSData(sizeof(T)))
    file.writeData(toNSData(obj))
}

/*func writeStruct<T>(toFile file: NSFileHandle, obj: T) {
    let mirror = reflect(obj)
    file.writeData(toNSData(sizeof(T)))

    for var i = 0; i != mirror.count; ++i {
        let (mirrorType, mirror) = mirror[i]
        file.writeData(toNSData(mirror.value))
        print("Wrote \(mirrorType)=\(mirror)")
    }
}*/

/*
func writeStruct<T>(toFile file: NSFileHandle, obj: T) {
    let mirror = reflect(obj)
    let sz = sizeofValue(obj)
    
    // Super complex record format:
    // [size of struct: UInt32 (4 bytes)]
    // [the struct (next (size of struct) bytes)]

    //var bytes:[UInt8] = [UInt8](count: sz + 4, repeatedValue: 0)
    //var offset:Int = 0
    
    func writeInt32(val: UInt32) {
        let swapped = val //CFSwapInt32HostToBig(val)
        swapped.
        /*
        bytes[offset++] = UInt8((swapped >> 3) & 0xFF)
        bytes[offset++] = UInt8((swapped >> 2) & 0xFF)
        bytes[offset++] = UInt8((swapped >> 1) & 0xFF)
        bytes[offset++] = UInt8(swapped & 0xFF)
        */
    }
    
    func writeFloat64(val: Float64) {
        let swapped = unsafeBitCast(val, Float64._BitsType.self) // val //CFConvertFloat64HostToSwapped(val)
    
        /*
        bytes[offset++] = UInt8((swapped >> 7) & 0xFF)
        bytes[offset++] = UInt8((swapped >> 6) & 0xFF)
        bytes[offset++] = UInt8((swapped >> 5) & 0xFF)
        bytes[offset++] = UInt8((swapped >> 4) & 0xFF)
        bytes[offset++] = UInt8((swapped >> 3) & 0xFF)
        bytes[offset++] = UInt8((swapped >> 2) & 0xFF)
        bytes[offset++] = UInt8((swapped >> 1) & 0xFF)
        bytes[offset++] = UInt8(swapped & 0xFF)
        */
    }
    
    // Header.
    writeInt32(UInt32(sz))
    
    // Fields.
    // Maybe I'll want to not use reflection for this at some
    // point.
    for var i = 0; i != mirror.count; ++i {
        let (mirrorType, mirror) = mirror[i]
        if (mirror.valueType is Float64.Type) {
            writeFloat64(mirror.value as! Float64)
        } else if (mirror.valueType is Int32.Type) {
            writeInt32(UInt32(mirror.value as! Int32))
        } else {
            NSLog("Failed to serialize field \(mirrorType): \(mirror)")
        }
    }

    // Write the record.
    file.writeData(NSData(bytes: bytes, length: sz))

}*/