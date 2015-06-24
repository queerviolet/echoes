//
//  FileBucket.swift
//  echoes
//
//  Created by Ashi Krishnan on 6/24/15.
//  Copyright © 2015 Ashi Krishnan. All rights reserved.
//

import Foundation

class FileBucket {
    let bucketId: String!
    let sessionId: String!
    let dir: NSURL!
    var nextFileId = 0
    
    init(bucketId id: String) throws {
        self.bucketId = id
        let fsMgr = NSFileManager.defaultManager()
        let root = try! fsMgr.URLForDirectory(
            NSSearchPathDirectory.DocumentDirectory,
            inDomain: NSSearchPathDomainMask.UserDomainMask,
            appropriateForURL: nil,
            create: true).URLByAppendingPathComponent(id)
        var sesh = NSUUID().UUIDString
        var url = root.URLByAppendingPathComponent(sesh)
        while fsMgr.fileExistsAtPath(url.path!) {
            sesh = NSUUID().UUIDString
            url = root.URLByAppendingPathComponent(sesh)
        }
        dir = url
        sessionId = sesh
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