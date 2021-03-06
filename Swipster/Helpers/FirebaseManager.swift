//
//  FirebaseManager.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 21/11/2019.
//  Copyright © 2019 Swipster Inc. All rights reserved.
//

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

func logoutUser(completion: @escaping () -> Void) {
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

func getFcmToken(){
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let fcmToken = appDelegate.firebaseToken ?? ""
    guard let uid = Auth.auth().currentUser?.uid else { return }
    let values = ["fcmToken": fcmToken]
    
    Database.database().reference().child("users").child(uid).updateChildValues(values, withCompletionBlock: { (err, ref) in
        if err != nil {
            print(err ?? "")
            return
        }
    })
}

func sendPushNotification(notData: [String: Any]) {
    let url = URL(string: "https://fcm.googleapis.com/fcm/send")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = try? JSONSerialization.data(withJSONObject:notData, options: [])
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    guard let api_key = ProcessInfo.processInfo.environment["push_key"] else {
        print("You need to put Firebase api in env variable")
        return
    }
    request.setValue(api_key, forHTTPHeaderField: "Authorization")
    let task =  URLSession.shared.dataTask(with: request)  { (data, response, error) in
        do {
            if let jsonData = data {
                if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                    print("Received data:\n\(jsonDataDict))")
                }
            }
        } catch let err as NSError {
            print(err.debugDescription)
        }
    }
    task.resume()
}
