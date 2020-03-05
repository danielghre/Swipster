//
//  Utils.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 02/01/2019.
//  Copyright © 2019 SwipSter Inc. All rights reserved.
//

import SwiftEntryKit
import Firebase
import FirebaseDatabase
import Photos
import FacebookLogin

public enum choiceDone: String {
    case nothing = "nothing"
    case love = "love"
    case cheers = "cheers"
    case hot = "hot"
}

func sendEmail(subject: String, text: String, user: User, fromUID: String, fromName: String, completion: @escaping () -> Void) {
    let textToSend = "<html><div>\(text)<br><p>Nom d'Utilisataeur: \(user.first_name)<br>Id: \(user.parentUID ?? "UID not found")<br>\(user.email)</p><p>Envoyé le \(Date().toString()) par \(fromName)<br>Id: \(fromUID)</div></html>"
    let params = [
        "api_user": "Swipy",
        "api_key": "amisraelhai26D",
        "to": "contact@swipster.io",
        "toname": "Signal Swipster",
        "subject": subject,
        "html": textToSend,
        "from": "signal@swipster.io"
    ]
    var parts: [String] = []
    for (k, v) in params {
        let key = String(describing: k).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        let value = String(describing: v).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        parts.append(String(format: "%@=%@", key!, value!))
    }
    guard let url = URL(string: String(format: "%@?%@", "https://api.sendgrid.com/api/mail.send.json", parts.joined(separator: "&"))) else { return }
    
    let session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
    let task = session.dataTask(with: url, completionHandler: {
        (data, response, error) in
        if (error == nil) {
            DispatchQueue.main.async {
                let image = UIImage(named: "ic_done_all_light_48pt")!
                let title = "Bien reçu !"
                let description = "Merci de nous avoir signalé " + user.first_name + " Nous allons nous en occuper !"
                showPopupMessage(title: title, buttonTitle: "Compris !", description: description, image: image) {
                    SwiftEntryKit.dismiss()
                    completion()
                }
            }
        } else {
            DispatchQueue.main.async {
                showPopupMessage(title: "Erreur !", buttonTitle: "Compris !", description: "Veuillez réessayer ultérieurement !", image: #imageLiteral(resourceName: "ic_error_all_light_48pt")) {
                    SwiftEntryKit.dismiss()
                }
            }
        }
    })
    task.resume()
    session.finishTasksAndInvalidate()
}

