//
//  FileBucket.swift
//  echoes
//
//  Created by Ashi Krishnan on 6/24/15.
//  Copyright © 2015 Ashi Krishnan. All rights reserved.
//

import Foundation
import UIKit

class FileBucket {
    let name: String!
    let sessionId: String!
    let dir: NSURL!
    var nextFileId = 0

    let fsMgr = NSFileManager.defaultManager()
    
    init(name bucketName: String) throws {
        self.name = bucketName
        
        // Start at Documents/$bucketName
        let root = try! fsMgr.URLForDirectory(
            NSSearchPathDirectory.DocumentDirectory,
            inDomain: NSSearchPathDomainMask.UserDomainMask,
            appropriateForURL: nil,
            create: true).URLByAppendingPathComponent(bucketName)
        
        // Then create a sessionId such that Documents/$bucketName/$sessionId
        // doesn't exist yet.
        //
        // self.dir will be Documents/$bucketName/$sessionId
        //
        // Our urls will be Documents/$BucketName/$sessionId/{1, 2, 3}{.ext}... etc,
        // with extensions as requested in getUrl
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
    
    func getUrl(ext ext: String?) -> NSURL {
        let url = dir.URLByAppendingPathComponent(String(nextFileId++))
        if let ext = ext {
            return url.URLByAppendingPathExtension(ext)
        }
        return url
    }
    
    func getUrlAndMkdir(ext ext: String?) throws -> NSURL {
        let url = getUrl(ext: ext)
        try fsMgr.createDirectoryAtURL(url, withIntermediateDirectories: false, attributes: nil)
        return url
    }
    
    func newObject(ext ext: String?) throws -> FileBucketObject {
        let url = getUrl(ext: ext)
        try fsMgr.createDirectoryAtURL(url, withIntermediateDirectories: false, attributes: nil)
        return FileBucketObject(root: url, fsMgr: fsMgr)
    }
}

class FileBucketObject {
    let dir: NSURL
    let fsMgr: NSFileManager
    
    init(root dir: NSURL, fsMgr: NSFileManager) {
        self.dir = dir
        self.fsMgr = fsMgr
    }
    
    func url(fileName file: String) -> NSURL {
        return dir.URLByAppendingPathComponent(file)
    }
    
    func open(fileName file: String) throws -> NSFileHandle {
        let path = dir.URLByAppendingPathComponent(file)
        var output: NSFileHandle
        do {
            output = try NSFileHandle(forWritingToURL: path)
        } catch _ as NSError {
            fsMgr.createFileAtPath(path.path!, contents: nil, attributes: nil)
            output = try NSFileHandle(forWritingToURL: path)
        }
        return output
    }
}