//
//  LocationViewController.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 07/10/2018.
//  Copyright © 2018 Swipster Inc. All rights reserved.
//

import UIKit
import CoreLocation

class LocationViewController: UIViewController {
    
    @IBAction func allowButton(_ sender: Any) {
        if let url = URL(string:UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                   UIApplication.shared.openURL(url)
                }
            }
        }
    }
    var locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureLocationManager()
    }
    
    func configureLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
    }
}

extension LocationViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted, .denied:
            break
            
        case .authorizedWhenInUse, .authorizedAlways:
            self.dismiss(animated: false, completion: nil)
            break
            
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}