func report(user: User, fromUID: String, fromName: String, isMatch: Bool, completion: @escaping () -> Void) {
    var attributes: EKAttributes
    attributes = EKAttributes.centerFloat
    attributes.windowLevel = .alerts
    attributes.displayDuration = .infinity
    attributes.entryInteraction = .absorbTouches
    attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .jolt)
    attributes.screenBackground = .color(color: EKColor(UIColor(white: 0, alpha: 0.7)))
    attributes.entryBackground = .color(color: EKColor(light: .white, dark: .darkGray))
    attributes.screenInteraction = .dismiss
    attributes.roundCorners = .all(radius: 8)
    attributes.entranceAnimation = .init(translate: .init(duration: 0.7, spring: .init(damping: 0.7, initialVelocity: 0)),
                                         scale: .init(from: 0.7, to: 1, duration: 0.4, spring: .init(damping: 1, initialVelocity: 0)))
    attributes.exitAnimation = .init(translate: .init(duration: 0.2))
    attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.35)))
    attributes.positionConstraints.size = .init(width: .offset(value: 20), height: .intrinsic)
    let title = EKProperty.LabelContent(text: "Signaler", style: .init(font: UIFont(name: "BerlinSansFBDemi-Bold", size: 32)!, color: EKColor(light: .darkGray, dark: .white), alignment: .center))
    let description = EKProperty.LabelContent(text: "On ne dira rien à " + user.first_name, style: .init(font: UIFont(name: "Bellota-Regular", size: 15)!, color: EKColor(light: UIColor(white: 0.4, alpha: 1), dark: .white), alignment: .center))
    let simpleMessage = EKSimpleMessage(title: title, description: description)
    
    let buttonFont = UIFont(name: "BerlinSansFB-Reg", size: 16)!
    let labelStyle = EKProperty.LabelStyle(font: buttonFont, color: EKColor(UIColor.cancelRed))
    
    let subject = isMatch ? "Signalement d'un match" : "Signalement d'un utilisateur"
    
    let spamButtonLabel = EKProperty.LabelContent(text: "SPAM", style: labelStyle)
    let spamButton = EKProperty.ButtonContent(label: spamButtonLabel, backgroundColor: .clear, highlightedBackgroundColor:  EKColor(UIColor.cancelRed.withAlphaComponent(0.05))) {
        showLoadingView(text: "Envoi en cours...")
        sendEmail(subject: subject, text: "SPAM", user: user, fromUID: fromUID, fromName: fromName, completion: {
            completion()
        })
    }
    
    let picsButtonLabel = EKProperty.LabelContent(text: "PHOTOS INAPPROPRIÉES", style: labelStyle)
    let picsButton = EKProperty.ButtonContent(label: picsButtonLabel, backgroundColor: .clear, highlightedBackgroundColor:  EKColor(UIColor.cancelRed.withAlphaComponent(0.05))) {
        showLoadingView(text: "Envoi en cours...")
        sendEmail(subject: subject, text: "PHOTOS INAPPROPRIÉES", user: user, fromUID: fromUID, fromName: fromName, completion: {
            completion()
        })
    }
    
    let ageButtonLabel = EKProperty.LabelContent(text: "ÂGE NON CONFORME", style: labelStyle)
    let ageButton = EKProperty.ButtonContent(label: ageButtonLabel, backgroundColor: .clear, highlightedBackgroundColor:  EKColor(UIColor.cancelRed.withAlphaComponent(0.05))) {
        showLoadingView(text: "Envoi en cours...")
        sendEmail(subject: subject, text: "ÂGE NON CONFORME", user: user, fromUID: fromUID, fromName: fromName, completion: {
            completion()
        })
    }
    
    let otherButtonLabel = EKProperty.LabelContent(text: "AUTRE", style: labelStyle)
    let otherButton = EKProperty.ButtonContent(label: otherButtonLabel, backgroundColor: .clear, highlightedBackgroundColor:  EKColor(UIColor.cancelRed.withAlphaComponent(0.05))) {
        showLoadingView(text: "Envoi en cours...")
        sendEmail(subject: subject, text: "AUTRE", user: user, fromUID: fromUID, fromName: fromName, completion: {
            completion()
        })
    }
    
    let otherStyle = EKProperty.LabelStyle(font: buttonFont, color: EKColor(light: .darkGray, dark: .white))
    let closeButtonLabel = EKProperty.LabelContent(text: "ANNULER", style: otherStyle)
    let closeButton = EKProperty.ButtonContent(label: closeButtonLabel, backgroundColor: .clear, highlightedBackgroundColor:  EKColor(UIColor.white.withAlphaComponent(0.05))) {
        SwiftEntryKit.dismiss(.all)
    }
    
    let buttonsBarContent = EKProperty.ButtonBarContent(with: spamButton, picsButton, ageButton, otherButton, closeButton, separatorColor: EKColor(UIColor.lightGray), expandAnimatedly: true)
    
    let alertMessage = EKAlertMessage(simpleMessage: simpleMessage, buttonBarContent: buttonsBarContent)
    
    let contentView = EKAlertMessageView(with: alertMessage)
    
    SwiftEntryKit.display(entry: contentView, using: attributes)
}

func showLoadingView(text: String){
    var attributes = EKAttributes.topFloat
    attributes = .topNote
    attributes.screenInteraction = .absorbTouches
    attributes.displayDuration = .infinity
    attributes.popBehavior = .animated(animation: .translation)
    attributes.entryBackground = .color(color: EKColor(UIColor.darkGrey))
    attributes.screenBackground = .color(color: EKColor(UIColor(white: 0, alpha: 0.7)))
    let style = EKProperty.LabelStyle(font: UIFont(name: "ITCAvantGardePro-Bk", size: 14)!, color: .white, alignment: .center)
    let labelContent = EKProperty.LabelContent(text: text, style: style)
    let contentView = EKProcessingNoteMessageView(with: labelContent, activityIndicator: .white)
    SwiftEntryKit.display(entry: contentView, using: attributes)
}

