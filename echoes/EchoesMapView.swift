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
    var locationMgr: CLLocationManager!
    
    var recordButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationMgr = CLLocationManager()
        locationMgr.delegate = self
        
        map = MKMapView(frame: view.bounds)
        map.delegate = self
        
        view.addSubview(map)
        
        recordButton = UIButton.buttonWithType(.System) as UIButton
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
        switch(CLLocationManager.authorizationStatus()) {
        case .NotDetermined:
            println("requesting authorization...")
            locationMgr.requestWhenInUseAuthorization()
            
        case .Restricted, .Denied:
            println("access to location services denied")
        
        case .AuthorizedWhenInUse, .Authorized:
            println("location services already authorized")
            
        default:
            println("unknown enum value for CLAuthorizationStatus: what does this mean?")
        }
    }
    
    func mapView(mapView: MKMapView!, didUpdateUserLocation userLocation: MKUserLocation!) {
        println("User location updated:\(userLocation.location)")
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        /*
        enum CLAuthorizationStatus : Int32 {
            case NotDetermined = 0
            case Restricted = 1
            case Denied = 2
            case AuthorizedAlways = 3
            case AuthorizedWhenInUse = 4
        }
        */

        println("didChangeAuthorizationStatus status:\(status.toRaw())")
        if (status == .Authorized || status == .AuthorizedWhenInUse) {
            map.showsUserLocation = true
            locationMgr.startUpdatingLocation()
            locationMgr.startUpdatingHeading()
        } else {
            map.showsUserLocation = false
            locationMgr.stopUpdatingLocation()
            locationMgr.stopUpdatingHeading()
        }
    }
}

