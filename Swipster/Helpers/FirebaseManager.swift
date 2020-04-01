//
//  FirebaseManager.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 21/11/2019.
//  Copyright © 2019 Swipster Inc. All rights reserved.
//

import Foundation
import Firebase
import SwiftEntryKit
import FacebookLogin

func createUser(uid: String, values: [String: Any], completion: @escaping () -> Void) {

    let usersReference = Database.database().reference().child("users").child(uid)
    let age = calcAge(birthday: values["birthday"] as! String)
    if age >= 18 {
        usersReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if err != nil {
                showPopupMessage(title: "Oops..", buttonTitle: "J'ai compris", description: "Une erreur s'est produite. Cela vient de nous et nous nous en excusons.\nMerci de réessayer dans quelques instants.", image: #imageLiteral(resourceName: "ic_error_all_light_48pt")) {
                    SwiftEntryKit.dismiss(.all)
                    return
                }
            }
            completion()
        })
    } else {
        showPopupMessage(title: "Impossible !", buttonTitle: "J'ai compris", description: "Swipster n'est disponible que pour les personnes ayant plus de 18 ans actuellement.", image: #imageLiteral(resourceName: "ic_error_all_light_48pt")) {
            SwiftEntryKit.dismiss(.all)
            return
        }
    }
}

func logoutUser(completion: @escaping () -> Void){
    LoginManager().logOut()
    let firebaseAuth = Auth.auth()
    do {
        try firebaseAuth.signOut()
        UserDefaults.standard.removeObject(forKey: "uid")
        UserDefaults.standard.removeObject(forKey: "active")
        UserDefaults.standard.synchronize()
        completion()
    } catch let signOutError {
        print ("Error signing out: %@", signOutError)
    }
}

func uploadImageToFirebase(ref: StorageReference, image: UIImage, completion: @escaping (_ imageUrl: String) -> ()) {
    showLoadingView(text: "Upload en cours ...")
    let newMetadata = StorageMetadata()
    newMetadata.contentType = "image/jpg"
    if let uploadData = image.jpegData(compressionQuality: 0.1) {
        ref.putData(uploadData, metadata: newMetadata, completion: { (metadata, error) in
            
            if error != nil {
                showPopupMessage(title: "Erreur !", buttonTitle: "Compris !", description: "Veuillez réessayer ultérieurement !", image: #imageLiteral(resourceName: "ic_error_all_light_48pt")) {
                    SwiftEntryKit.dismiss()
                }
                return
            }
            
            ref.downloadURL(completion: { (url, error) in
                if (error == nil) {
                    if let downloadUrl = url {
                        completion(downloadUrl.absoluteString)
                    }
                } else {
                    showPopupMessage(title: "Erreur !", buttonTitle: "Compris !", description: "Veuillez réessayer ultérieurement !", image: #imageLiteral(resourceName: "ic_error_all_light_48pt")) {
                        SwiftEntryKit.dismiss()
                    }
                }
            })
            
        })
    }
}
