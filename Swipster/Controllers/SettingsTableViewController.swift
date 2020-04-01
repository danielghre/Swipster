//
//  SettingsTableViewController.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 26/09/2018.
//  Copyright © 2018 Swipster Inc. All rights reserved.
//

import Firebase
import RangeSeekSlider
import SafariServices
import MessageUI
import MXSegmentedControl
import SwiftEntryKit

protocol SettingsChangeDelegate: AnyObject {
    func didUpdateDetail()
}

class SettingsTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MFMailComposeViewControllerDelegate, UIAdaptivePresentationControllerDelegate {
    
    var user: User?
    
    @IBOutlet private weak var segmentedControl: MXSegmentedControl!
    @IBOutlet weak var ageSlider: RangeSeekSlider!
    @IBOutlet private weak var switchProfil: UISwitch!
    weak var delegate: SettingsChangeDelegate?
    
    @IBAction func publiqueProfil(_ sender: Any) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(uid)
        var values = [String: String]()
        values = switchProfil.isOn ? ["public": "true"] : ["public": "false"]
        ref.updateChildValues(values, withCompletionBlock: { [weak self] (err, ref) in
            if err != nil {
                print(err ?? "")
                return
            }
            self?.delegate?.didUpdateDetail()
        })
    }
    
    
    @IBAction func dismissView(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBOutlet private weak var ageLabel: UILabel!
    @IBOutlet private weak var distanceValue: UILabel!
    @IBOutlet private weak var distanceSlider: UISlider!
    
    @IBAction func distance(_ sender: UISlider) {
        distanceValue.text = "\(Int(sender.value)) Kms"
    }

    @objc func share(recognizer: UITapGestureRecognizer) {
        let activityVC = UIActivityViewController(activityItems: ["Découvrez Swipster... Pour un soir ou pour la vie, nous répondons à toutes vos envies ! 😍 🍻 🔥 https://swipster.io"], applicationActivities: nil)
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
        mailComposerVC.setMessageBody("\n\n ---\nN'écrivez pas en dessous de cette ligne.\n\(user!.parentUID ?? "")", isHTML: false)
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
                self?.navigationController?.viewControllers.removeAll()
                let storyboard = UIStoryboard(name: "LoginScreen", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "welcomeView")
                UIApplication.shared.keyWindow?.setRootViewController(vc, options: .init(direction: .toBottom, style: .linear))
                SwiftEntryKit.dismiss(.displayed)
            }
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
        let ref = Database.database().reference().child("user-messages")
        ref.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let refMessage = ref.child(uid).child(child.key)
                ref.child(child.key).child(uid).removeValue()
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
                        Database.database().reference().child("messages").child(child.key).removeValue()
                    }
                }
            }
            ref.child(uid).removeValue()
        }
        
        Database.database().reference().child("users").child(uid).removeValue { (err, ref) in
            if err != nil {
                SwiftEntryKit.dismiss(.all)
                showPopupMessage(title: "Impossible..", buttonTitle: "Compris !", description: "Une erreur est survenu, veuillez réessayer plus tard !", image: #imageLiteral(resourceName: "ic_error_all_light_48pt")) {
                    SwiftEntryKit.dismiss()
                }
                return
            }
            Storage.storage().reference().child("profile_images").child("\(uid).jpg").delete { (err) in
                Auth.auth().currentUser?.delete(completion: { [weak self] (err) in
                    self?.navigationController?.viewControllers.removeAll()
                    let storyBoard: UIStoryboard = UIStoryboard(name: "LoginScreen", bundle: nil)
                    let vc = storyBoard.instantiateViewController(withIdentifier: "welcomeView") as! ViewController
                    vc.modalPresentationStyle = .fullScreen
                    UIApplication.shared.keyWindow?.setRootViewController(vc, options: .init(direction: .toBottom, style: .linear))
                    SwiftEntryKit.dismiss(.all)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                        showPopupMessage(title: "Compte supprimé avec succès", buttonTitle: "J'ai compris", description: "", image: #imageLiteral(resourceName: "ic_done_all_light_48pt")) {
                            SwiftEntryKit.dismiss(.all)
                        }
                    })
                    UserDefaults.standard.removeObject(forKey: "active")
                    UserDefaults.standard.synchronize()
                })
            }
        }
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
        } else {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        IAPService.shared.getProducts()
        ageSlider.delegate = self
        configureSegmentedControl()
        getUserInfo()
        configureTapOnSection()
        configureTableViewFooter()
        
        let panGesture = UIPanGestureRecognizer(target: nil, action:nil)
        panGesture.cancelsTouchesInView = false
        ageSlider.addGestureRecognizer(panGesture)
        
        distanceSlider.addTarget(self, action: #selector(sliderDidEndSliding(_:)), for: [.touchUpInside, .touchUpOutside])
    }
    
    @objc func sliderDidEndSliding(_ sender: UISlider) {
        
        let lookingDistance = "\(Int(sender.value))"
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let ref = Database.database().reference().child("users").child(uid)

        let values = ["lookingDistance": lookingDistance]

        ref.updateChildValues(values, withCompletionBlock: { [weak self] (err, ref) in
            if err != nil {
                print(err ?? "")
                return
            }
            self?.delegate?.didUpdateDetail()
        })
    }
    
    func configureSegmentedControl() {
        segmentedControl.append(title: "Hommes")
        segmentedControl.append(title: "Femmes")
        segmentedControl.append(title: "Les deux")
        segmentedControl.font = UIFont(name: "ITCAvantGardePro-Bk", size: 17)!
    }
    
    func configureTapOnSection() {
        let shareRecognizer = UITapGestureRecognizer(target: self, action: #selector(share))
        let contactRecognizer = UITapGestureRecognizer(target: self, action: #selector(contact))
        let policyRecognizer = UITapGestureRecognizer(target: self, action: #selector(confidentiality))
        let logoutRecognizer = UITapGestureRecognizer(target: self, action: #selector(logout))
        let deleteRecognizer = UITapGestureRecognizer(target: self, action: #selector(deleteAccount))
        let rateTheApp = UITapGestureRecognizer(target: self, action: #selector(rate))
        let tuto = UITapGestureRecognizer(target: self, action: #selector(showTuto))
        let removeAds = UITapGestureRecognizer(target: self, action: #selector(showRemoveAds))
        let retorePurchased = UITapGestureRecognizer(target: self, action: #selector(restorePurchased))
        
        let dictView = [shareRecognizer: shareSection, contactRecognizer: contactSection, policyRecognizer: policySection, logoutRecognizer: logoutSection, deleteRecognizer: deleteMyAccountSection, rateTheApp: rateApp, tuto: tutoView, removeAds: removeAdsSection, retorePurchased: restorePurchasedSection]
        
        for tapGesture in dictView {
            tapGesture.key.numberOfTapsRequired = 1
            tapGesture.value?.addGestureRecognizer(tapGesture.key)
        }
    }
    
    func configureTableViewFooter() {
        let tableViewFooter = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 85))
        let name = UILabel(frame: CGRect(x: 0, y: 20, width: tableView.frame.width, height: 35))
        name.font = UIFont(name: "Bellota-Regular", size: 28)
        name.text = "Swipster"
        name.textColor = .purple
        name.textAlignment = .center
        let version = UILabel(frame: CGRect(x: 0, y: 55, width: tableView.frame.width, height: 20))
        version.font = UIFont(name: "Bellota-Regular", size: 17)
        version.text = getVersion()
        version.textColor = .purple
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
        ref.updateChildValues(values, withCompletionBlock: { [weak self] (err, ref) in
            if err != nil {
                print(err ?? "")
                return
            }
            self?.delegate?.didUpdateDetail()
        })
    }
    
    func getUserInfo() {
        distanceSlider.setValue(Float(user!.lookingDist)!, animated: false)
        distanceValue.text = "\(user!.lookingDist) Kms"
        
        if user!.lookingFor == "male" {
            segmentedControl.select(index: 0, animated: false)
        } else if user!.lookingFor == "female" {
            segmentedControl.select(index: 1, animated: false)
        } else {
            segmentedControl.select(index: 2, animated: false)
        }
        
        if user!.active == "true" {
            switchProfil.setOn(true, animated:false)
        } else if user!.active == "false" {
            switchProfil.setOn(false, animated:false)
        }
        if self.user!.minAge != "" {
            ageSlider.selectedMinValue = CGFloat(Double(user!.minAge)!)
            ageSlider.selectedMaxValue = CGFloat(Double(user!.maxAge)!)
        }
        
        ageLabel.text = user!.minAge + " - " + user!.maxAge
        segmentedControl.addTarget(self, action: #selector(changeIndex(segmentedControl:)), for: .valueChanged)
    }

}

extension SettingsTableViewController: RangeSeekSliderDelegate {
    func rangeSeekSlider(_ slider: RangeSeekSlider, didChange minValue: CGFloat, maxValue: CGFloat) {
        if Int(maxValue) < 22 {
            return
        }
        ageLabel.text = "\(Int(minValue)) - \(Int(maxValue))"
    }
    
    func didEndTouches(in slider: RangeSeekSlider) {

        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let ref = Database.database().reference().child("users").child(uid)
        
        let values = ["minAge": String(Int(slider.selectedMinValue)), "maxAge": String(Int(slider.selectedMaxValue))]

        ref.updateChildValues(values, withCompletionBlock: { [weak self] (err, ref) in
            if err != nil {
                print(err ?? "")
                return
            }
            self?.delegate?.didUpdateDetail()
        })
    }
}
