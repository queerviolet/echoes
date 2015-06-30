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
    let name: String
    let sessionId: String
    let dir: NSURL
    let root: NSURL
    var nextFileId = 0

    let fsMgr = NSFileManager.defaultManager()
    var syncer: FileBucketSyncer?
    
    init(name bucketName: String) throws {
        self.name = bucketName

        // Start at Documents/$bucketName
        root = try! fsMgr.URLForDirectory(
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
        self.syncer = FileBucketSyncer(bucket: self)
        self.syncer?.fileBucket(bucket: self, didInitializeWithSessionId: sesh)
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
        return FileBucketObject(bucket: self, url: url)
    }
}

class FileBucketObject {
    let url: NSURL
    let bucket: FileBucket
    var streams = [FileBucketStream]()
    
    init(bucket: FileBucket, url: NSURL) {
        self.bucket = bucket
        self.url = url
    }
    
    func stream(name file: String) -> FileBucketStream {
        let stream = FileBucketStream(object: self, name: file)
        streams.append(stream)
        return stream
    }
    
    func close() {
        for stream in streams {
            stream.close()
        }
    }
    
}

class FileBucketStream {
    let object: FileBucketObject
    let name: String
    let url: NSURL
    
    init(object: FileBucketObject, name: String) {
        self.object = object
        self.name = name
        self.url = object.url.URLByAppendingPathComponent(name)
    }
    
    var handle: NSFileHandle? {
        get {
            if let h = _handle { return h }

            var h: NSFileHandle?
            do {
                h = try NSFileHandle(forWritingToURL: url)
            } catch _ as NSError {
                object.bucket.fsMgr.createFileAtPath(url.path!, contents: nil, attributes: nil)
                h = try! NSFileHandle(forWritingToURL: url)
            }
            _handle = h
            return h!
        }
    }
    
    var _handle: NSFileHandle? = nil
    
    func close() {
        _handle?.closeFile()
        object.bucket.syncer?.fileBucketStream(stream: self, didCloseSuccessfully: true)
    }
    
}

class FileBucketSyncer {
    let bucket: FileBucket
    let fsMgr = NSFileManager.defaultManager()
    
    init(bucket: FileBucket) {
        self.bucket = bucket
    }
    
    func fileBucket(bucket bucket: FileBucket, didInitializeWithSessionId sessionId: String) {
        NSLog("FileBucketSyncer: syncing \(bucket)")
        NSLog("  Root: %@", bucket.root)
        //let enumerator = fsMgr.enumeratorAtPath(bucket.root.path!)
        let keys = [NSURLIsDirectoryKey]
        let enumerator: NSDirectoryEnumerator = fsMgr.enumeratorAtURL(bucket.root,
            includingPropertiesForKeys:keys,
            options: NSDirectoryEnumerationOptions(),
            errorHandler: { (url: NSURL, error: NSError) -> Bool in
                return true;
            })!;
        NSLog("all sessions: %@", enumerator.allObjects)
        while let entry = enumerator.nextObject() as? String {
            NSLog(entry)
        }
    }
    
    func fileBucketStream(stream stream: FileBucketStream, didCloseSuccessfully: Bool) {
        
    }
}