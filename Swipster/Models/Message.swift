//
//  Message.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 05/04/2018.
//  Copyright © 2018 Swipster Inc. All rights reserved.
//

import UIKit
import Firebase

struct Message {
    
    let fromId: String?
    let text: String?
    let timestamp: Int?
    let toId: String?
    let imageUrl: String?
    let videoUrl: String?
    let imageWidth: Float?
    let imageHeight: Float?
    var messageId: String?
    
    init(dictionary: [String: Any]) {
        fromId = dictionary["fromId"] as? String
        text = dictionary["text"] as? String
        toId = dictionary["toId"] as? String
        timestamp = dictionary["timestamp"] as? Int
        imageUrl = dictionary["imageUrl"] as? String
        videoUrl = dictionary["videoUrl"] as? String
        imageWidth = dictionary["imageWidth"] as? Float
        imageHeight = dictionary["imageHeight"] as? Float
    }
    
    func chatPartnerId() -> String? {
        return fromId == Auth.auth().currentUser?.uid ? toId : fromId
    }
    
}

