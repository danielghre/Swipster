//
//  AppDelegate.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 22/03/2018.
//  Copyright © 2018 Swipster Inc. All rights reserved.
//

import UIKit
import Firebase
import FirebaseInstanceID
import FirebaseMessaging
import UserNotifications
import SwiftEntryKit
import FacebookCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate {
    
    var token, firebaseToken: String?
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        Database.database().isPersistenceEnabled = true
        
        if UserDefaults.standard.bool(forKey: "active") {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "swipe") as! SwipeViewController
            window?.rootViewController = vc
        }
        
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        registerForPushNotifications()
        
        AppUpdater.shared.showUpdate(withConfirmation: true)
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard let appId = Settings.appID else { return false }
        if url.scheme != nil && url.scheme!.hasPrefix("fb\(appId)") && url.host ==  "authorize" {
            return ApplicationDelegate.shared.application(app, open: url, options: options)
        }
        return false
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        AppEvents.activateApp()
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
    
    private func showChatNotificationMessage(uid: String?=nil, pictureURL: String?=nil, title : String, time: String, text: String) {
        var attributes = EKAttributes.topFloat
        attributes = .topToast
        attributes.hapticFeedbackType = .success
        attributes.entryBackground = .color(color: EKColor(UIColor.darkGrey))
        attributes.entranceAnimation = .translation
        attributes.exitAnimation = .translation
        attributes.scroll = .edgeCrossingDisabled(swipeable: true)
        attributes.displayDuration = 5
        attributes.shadow = .active(with: .init(color: EKColor(UIColor.darkGrey), opacity: 0.5, radius: 10))
        let action = { [weak self] in
            if (pictureURL != nil && uid != nil) {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "messageView") as! UINavigationController
                self?.window?.rootViewController!.present(vc, animated: false, completion: {()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        let dst = vc.viewControllers.first as! MessagesController
                        Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value) { (snapshot) in
                            guard let dict = snapshot.value as? [String: Any] else { return }
                            var me = User(dictionary: dict)
                            me.uid = uid!
                            dst.showChatControllerForUser(me)
                        }
                    }
                })
            }
        }
        attributes.entryInteraction.customTapActions.append(action)
        
        let title = EKProperty.LabelContent(text: title, style: .init(font: .systemFont(ofSize: 14), color: .white))
        let time = EKProperty.LabelContent(text: time, style: .init(font: .systemFont(ofSize: 12), color: .white))
        let description = EKProperty.LabelContent(text: text, style: .init(font: .systemFont(ofSize: 10), color: .white))
        if let pictureURL = pictureURL {
            ImageService.getImage(withURL: URL(string: pictureURL)) { (image) in
                let image = EKProperty.ImageContent.thumb(with: image!, edgeSize: 35)
                let simpleMessage = EKSimpleMessage(image: image, title: title, description: description)
                let notificationMessage = EKNotificationMessage(simpleMessage: simpleMessage, auxiliary: time)
                let contentView = EKNotificationMessageView(with: notificationMessage)
                SwiftEntryKit.display(entry: contentView, using: attributes)
            }
        } else {
            let simpleMessage = EKSimpleMessage(title: title, description: description)
            let notificationMessage = EKNotificationMessage(simpleMessage: simpleMessage, auxiliary: time)
            let contentView = EKNotificationMessageView(with: notificationMessage)
            SwiftEntryKit.display(entry: contentView, using: attributes)
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        if UserDefaults.standard.bool(forKey: "active") {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let timestamp = Int(Date().timeIntervalSince1970)
            let values = ["lastLoginDate" : timestamp]
            Database.database().reference().child("users").child(uid).updateChildValues(values) { (err, snapshot) in
                if err != nil {
                    print("something went wrong")
                }
            }
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        let aps = userInfo["aps"] as? NSDictionary
        let alert = aps!["alert"] as? NSDictionary
        let title = alert!["title"] as? String
        let body = alert!["body"] as? String
        let picURL = userInfo["gcm.notification.pictureURL"] as? String
        let userUID = userInfo["gcm.notification.uid"] as? String
        
        if picURL != nil {
            if title! == "Swipster" {
                showChatNotificationMessage(uid: userUID, pictureURL: picURL! as String, title: "Bravo !", time: "Maintenant", text: String(body!))
            } else if UIApplication.topViewController() is ChatLogController {
                guard let vc = UIApplication.topViewController() as? ChatLogController else { return }
                if vc.chatUser?.uid != userUID {
                    showChatNotificationMessage(uid: userUID, pictureURL: picURL! as String, title: String(title!), time: "Maintenant", text: String(body!))
                }
            } else {
                showChatNotificationMessage(uid: userUID, pictureURL: picURL! as String, title: String(title!), time: "Maintenant", text: String(body!))
            }
        } else {
            showChatNotificationMessage(title: title!, time: "Maintenant", text: String(body!))
        }
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        firebaseToken = fcmToken
    }
    
    func registerForPushNotifications() {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self]
                (granted, error) in
                guard granted else { return }
                self?.getNotificationSettings()
            }
        } else {
            let settings = UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func getNotificationSettings() {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                guard settings.authorizationStatus == .authorized else { return }
                DispatchQueue.main.async(execute: {
                    UIApplication.shared.registerForRemoteNotifications()
                })
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    func application(_ application: UIApplication,didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data){
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        token = tokenParts.joined()
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
}
