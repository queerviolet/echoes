//
//  AppDelegate.swift
//  echoes
//
//  Created by Ashi Krishnan on 6/22/15.
//  Copyright (c) 2015 Ashi Krishnan. All rights reserved.
//

import UIKit
import MapKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    let echoRecorder = EchoRecorder()
    var mapViewCtrl: EchoesMapViewController!
    
    func alert(msg: String) {
        UIAlertController(title: "Echoes Alert",
            message: msg,
            preferredStyle: .Alert)
    }
    
    func alert(title: String, msg text: String) {
        UIAlertController(title: title,
            message: text,
            preferredStyle: .Alert)
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        if let vendorId = UIDevice.currentDevice().identifierForVendor?.UUIDString {
            NSLog("Vendor identifier: %@", vendorId)
        } else {
            alert("Vendor ID Unavailable",
                msg: "Couldn't read identifier for vendor. This should only happen if your phone is locked.")
            NSLog("Vendor identifier unreadable.")
        }
        
        let frame = UIScreen.mainScreen().bounds
        let window = UIWindow(frame: frame)
        self.window = window
        mapViewCtrl = EchoesMapViewController()
        window.rootViewController = mapViewCtrl
        window.makeKeyAndVisible()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

