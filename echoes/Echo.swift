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

enum EchoRecorderState {
    case Stopped
    case Recording
}

class EchoRecorder: NSObject, CLLocationManagerDelegate, AVAudioRecorderDelegate {
    var state = EchoRecorderState.Stopped

    let locationMgr = CLLocationManager()
    
    let audioSession = AVAudioSession.sharedInstance()
    var recorder: AVAudioRecorder?
    var nextRecorder: AVAudioRecorder?

    let bucket = try! FileBucket(id: "echoes")
    
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
        
        do { try startRecordingSession() } catch let error as NSError {
            NSLog("Couldn't initialize recording session: %@", error)
        }
        
        do {
            try initRecorders()
            state = .Recording
            NSLog("Recording.")
        } catch let error as NSError {
            state = .Stopped
            NSLog("Error starting recording: %@", error)
        }
    }
    
    // One minute segments.
    let segmentLength = NSTimeInterval(5.0)
    
    func initRecorders() throws {
        let rec = try createRecorder()
        recorder = rec
        try prepareNextRecorder()
        rec.recordAtTime(rec.deviceCurrentTime, forDuration: segmentLength)
    }
    
    func prepareNextRecorder() throws {
        let rec = try createRecorder()
        rec.recordAtTime(rec.deviceCurrentTime + segmentLength, forDuration: segmentLength)
        self.nextRecorder = rec
    }
    
    func createRecorder() throws -> AVAudioRecorder {
        let url = bucket.getUrl("m4a")
        NSLog("Will write audio segment to: %@", url)
        let rec = try AVAudioRecorder(URL: url, settings: recordingSettings)
        rec.delegate = self
        return rec
    }
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        NSLog("Recorder finished, wrote %@", recorder.url)
        if (recorder == self.recorder && state == .Recording) {
            self.recorder = self.nextRecorder
            do { try prepareNextRecorder() } catch let error as NSError {
                NSLog("Error creating recorder for segment: %@", error)
                stop()
            }
        }
    }
    
    func stop() {
        if (state == .Stopped) { return; }
        if let recorder = recorder {
            recorder.stop()
            self.recorder = nil
        }
        if let nextRecorder = nextRecorder {
            nextRecorder.stop()
            self.nextRecorder = nil
        }
        do { try stopRecordingSession() } catch let error as NSError {
            NSLog("Error closing AVAudioSession: %@", error)
        }
        NSLog("Recording stopped.")
    }

    func startRecordingSession() throws {
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setActive(true)
    }
    
    func stopRecordingSession() throws {
        try audioSession.setActive(false)
    }
    
    func toggle() {
        switch (state) {
        case .Recording:
            stop()
        case .Stopped:
            start()
        }
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