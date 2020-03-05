//
//  User.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 30/03/2018.
//  Copyright © 2018 Swipster Inc. All rights reserved.
//

import UIKit
import CoreLocation

struct User {
    
    let first_name: String
    let email: String
    let birthday: String
    let gender: String
    var uid: String
    var parentUID: String?
    let pictureURL: String
    let secondPictureURL: String
    let thirdPictureURL: String
    let fourthPictureURL: String
    let lookingFor: String
    var latitude: String
    var longitude: String
    var position: CLLocation?
    let lookingDist: String
    let url: String
    let minAge: String
    let maxAge: String
    var active: String
    let fcmToken: String
    let deviceToken: String
    let bio: String
    let purchased: Bool
    let isPremium: Bool
    var seenArray: [String: String]?
    
    init(dictionary: [String: Any]) {
        first_name = dictionary["first_name"] as? String ?? ""
        email = dictionary["email"] as? String ?? ""
        birthday = dictionary["birthday"] as? String ?? ""
        gender = dictionary["gender"] as? String ?? ""
        uid = dictionary["id"] as? String ?? ""
        pictureURL = dictionary["pictureURL"] as? String ?? ""
        secondPictureURL = dictionary["secondPictureURL"] as? String ?? ""
        thirdPictureURL = dictionary["thirdPictureURL"] as? String ?? ""
        fourthPictureURL = dictionary["fourthPictureURL"] as? String ?? ""
        lookingFor = dictionary["lookingFor"] as? String ?? ""
        latitude = dictionary["latitude"] as? String ?? ""
        longitude = dictionary["longitude"] as? String ?? ""
        lookingDist = dictionary["lookingDistance"] as? String ?? ""
        url = dictionary["url"] as? String ?? ""
        minAge = dictionary["minAge"] as? String ?? ""
        maxAge = dictionary["maxAge"] as? String ?? ""
        active = dictionary["public"] as? String ?? ""
        fcmToken = dictionary["fcmToken"] as? String ?? ""
        deviceToken = dictionary["token"] as? String ?? ""
        bio = dictionary["description"] as? String ?? ""
        purchased = dictionary["purchased"] as? Bool ?? false
        isPremium = dictionary["isPremium"] as? Bool ?? false
        if Double(latitude) != nil && Double(longitude) != nil {
            position = CLLocation(latitude: Double(latitude)!, longitude: Double(longitude)!)
        }
    }
}
