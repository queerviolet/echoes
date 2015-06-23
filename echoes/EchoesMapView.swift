//
//  MapViewController.swift
//  echoes
//
//  Created by Ashi Krishnan on 6/22/15.
//  Copyright (c) 2015 Ashi Krishnan. All rights reserved.
//

import UIKit
import MapKit

class EchoesMapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    var map: MKMapView!
    let locationMgr = CLLocationManager()
    
    var recordButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationMgr.delegate = self
        
        map = MKMapView(frame: view.bounds)
        map.delegate = self
        
        view.addSubview(map)
        
        recordButton = UIButton(type: .System)
        recordButton.setTitle("rec", forState: .Normal)
        recordButton.frame = CGRectMake(
            view.bounds.width / 2.0 - 25,
            view.bounds.height - 60,
            50, 50)
        recordButton.backgroundColor = UIColor.blueColor()
        recordButton.tintColor = UIColor.whiteColor()
        recordButton.addTarget(self, action: "record:", forControlEvents: .TouchUpInside)
        view.addSubview(recordButton)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func record(sender: UIButton!) {
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        app.echoRecorder.toggle()
    }
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        //print("Map View User location updated:\(userLocation.location)")
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        NSLog("didChangeAuthorizationStatus status:%d", status.rawValue)
        if (status == .AuthorizedAlways || status == .AuthorizedWhenInUse) {
            map.showsUserLocation = true
        } else {
            map.showsUserLocation = false
        }
    }
}

