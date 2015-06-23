//
//  Echo.swift
//  echoes
//
//  An Echo is a stream of audio, location fixes, and timestamps.
//
//  Created by Ashi Krishnan on 6/22/15.
//  Copyright (c) 2015 Ashi Krishnan. All rights reserved.
//

import Foundation
import CoreLocation
import AVFoundation
import UIKit

struct Echo {
    
}

enum EchoRecorderState {
    case Stopped
    case Recording
}

class EchoRecorder: NSObject, CLLocationManagerDelegate {
    let locationMgr = CLLocationManager()
    var state = EchoRecorderState.Stopped
    
    let recorders = Set<AVAudioRecorder>()
    var recorder: AVAudioRecorder?

    let fsMgr = NSFileManager.defaultManager()
    let baseUrl = try! NSFileManager.defaultManager().URLForDirectory(
        NSSearchPathDirectory.DocumentDirectory,
        inDomain: NSSearchPathDomainMask.UserDomainMask,
        appropriateForURL: nil,
        create: true)
    
    override init() {
        super.init()
        locationMgr.delegate = self
    }
    
    // Request the appropriate authorizations to record audio and location data
    // from the user. Call this method at an appropriate point in the UI flow.
    func requestAuthorizations() {
        switch(CLLocationManager.authorizationStatus()) {
        case .NotDetermined:
            NSLog("Requesting access to location services")
            locationMgr.requestAlwaysAuthorization()
            
        case .Restricted, .Denied:
            NSLog("Access to location services denied or location services off.")
            NSLog("TODO: Display an error here")
            
        case .AuthorizedWhenInUse, .Authorized:
            NSLog("Location services already authorized")
        }
    }
    
    let recordingSettings: [String:AnyObject] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVEncoderAudioQualityKey : AVAudioQuality.Max.rawValue,
        AVEncoderBitRateKey : 320000,
        AVNumberOfChannelsKey: 2,
        AVSampleRateKey : 44100.0
    ]
    
    func start() {
        if (state == .Recording) { return; }

        requestAuthorizations()
        let url = createDocumentUrl("m4a")
        NSLog("Write to URL: %@", url)
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(AVAudioSessionCategoryRecord)
            try session.setActive(true)
            recorder = try AVAudioRecorder(
                URL: url,
                settings: recordingSettings)
            state = .Recording
            recorder!.record()
            NSLog("Recording.")
        } catch let error as NSError {
            state = .Stopped
            NSLog("Error starting recording: %@", error)
        }
    }
    
    func stop() {
        if (state == .Stopped) { return; }
        if let recorder = recorder {
            recorder.stop()
        }
    }
    
    func toggle() {
        switch (state) {
        case .Recording:
            stop()
        case .Stopped:
            start()
        }
    }
    
    func createDocumentUrl(ext: String?) -> NSURL {
        var url = baseUrl.URLByAppendingPathComponent(NSUUID().UUIDString)
        while fsMgr.fileExistsAtPath(url.path!) {
            url = baseUrl.URLByAppendingPathComponent(NSUUID().UUIDString)
        }
        if let ext = ext {
            return url.URLByAppendingPathExtension(ext)
        }
        return url
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        NSLog("didChangeAuthorizationStatus status:%d", status.rawValue)
        if (status == .AuthorizedAlways || status == .AuthorizedWhenInUse) {
            locationMgr.startUpdatingLocation()
            locationMgr.startUpdatingHeading()
        } else {
            locationMgr.stopUpdatingLocation()
            locationMgr.stopUpdatingHeading()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // NSLog("didUpdateHeading newHeading:%@", newHeading)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [AnyObject]) {
        // NSLog("didUpdateLocations: %@", locations)
    }
}