func showPopupMessage(title: String, buttonTitle: String, description: String, image: UIImage? = nil, completion: @escaping () -> Void) {
    
    var attributes = EKAttributes.bottomFloat
    attributes.scroll = .edgeCrossingDisabled(swipeable: true)
    attributes.entranceAnimation = .init(translate: .init(duration: 0.5, spring: .init(damping: 1, initialVelocity: 0)))
    attributes.entryBackground = .gradient(gradient: .init(colors: [EKColor(UIColor(rgb: 0xCA41A3)), EKColor(UIColor(rgb: 0x66084B))], startPoint: .zero, endPoint: CGPoint(x: 1, y: 1)))
    attributes.positionConstraints = .fullWidth
    attributes.positionConstraints.safeArea = .empty(fillSafeArea: true)
    attributes.roundCorners = .top(radius: 20)
    attributes.displayDuration = .infinity
    attributes.screenBackground = .color(color: EKColor(UIColor(white: 0, alpha: 0.7)))
    attributes.shadow = .active(with: .init(color: .black, opacity: 0.3, radius: 8))
    attributes.screenInteraction = .dismiss
    attributes.entryInteraction = .absorbTouches
    attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .jolt)
    attributes.roundCorners = .all(radius: 25)
    attributes.exitAnimation = .init(translate: .init(duration: 0.2))
    attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.2)))
    attributes.positionConstraints.verticalOffset = 10
    attributes.positionConstraints.size = .init(width: .offset(value: 20), height: .intrinsic)
    
    var themeImage: EKPopUpMessage.ThemeImage?
    
    if let image = image {
        themeImage = .init(image: .init(image: image, size: CGSize(width: 60, height: 60), contentMode: .scaleAspectFit))
    }
    
    let title = EKProperty.LabelContent(text: title, style: .init(font: UIFont(name: "ITCAvantGardePro-Bk", size: 24)!, color: .white, alignment: .center))
    let description = EKProperty.LabelContent(text: description, style: .init(font: UIFont(name: "Bellota-Regular", size: 16)!, color: .white, alignment: .center))
    let button = EKProperty.ButtonContent(label: .init(text: buttonTitle, style: .init(font: UIFont(name: "ITCAvantGardePro-Bk", size: 16)!, color: EKColor(UIColor(rgb: 0x616161)))), backgroundColor: .white, highlightedBackgroundColor: EKColor(UIColor(rgb: 0x616161).withAlphaComponent(0.05)))
    let message = EKPopUpMessage(themeImage: themeImage, title: title, description: description, button: button) {
        completion()
    }
    
    let contentView = EKPopUpMessageView(with: message)
    SwiftEntryKit.display(entry: contentView, using: attributes)
}

func showCenterAlertView(title: String, message: String, okButton: String, cancelButton: String, okButtonColor: EKColor? = nil, cancelButtonColor: EKColor? = nil, completion: @escaping () -> Void) {
    var attributes: EKAttributes
    attributes = EKAttributes.centerFloat
    attributes.windowLevel = .alerts
    attributes.displayDuration = .infinity
    attributes.entryInteraction = .absorbTouches
    attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .jolt)
    attributes.screenBackground = .color(color: EKColor(UIColor(white: 0, alpha: 0.7)))
    attributes.entryBackground = .color(color: EKColor(light: .white, dark: .darkGray))
    attributes.screenInteraction = .dismiss
    attributes.roundCorners = .all(radius: 8)
    attributes.entranceAnimation = .init(translate: .init(duration: 0.7, spring: .init(damping: 0.7, initialVelocity: 0)),
                                         scale: .init(from: 0.7, to: 1, duration: 0.4, spring: .init(damping: 1, initialVelocity: 0)))
    attributes.exitAnimation = .init(translate: .init(duration: 0.2))
    attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.35)))
    attributes.positionConstraints.size = .init(width: .offset(value: 20), height: .intrinsic)
    let title = EKProperty.LabelContent(text: title, style: .init(font: UIFont(name: "BerlinSansFBDemi-Bold", size: 32)!, color: EKColor(light: .darkGray, dark: .white), alignment: .center))
    let description = EKProperty.LabelContent(text: message, style: .init(font: UIFont(name: "Bellota-Regular", size: 15)!, color: EKColor(light: UIColor(white: 0.4, alpha: 1), dark: .white), alignment: .center))
    let simpleMessage = EKSimpleMessage(title: title, description: description)
    
    let buttonFont = UIFont(name: "ITCAvantGardePro-Bk", size: 16)!
    
    var closeButtonLabelStyle: EKProperty.LabelStyle?
    if cancelButtonColor == nil {
        closeButtonLabelStyle = EKProperty.LabelStyle(font: buttonFont, color: EKColor(light: .darkGray, dark: .white))
    } else {
        closeButtonLabelStyle = EKProperty.LabelStyle(font: buttonFont, color: cancelButtonColor!)
    }
    let closeButtonLabel = EKProperty.LabelContent(text: cancelButton, style: closeButtonLabelStyle!)
    let closeButton = EKProperty.ButtonContent(label: closeButtonLabel, backgroundColor: .clear, highlightedBackgroundColor:  EKColor(UIColor.darkGray.withAlphaComponent(0.05))) {
        SwiftEntryKit.dismiss()
    }
    
    var okButtonLabelStyle: EKProperty.LabelStyle?
    if okButtonColor == nil {
        okButtonLabelStyle = EKProperty.LabelStyle(font: buttonFont, color: EKColor(UIColor.cancelRed))
    } else {
        okButtonLabelStyle = EKProperty.LabelStyle(font: buttonFont, color: okButtonColor!)
    }
    let okButtonLabel = EKProperty.LabelContent(text: okButton, style: okButtonLabelStyle!)
    let okButton = EKProperty.ButtonContent(label: okButtonLabel, backgroundColor: .clear, highlightedBackgroundColor:  EKColor(UIColor.cancelRed.withAlphaComponent(0.05))) {
        completion()
    }
    
    var buttonsBarContent: EKProperty.ButtonBarContent?
    if okButtonColor == nil {
        buttonsBarContent = EKProperty.ButtonBarContent(with: okButton, closeButton, separatorColor: EKColor(UIColor.lightGray), expandAnimatedly: true)
    } else {
        buttonsBarContent = EKProperty.ButtonBarContent(with: closeButton, okButton, separatorColor: EKColor(UIColor.lightGray), expandAnimatedly: true)
    }
    
    let alertMessage = EKAlertMessage(simpleMessage: simpleMessage, buttonBarContent: buttonsBarContent!)
    
    let contentView = EKAlertMessageView(with: alertMessage)
    
    SwiftEntryKit.display(entry: contentView, using: attributes)
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

