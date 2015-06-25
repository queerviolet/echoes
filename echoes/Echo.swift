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

enum EchoRecorderState { case Stopped; case Recording }

class EchoRecorder: NSObject, CLLocationManagerDelegate, AVAudioRecorderDelegate {
    var state = EchoRecorderState.Stopped
    
    let recordingSettings: [String:AnyObject] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVEncoderAudioQualityKey : AVAudioQuality.Max.rawValue,
        AVEncoderBitRateKey : 320000,
        AVNumberOfChannelsKey: 2,
        AVSampleRateKey : 44100.0
    ]
    
    struct SegmentRecorder {
        let url: NSURL
        let audioUrl: NSURL
        let locationUrl: NSURL
        let audioRecorder: AVAudioRecorder
        let startTime: NSTimeInterval
        
        var description: String {
            return "url: \"\(url)\", audioUrl: \"\(audioUrl)\", locationUrl: \"\(locationUrl)\", startTime: \"\(startTime)\""
        }
        
        func stop() {
            audioRecorder.stop()
        }
    }
    
    let audioSession = AVAudioSession.sharedInstance()
    var recorder: SegmentRecorder?
    var nextRecorder: SegmentRecorder?
    let segmentLength = NSTimeInterval(60.0)  // audio file length in seconds, must be at least 1.
    let segmentOverlap = NSTimeInterval(1.0e-3) // one millisecond of overlap between segments.

    let bucket = try! FileBucket(name: "echoes")

    let locationMgr = CLLocationManager()

    override init() {
        super.init()
        locationMgr.delegate = self
    }
    
    func toggle() { state == .Stopped ? start() : stop(); }
    
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
    
    func stop() {
        if (state == .Stopped) { return; }
        recorder?.stop(); recorder = nil
        nextRecorder?.stop(); nextRecorder = nil
        do { try stopRecordingSession() } catch let error as NSError {
            NSLog("Error closing AVAudioSession: %@", error)
        }
        NSLog("Recording stopped.")
    }
    
    // Request the appropriate authorizations to track location data
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
    
    // We have two AVAudioRecorders, recorder and nextRecorder. recorder is set to record
    // immediately and forDuration: segmentLength. nextRecorder is set to start recording
    // slightly before (segmentOverlap seconds) recorder finishes and forDuration: segmentLength.
    // When a recorder finishes, we rotate nextRecorder into recorder and create a new
    // nextRecorder.
    //
    // The upshot of this is that we get segments of segmentLength which fit together almost
    // exactly. It's good enough for our purposes, in any case.
    //
    // We could use a queue, but there's no point—recorders go for about a minute, so I can't
    // imagine us needing more than two.
    
    // Initializes recorder and nextRecorder and queues them for recording
    // at the appropriate times.
    func initRecorders() throws {
        recorder = try createRecorder(startTime: nil)
        try prepareNextRecorder()
    }
    
    // Initializes nextRecorder and queues it to start at the appropriate time.
    func prepareNextRecorder() throws {
        if let recorder = recorder {
            nextRecorder = try createRecorder(startTime: recorder.startTime + segmentLength)
        } else {
            NSLog("prepareNextRecorder() called when no recording in progress. Stopping recording.")
            state = .Stopped
        }
    }
    
    // Returns an AVAudioRecorder set up to write to a URL pulled from bucket and notify
    // us when it's done via a delegate call.
    func createRecorder(startTime start: NSTimeInterval?) throws -> SegmentRecorder {
        let echoUrl = try bucket.getUrlAndMkdir(ext: "echo")
        let avUrl = echoUrl.URLByAppendingPathComponent("audio")
                           .URLByAppendingPathExtension("m4a")
        let locationUrl = echoUrl.URLByAppendingPathComponent("locations")
                                  .URLByAppendingPathExtension("pb")
        
        let audioRecorder = try AVAudioRecorder(URL: avUrl, settings: recordingSettings)
        let rec = SegmentRecorder(
            url: echoUrl,
            audioUrl: avUrl,
            locationUrl: locationUrl,
            audioRecorder: audioRecorder,
            startTime: start != nil ? start! : audioRecorder.deviceCurrentTime)
        NSLog("SegmentRecorder created: %@", rec.description)
        rec.audioRecorder.delegate = self
        rec.audioRecorder.recordAtTime(rec.startTime, forDuration: segmentLength + segmentOverlap)
        return rec
    }
    
    // Called by an AVAudioRecorder when it's finished recording. We rotate nextRecorder into
    // recorder here.
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        NSLog("Recorder finished, wrote %@", recorder.url)
        if (recorder == self.recorder?.audioRecorder && state == .Recording) {
            self.recorder = self.nextRecorder
            do { try prepareNextRecorder() } catch let error as NSError {
                NSLog("Error creating recorder for segment: %@", error)
                stop()
            }
        }
    }

    func startRecordingSession() throws {
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setActive(true)
    }
    
    func stopRecordingSession() throws {
        try audioSession.setActive(false)
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
        //NSLog("didUpdateHeading newHeading:%@", newHeading)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [AnyObject]) {
        //NSLog("didUpdateLocations: %@", locations)
    }
}