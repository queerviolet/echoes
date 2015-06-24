//
//  FileBucket.swift
//  echoes
//
//  Created by Ashi Krishnan on 6/24/15.
//  Copyright © 2015 Ashi Krishnan. All rights reserved.
//

import Foundation

class FileBucket {
    let id: String!
    let dir: NSURL!
    var nextFileId = 0
    
    init(id: String) throws {
        self.id = id
        let fsMgr = NSFileManager.defaultManager()
        let root = try! fsMgr.URLForDirectory(
            NSSearchPathDirectory.DocumentDirectory,
            inDomain: NSSearchPathDomainMask.UserDomainMask,
            appropriateForURL: nil,
            create: true).URLByAppendingPathComponent(id)
        var url = root.URLByAppendingPathComponent(NSUUID().UUIDString)
        while fsMgr.fileExistsAtPath(url.path!) {
            url = root.URLByAppendingPathComponent(NSUUID().UUIDString)
        }
        dir = url
        try fsMgr.createDirectoryAtURL(url, withIntermediateDirectories: true, attributes: nil)
    }
    
    func getUrl(ext: String?) -> NSURL {
        let url = dir.URLByAppendingPathComponent(String(nextFileId++))
        if let ext = ext {
            return url.URLByAppendingPathExtension(ext)
        }
        return url
    }
}