func calcAge(birthday: String) -> Int {
    let dateFormater = DateFormatter()
    dateFormater.dateFormat = "MM/dd/yyyy"
    let birthdayDate = dateFormater.date(from: birthday)
    let calendar: NSCalendar! = NSCalendar(calendarIdentifier: .gregorian)
    let now = Date()
    let calcAge = calendar.components(.year, from: birthdayDate!, to: now, options: [])
    let age = calcAge.year
    return age!
}

func sendPushNotification(notData: [String: Any]) {
    let url = URL(string: "https://fcm.googleapis.com/fcm/send")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = try? JSONSerialization.data(withJSONObject:notData, options: [])
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("key=AAAANpOP_Uo:APA91bH2QcLQ9d43ZhkEam3GM5dL-TXgLvCPL33TrfHceVfPuoyPj8aYVsdVRpl07EbTa_Uo3d4xhpgjA9gRVdtTg6qyqV5Ddk579QwYXnzNicbuOoyd8vCosECo8T0eFb_E0LO460w0", forHTTPHeaderField: "Authorization")
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

func checkLibraryPermission(completion: @escaping () -> Void) {
    
    let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
    switch photoAuthorizationStatus {
    case .authorized:
        completion()
    case .notDetermined:
        PHPhotoLibrary.requestAuthorization({ newStatus in
            if newStatus == PHAuthorizationStatus.authorized {
                DispatchQueue.main.async {
                    completion()
                }
            } else {
               checkLibraryPermission() {}
            }
        })
    case .restricted:
        showPopupMessage(title: "Impossible !", buttonTitle: "Autoriser", description: "Swipster a besoin d'accéder à votre Pellicule afin de choisir une photo", image: #imageLiteral(resourceName: "ic_error_all_light_48pt")) {
            let settingsAppURL = URL(string: UIApplication.openSettingsURLString)!
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(settingsAppURL)
            } else {
                UIApplication.shared.openURL(settingsAppURL)
            }
        }
    case .denied:
        DispatchQueue.main.async {
            showPopupMessage(title: "Impossible !", buttonTitle: "Autoriser", description: "Swipster a besoin d'accéder à votre Pellicule afin de choisir une photo", image: #imageLiteral(resourceName: "ic_error_all_light_48pt")) {
                let settingsAppURL = URL(string: UIApplication.openSettingsURLString)!
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(settingsAppURL)
                } else {
                    UIApplication.shared.openURL(settingsAppURL)
                }
            }
        }
        
    default:
        break
    }
}

func checkCameraPermission(completion: @escaping () -> Void) {
        
    let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)

    switch (authStatus){

    case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { success in
            if success {
                DispatchQueue.main.async {
                    completion()
                }
            } else {
                checkCameraPermission() {}
            }
        }
    case .restricted:
        print("")
    case .denied:
        DispatchQueue.main.async {
            showPopupMessage(title: "Impossible !", buttonTitle: "Autoriser", description: "Swipster a besoin d'accéder à votre caméra afin de prendre une photo.", image: #imageLiteral(resourceName: "ic_error_all_light_48pt")) {
                let settingsAppURL = URL(string: UIApplication.openSettingsURLString)!
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(settingsAppURL)
                } else {
                    UIApplication.shared.openURL(settingsAppURL)
                }
            }
        }
    case .authorized:
        completion()
    @unknown default:
        print("")
    }
}

func hideAds()->Bool {
    return UserDefaults.standard.bool(forKey: "Purchased")
}

func isAppAlreadyLaunchedOnce()->Bool{
    let defaults = UserDefaults.standard
    if let _ = defaults.string(forKey: "isAppAlreadyLaunchedOnce") {
        return true
    } else {
        defaults.set(true, forKey: "isAppAlreadyLaunchedOnce")
        return false
    }
}
