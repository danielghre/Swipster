//
//  SettingsTableViewController.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 26/09/2018.
//  Copyright © 2018 Swipster Inc. All rights reserved.
//

import UIKit
import FacebookLogin
import CoreLocation
import Firebase
import FirebaseStorage
import FirebaseDatabase
import RangeUISlider
import SafariServices
import MessageUI
import MXSegmentedControl
import SwiftEntryKit


class SettingsTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MFMailComposeViewControllerDelegate{
    
    var user: User?
    
    @IBOutlet private weak var segmentedControl: MXSegmentedControl!
    @IBOutlet private weak var ageSlider: RangeUISlider!
    @IBOutlet private weak var switchProfil: UISwitch!
    
    @IBAction func publiqueProfil(_ sender: Any) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(uid)
        var values = [String: String]()
        values = switchProfil.isOn ? ["public": "true"] : ["public": "false"]
        ref.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if err != nil {
                print(err ?? "")
                return
            }
        })
    }
    
    @IBOutlet private weak var ageLabel: UILabel!
    @IBOutlet private weak var distanceValue: UILabel!
    @IBOutlet private weak var distanceSlider: UISlider!
    
    @IBAction func distance(_ sender: UISlider) {
        var lookingDistance = ""
        distanceValue.text = String(Int(sender.value)) + " Kms"
        lookingDistance = String(Int(sender.value))
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let ref = Database.database().reference().child("users").child(uid)

        let values = ["lookingDistance": lookingDistance]

        ref.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if err != nil {
                print(err ?? "")
                return
            }
        })
    }

    @objc func share(recognizer: UITapGestureRecognizer) {
        let activityVC = UIActivityViewController(activityItems: ["Découvrez Swipster... Evitez les pertes de temps, matchez uniquement selon vos envies ! https://swipster.io"], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = view
        present(activityVC, animated: true)
    }
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    func configureMailController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        mailComposerVC.setToRecipients(["contact@swipster.io"])
        mailComposerVC.setSubject("[" + randomString(length: 6) + "]" + " Feedback de " + user!.first_name)
        return mailComposerVC
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    @objc func contact(recognizer: UITapGestureRecognizer) {
        let mailComposeViewController = configureMailController()
        if MFMailComposeViewController.canSendMail() {
            present(mailComposeViewController, animated: true)
        } else {
            showPopupMessage(title: "Impossible !", buttonTitle: "Compris !", description: "Votre iPhone ne peut pas envoyer de mail !", image: #imageLiteral(resourceName: "ic_error_all_light_48pt")) {
                SwiftEntryKit.dismiss(.all)
            }
        }
    }
    
    @objc func confidentiality(recognizer: UITapGestureRecognizer) {
        let svc = SFSafariViewController(url: URL(string: "https://www.swipster.io/privacy")!)
        present(svc, animated: true)
    }
    
    @objc func logout(recognizer: UITapGestureRecognizer) {
        var message = ""
        
        message = user?.gender == "male" ? "Êtes-vous sûr de vouloir vous déconnecter ?" : "Êtes-vous sûre de vouloir vous déconnecter ?"
        
        showCenterAlertView(title: "Déjà ! 😢", message: message, okButton: "Déconnexion", cancelButton: "Annuler") { [weak self] in
            logoutUser {
                let storyboard = UIStoryboard(name: "LoginScreen", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "welcomeView")
                vc.modalPresentationStyle = .fullScreen
                self!.present(vc, animated: false, completion: {
                    SwiftEntryKit.dismiss(.displayed)
                })
            }
//            weak var pvc = self.presentingViewController
//
//            self.dismiss(animated: true) {
//                let storyboard = UIStoryboard(name: "Main", bundle: nil)
//                let vc = storyboard.instantiateViewController(withIdentifier: "welcomeView") as! ViewController
//                pvc?.present(vc, animated: true, completion: nil)
//            }
        }
    }
    
    @objc func deleteAccount(recognizer: UITapGestureRecognizer) {
        var message = "En supprimant votre compte, vous perdrez votre profil, vos messages, vos photos, ainsi que vos matchs. Cette action est irréversible.\n\nÊtes-vous "
                
        message = user?.gender == "male" ? message + "sûr ?" : message + "sûre ?"
        
        showCenterAlertView(title: "Vraiment 😭", message: message, okButton: "OUI", cancelButton: "NON") { [weak self] in
            self?.removeAccount()
        }
    }
    
    fileprivate func removeAccount(){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        showLoadingView(text: "Veuillez patienter...")
        let refUM = Database.database().reference().child("user-messages").child(uid)
        refUM.observeSingleEvent(of: .value) { (snapshot) in
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let refMessage = Database.database().reference().child("user-messages").child(uid).child(child.key)
                refMessage.observeSingleEvent(of: .value) { (snapshot) in
                    for child in snapshot.children.allObjects as! [DataSnapshot] {
                        Database.database().reference().child("messages").child(child.key).observeSingleEvent(of: .value) { (snapshot) in
                            guard let dict = snapshot.value as? [String: Any] else { return }
                            let message = Message(dictionary: dict)
                            if message.imageUrl != nil{
                                let messagesImagesRef = Storage.storage().reference(forURL: message.imageUrl!)
                                messagesImagesRef.delete { error in
                                    if error != nil {
                                        print(error ?? "")
                                    }
                                }
                            }
                        }
                        Database.database().reference().child("messages").child(child.key).removeValue(completionBlock: { error, ref  in
                            if error != nil {
                                print(error ?? "")
                            }
                        })
                    }
                }
            }
        }
        let ref = Database.database().reference().child("users").child(uid)
        ref.removeValue(completionBlock: { error, ref  in
            if error != nil {
                print(error ?? "")
            }
            let refUserMessage = Database.database().reference().child("user-messages").child(uid)
            refUserMessage.removeValue(completionBlock: { error, ref  in
                if error != nil {
                    print(error ?? "")
                }
                let refRacine = Database.database().reference().child("user-messages")
                refRacine.observeSingleEvent(of: .value) { (snapshot) in
                    for child in snapshot.children.allObjects as! [DataSnapshot] {
                        let refMessage = Database.database().reference().child("user-messages").child(child.key)
                        refMessage.observeSingleEvent(of: .value) { (snapshot) in
                            for child in snapshot.children.allObjects as! [DataSnapshot] {
                                if child.key == uid {
                                    refMessage.child(child.key).removeValue(completionBlock: { error, ref  in
                                        if error != nil {
                                            print(error ?? "")
                                        }
                                    })
                                }
                            }
                        }
                    }
                }
            })
            let profilRef = Storage.storage().reference().child("profile_images").child("\(uid).jpg")
            profilRef.delete { error in
                if error != nil {
                    print(error ?? "")
                }
            }
        })
        
        Auth.auth().currentUser?.delete(completion: { [weak self] (err) in
            let storyBoard: UIStoryboard = UIStoryboard(name: "LoginScreen", bundle: nil)
            let vc = storyBoard.instantiateViewController(withIdentifier: "welcomeView") as! ViewController
            vc.modalPresentationStyle = .fullScreen
            self?.present(vc, animated: true, completion: {
                SwiftEntryKit.dismiss(.all)
                showPopupMessage(title: "Compte supprimé avec succès", buttonTitle: "J'ai compris", description: "", image: #imageLiteral(resourceName: "ic_done_all_light_48pt")) {
                    SwiftEntryKit.dismiss(.all)
                }
            })
        })
        UserDefaults.standard.removeObject(forKey: "active")
        UserDefaults.standard.synchronize()
    }
    
    func showRatingView(attributes: EKAttributes) {
        let imageUnselect: UIImage?
        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle == .light {
                imageUnselect = UIImage(named: "ic_star_unselected")!
            } else {
                imageUnselect = UIImage(named: "ic_star_unselected")!.withTintColor(.white)
            }
        } else {
            imageUnselect = UIImage(named: "ic_star_unselected")!
        }
        
        let unselectedImage = EKProperty.ImageContent(image: imageUnselect!)
        let selectedImage = EKProperty.ImageContent(image: UIImage(named: "ic_star_selected")!)
        
        let initialTitle = EKProperty.LabelContent(text: "Vous aimez Swipster ?", style: .init(font: UIFont(name: "ITCAvantGardePro-Bk", size: 20)!, color: EKColor(light: .darkGray, dark: .white), alignment: .center))
        let initialDescription = EKProperty.LabelContent(text: "Notez nous !", style: .init(font: UIFont(name: "Bellota-Regular", size: 16)!, color: EKColor(light: UIColor(white: 0.4, alpha: 1), dark: .white), alignment: .center))
        
        let items = [("💩", "Nul !"), ("🤨", "Ahhh ?!"), ("👍", "OK !"), ("👌", "J'aime !"), ("😍", "La meilleure appli !")].map { texts -> EKProperty.EKRatingItemContent in
            let itemTitle = EKProperty.LabelContent(text: texts.0, style: .init(font: .systemFont(ofSize: 48, weight: .medium), color: EKColor(light: UIColor(white: 0.4, alpha: 1), dark: .white), alignment: .center))
            let itemDescription = EKProperty.LabelContent(text: texts.1, style: .init(font: .systemFont(ofSize: 20, weight: .light), color: EKColor(light: UIColor(white: 0.4, alpha: 1), dark: .white), alignment: .center))
            return .init(title: itemTitle, description: itemDescription, unselectedImage: unselectedImage, selectedImage: selectedImage)
        }
        
        var message: EKRatingMessage!
        
        let font = UIFont(name: "ITCAvantGardePro-Bk", size: 16)!
        let grayColor = EKColor(UIColor.darkGrey.withAlphaComponent(0.05))
        let closeButtonLabelStyle = EKProperty.LabelStyle(font: font, color: EKColor(light: .darkGray, dark: .white))
        let closeButtonLabel = EKProperty.LabelContent(text: "Annuler", style: closeButtonLabelStyle)
        let closeButton = EKProperty.ButtonContent(label: closeButtonLabel, backgroundColor: .clear, highlightedBackgroundColor:  grayColor) {
            SwiftEntryKit.dismiss {
            }
        }

        let pinkyColor = EKColor(UIColor.cancelRed.withAlphaComponent(0.05))
        let okButtonLabelStyle = EKProperty.LabelStyle(font: font, color: EKColor(UIColor.cancelRed))
        let okButtonLabel = EKProperty.LabelContent(text: "Laisser un avis", style: okButtonLabelStyle)
        let okButton = EKProperty.ButtonContent(label: okButtonLabel, backgroundColor: .clear, highlightedBackgroundColor:  pinkyColor) { [weak self] in
            SwiftEntryKit.dismiss()
            self?.rateApp(appId: "1444964003")
        }
        
        let buttonsBarContent = EKProperty.ButtonBarContent(with: closeButton, okButton, separatorColor: EKColor(UIColor.lightGray), expandAnimatedly: true)
        
        message = EKRatingMessage(initialTitle: initialTitle, initialDescription: initialDescription, ratingItems: items, buttonBarContent: buttonsBarContent) { index in
            // Rating selected - do something
        }
        
        let contentView = EKRatingMessageView(with: message)
        SwiftEntryKit.display(entry: contentView, using: attributes)
    }
    
    @objc func rate() {
        var attributes: EKAttributes
        attributes = .centerFloat
        attributes.windowLevel = .alerts
        attributes.screenInteraction = .dismiss
        attributes.entryInteraction = .absorbTouches
        attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .jolt)
        attributes.screenBackground = .color(color: EKColor(UIColor(white: 0, alpha: 0.7)))
        attributes.entryBackground = .color(color: EKColor(light: .white, dark: .darkGray))
        attributes.entranceAnimation = .init(scale: .init(from: 0.9, to: 1, duration: 0.4, spring: .init(damping: 0.8, initialVelocity: 0)), fade: .init(from: 0, to: 1, duration: 0.3))
        attributes.exitAnimation = .init(translate: .init(duration: 0.2))
        attributes.displayDuration = .infinity
        
        showRatingView(attributes: attributes)
    }
    
    fileprivate func rateApp(appId: String) {
        openUrl("itms-apps:itunes.apple.com/us/app/apple-store/id\(appId)?mt=8&action=write-review")
    }
    
    fileprivate func openUrl(_ urlString:String) {
        let url = URL(string: urlString)!
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    @objc func showTuto(){
        let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
        if let walkthroughViewController = storyboard.instantiateViewController(withIdentifier: "WalkthroughViewController") as? WalkthroughViewController {
            present(walkthroughViewController, animated: true, completion: nil)
        }
    }
    
    @objc func showRemoveAds() {
        if user?.purchased != true {
            IAPService.shared.purshase(product: .nonConsumable)
        }else {
            showPopupMessage(title: "Merci !", buttonTitle: "Compris !", description: "Vous avez déjà supprimer les publicités auparavant, vous pouvez dès à présent profiter à 100% de l'application !", image: #imageLiteral(resourceName: "ic_done_all_light_48pt")) {
                SwiftEntryKit.dismiss(.all)
            }
        }
    }
    
    @objc func restorePurchased() {
        IAPService.shared.restorePurshases()
    }
    
    @IBOutlet private weak var shareSection: UIView!
    @IBOutlet private weak var contactSection: UIView!
    @IBOutlet private weak var policySection: UIView!
    @IBOutlet private weak var logoutSection: UIView!
    @IBOutlet private weak var deleteMyAccountSection: UIView!
    @IBOutlet private weak var rateApp: UIView!
    @IBOutlet private weak var tutoView: UIView!
    @IBOutlet private weak var removeAdsSection: UIView!
    @IBOutlet private weak var restorePurchasedSection: UIView!
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if hideAds() {
            if indexPath.section == 0 {
                cell.isHidden = true
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 &&  user?.purchased != false{
            return 0
        } else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        IAPService.shared.getProducts()
        ageSlider.delegate = self
        configureSegmentedControl()
        getUserInfo()
        configureTapOnSection()
        configureTableViewFooter()
    }
    
    func configureSegmentedControl() {
        segmentedControl.append(title: "Hommes")
        segmentedControl.append(title: "Femmes")
        segmentedControl.append(title: "Les deux")
        segmentedControl.font = UIFont(name: "ITCAvantGardePro-Bk", size: 17)!
        segmentedControl.selectedTextColor = UIColor.purple
        segmentedControl.indicator.lineView.backgroundColor = UIColor.purple
        segmentedControl.addTarget(self, action: #selector(changeIndex(segmentedControl:)), for: .valueChanged)
    }
    
    func configureTapOnSection() {
        let shareRecognizer = UITapGestureRecognizer(target: self, action: #selector(share))
        shareRecognizer.numberOfTapsRequired = 1
        shareSection.addGestureRecognizer(shareRecognizer)
        
        let contactRecognizer = UITapGestureRecognizer(target: self, action: #selector(contact))
        contactRecognizer.numberOfTapsRequired = 1
        contactSection.addGestureRecognizer(contactRecognizer)
        
        let policyRecognizer = UITapGestureRecognizer(target: self, action: #selector(confidentiality))
        policyRecognizer.numberOfTapsRequired = 1
        policySection.addGestureRecognizer(policyRecognizer)
        
        let logoutRecognizer = UITapGestureRecognizer(target: self, action: #selector(logout))
        logoutRecognizer.numberOfTapsRequired = 1
        logoutSection.addGestureRecognizer(logoutRecognizer)
        
        let deleteRecognizer = UITapGestureRecognizer(target: self, action: #selector(deleteAccount))
        deleteRecognizer.numberOfTapsRequired = 1
        deleteMyAccountSection.addGestureRecognizer(deleteRecognizer)
        
        let rateTheApp = UITapGestureRecognizer(target: self, action: #selector(rate))
        rateTheApp.numberOfTapsRequired = 1
        rateApp.addGestureRecognizer(rateTheApp)
        
        let tuto = UITapGestureRecognizer(target: self, action: #selector(showTuto))
        tuto.numberOfTapsRequired = 1
        tutoView.addGestureRecognizer(tuto)
        
        let removeAds = UITapGestureRecognizer(target: self, action: #selector(showRemoveAds))
        removeAds.numberOfTapsRequired = 1
        removeAdsSection.addGestureRecognizer(removeAds)
        
        let retorePurchased = UITapGestureRecognizer(target: self, action: #selector(restorePurchased))
        retorePurchased.numberOfTapsRequired = 1
        restorePurchasedSection.addGestureRecognizer(retorePurchased)
    }
    
    func configureTableViewFooter() {
        let tableViewFooter = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 85))
        let name = UILabel(frame: CGRect(x: 0, y: 20, width: tableView.frame.width, height: 25))
        name.font = UIFont(name: "Bellota-Regular", size: 28)
        name.text = "SWIPSTER"
        name.textColor = UIColor.purple
        name.textAlignment = .center
        let version = UILabel(frame: CGRect(x: 0, y: 45, width: tableView.frame.width, height: 20))
        version.font = UIFont(name: "Bellota-Regular", size: 17)
        version.text = getVersion()
        version.textColor = UIColor.purple
        version.textAlignment = .center
        tableViewFooter.addSubview(name)
        tableViewFooter.addSubview(version)
        tableView.tableFooterView  = tableViewFooter
    }
    
    func getVersion() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        return "Version \(version)"
    }
    
    @objc func changeIndex(segmentedControl: MXSegmentedControl) {
        if #available(iOS 10.0, *) {
            let impact = UIImpactFeedbackGenerator()
            impact.impactOccurred()
        }
        var lookingfor = ""
        switch segmentedControl.selectedIndex {
        case 0:
            lookingfor = "male"
        case 1:
            lookingfor = "female"
        case 2:
            lookingfor = "both"
        default:
            break
        }
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(uid)
        let values = ["lookingFor": lookingfor]
        ref.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if err != nil {
                print(err ?? "")
                return
            }
        })
    }
    
    func getUserInfo() {
        distanceSlider.setValue(Float(user!.lookingDist)!, animated: false)
        distanceValue.text = "\(user!.lookingDist) Kms"
        
        if user!.lookingFor == "female" {
            segmentedControl.select(index: 1, animated: false)
        } else if user!.lookingFor == "male" {
            segmentedControl.select(index: 0, animated: false)
        } else {
            segmentedControl.select(index: 2, animated: false)
        }
        
        if user!.active == "true" {
            switchProfil.setOn(true, animated:false)
        } else if user!.active == "false" {
            switchProfil.setOn(false, animated:false)
        }
        if self.user!.minAge != "" {
            ageSlider.defaultValueLeftKnob = CGFloat(Double(user!.minAge)!)
            ageSlider.defaultValueRightKnob = CGFloat(Double(user!.maxAge)!)
        }
        
        ageLabel.text = user!.minAge + " - " + user!.maxAge
    }

}

extension SettingsTableViewController: RangeUISliderDelegate {
    
    func rangeIsChanging(minValueSelected: CGFloat, maxValueSelected: CGFloat, slider: RangeUISlider){
        if Int(maxValueSelected) < 22 {
            return
        }
        ageLabel.text = String(Int(minValueSelected)) + " - " + String(Int(maxValueSelected))
    }
    
    func rangeChangeFinished(minValueSelected: CGFloat, maxValueSelected: CGFloat, slider: RangeUISlider) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let ref = Database.database().reference().child("users").child(uid)
        
        let values = ["minAge": String(Int(minValueSelected)), "maxAge": String(Int(maxValueSelected))]
        
        ref.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if err != nil {
                print(err ?? "")
                return
            }
        })
    }
}
