//
//  MenuViewController.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 22/03/2018.
//  Copyright © 2018 Swipster Inc. All rights reserved.
//

import CoreLocation
import Firebase
import SafariServices
import Photos
import SwiftEntryKit
import CropViewController

protocol MenuUpdateDelegate: AnyObject {
    func didUpdate()
}

class MenuViewController: UIViewController, CLLocationManagerDelegate {
    
    lazy var locationManager = CLLocationManager()
    var user: User?
    lazy var imagePickerController = UIImagePickerController()
    let uid = Auth.auth().currentUser?.uid
    let ref = Database.database().reference()
    weak var delegate: MenuUpdateDelegate?
    
    @IBOutlet private weak var dots: UIImageView!
    @IBOutlet private weak var ageLabel: UILabel!
    @IBOutlet private weak var charactersCount: UILabel!
    @IBOutlet private weak var textView: UITextView!
    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var imageLoader: UIActivityIndicatorView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var sexe: UILabel!
    @IBOutlet private weak var sexeIconImageView: UIImageView!
    @IBOutlet private weak var changeProfilPicButton: UIButton!
    @IBOutlet private weak var shareButton: UIButton!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UINavigationController {
            let tableVC = vc.viewControllers.first as! SettingsTableViewController
            tableVC.user = user
            tableVC.delegate = self
        }
    }
    
    @IBAction func changeProfilImage(_ sender: Any) {
        handleSelectProfileImageView()
    }
    
    @IBAction func share(_ sender: Any) {
        let activityVC = UIActivityViewController(activityItems: ["Découvrez Swipster... Pour un soir ou pour la vie, nous répondons à toutes vos envies ! 😍 🍻 🔥 https://swipster.io"], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = view
        present(activityVC, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UINavigationBar.appearance().shadowImage = UIImage()

        changeProfilPicButton.layer.cornerRadius = changeProfilPicButton.frame.width / 8
        changeProfilPicButton.titleLabel?.adjustsFontSizeToFitWidth = true
        shareButton.layer.cornerRadius = shareButton.frame.height / 5
        textView.delegate = self
        textView.tintColor = UIColor(rgb: 0x961872)
        textView.font = UIFont(name: "ITCAvantGardePro-Bk", size: textView.frame.height / 5)
        
        getUserInfo()
        configureImagePicker()
        configureLocation()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    func configureLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    func configureImagePicker() {
        imagePickerController.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        settingsPerso()
    }
    
    override func viewWillLayoutSubviews() {
        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                dots.image = dots.image?.withTintColor(.white)
            } else {
                dots.image = dots.image?.withTintColor(.black)
            }
        }
    }
    
    @objc func keyboardWillChange(notification:Notification){
        
        if notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillChangeFrameNotification{
            view.frame.origin.y = -100
        } else {
            view.frame.origin.y = 0
        }
    }
    
    func settingsPerso(){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        ref.child("users").child(uid).observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard let dict = snapshot.value as? [String: Any] else { return }
            let user = User(dictionary: dict)
            self?.user = user
            self?.getUserLocation()
        }
    }
    
    func getUserInfo() {
        guard let user = user else { return }
        let age = calcAge(birthday: user.birthday)
        ImageService.getImage(withURL: URL(string: user.pictureURL)) { [weak self] (image) in
            self?.imageView.image = image
            self?.imageLoader.stopAnimating()
        }
        imageView.clipsToBounds = true
        imageView.layer.borderColor = UIColor(rgb: 0x961872).cgColor
        imageView.layer.borderWidth = 3
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSelectProfileImageView)))
        imageView.setRounded()
        label.text = user.first_name
        ageLabel.text = String(age) + " ans"
        if(user.bio != "") {
            textView.text = user.bio
            charactersCount.text = String(120 - textView.text.count)
        }else{
            charactersCount.text = "120"
            textView.text = "Décrivez vous en moins de 120 caractères !"
            textView.font = UIFont.italicSystemFont(ofSize: 14)
        }
        switch self.user!.gender {
        case "male":
            sexeIconImageView.image = UIImage(named: "Homme")
            sexe.text = "Homme"
            break
        case "female":
            sexeIconImageView.image = UIImage(named: "Femme")
            sexe.text = "Femme"
            break
        default:
            break
        }
        getUserLocation()
    }
    
    @objc func handleSelectProfileImageView(){
        handleOpenAlertControllerForPics()
    }
    
    func handleOpenAlertControllerForPics(needMultiplePics: Bool? = false) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let takePic = UIAlertAction(title: "Caméra", style: .default, handler: { [weak self] (_) in
            guard let self = self else { return }
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                self.imagePickerController.sourceType = .camera
                checkCameraPermission { [weak self] in
                    self?.present(self!.imagePickerController, animated: true)
                }
            } else {
                showPopupMessage(title: "Erreur !", buttonTitle: "Compris !", description: "Votre appareil photo n'est pas pris en charge", image: #imageLiteral(resourceName: "ic_error_all_light_48pt")) {
                    SwiftEntryKit.dismiss()
                }
            }
        })
        takePic.setValue(UIImage.init(named: "camera-icon"), forKey: "image")
        
        let picLibrary = UIAlertAction(title: "Bibliothèque Photo", style: .default, handler: { [weak self] (_) in
            guard let self = self else { return }
            checkLibraryPermission { [weak self] in
                self?.imagePickerController.sourceType = .photoLibrary
                self?.present(self!.imagePickerController, animated: true)
            }
        })
        picLibrary.setValue(UIImage.init(named: "add"), forKey: "image")
        
        [takePic, picLibrary].forEach {
            $0.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            alertController.addAction($0)
        }
        
        alertController.addAction(UIAlertAction(title: "Annuler", style: .cancel))
        present(alertController, animated: true)
    }
    
    func getUserLocation(){
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .authorizedAlways, .authorizedWhenInUse:
                let latitude: CLLocationDegrees = (locationManager.location?.coordinate.latitude)!
                let longitude: CLLocationDegrees = (locationManager.location?.coordinate.longitude)!
                let location = CLLocation(latitude: latitude, longitude: longitude)
                CLGeocoder().reverseGeocodeLocation(location, completionHandler: { [weak self] (placemarks, error) -> Void in
                    if error != nil {
                        return
                    }else if let country = placemarks?.first?.country, let city = placemarks?.first?.locality {
                        self?.locationLabel.text = city + ", " + country
                    }
                })
                break
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
                break
            case .restricted, .denied:
                locationManager.requestWhenInUseAuthorization()
                break
            @unknown default:
                locationManager.requestWhenInUseAuthorization()
            }
        }
    }
}

extension MenuViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let image = (info[UIImagePickerController.InfoKey.originalImage] as? UIImage) else { return }
        let cropController = CropViewController(croppingStyle: .circular, image: image)
        cropController.delegate = self
        picker.pushViewController(cropController, animated: true)
    }
}

extension MenuViewController: CropViewControllerDelegate {
    public func cropViewController(_ cropViewController: CropViewController, didCropToCircularImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        updateImageViewWithImage(image, fromCropViewController: cropViewController)
    }
    
    func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
        cropViewController.dismiss(animated: true)
    }
    
    public func updateImageViewWithImage(_ image: UIImage, fromCropViewController cropViewController: CropViewController) {
        imageView.image = image
        cropViewController.dismiss(animated: true, completion: {
            let storageRef = Storage.storage().reference().child("profile_images").child("\(self.uid ?? "").jpg")
            uploadImageToFirebase(ref: storageRef, image: self.imageView.image!) { [weak self] (imageUrl) in
                let values = ["pictureURL": imageUrl]
                let usersReference = Database.database().reference().child("users").child((self?.uid!)!)
                
                usersReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
                    if err != nil {
                        print(err!)
                        return
                    }
                    SwiftEntryKit.dismiss()
                })
            }
        })
    }
}

extension MenuViewController: UITextViewDelegate {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        let values = ["description": textView.text!]
        ref.child("users").child(uid!).updateChildValues(values, withCompletionBlock: { (err, ref) in
            if err != nil {
                print(err ?? "")
                return
            }
        })
        
        if textView.text.isEmpty {
            textView.text = "Décrivez vous en moins de 120 caractères !"
            textView.font = UIFont.italicSystemFont(ofSize: 14)
        }
    }
    
    func updateCharacterCount() {
        let summaryCount = 120 - textView.text.count
        charactersCount.text = String(summaryCount)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        updateCharacterCount()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return textView.text.count +  (text.count - range.length) <= 120
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Décrivez vous en moins de 120 caractères !" {
            textView.font = UIFont(name: "ITCAvantGardePro-Bk", size: 14)
            textView.text = nil
        }
    }
}

extension MenuViewController: SettingsChangeDelegate {
    func didUpdateDetail() {
        delegate?.didUpdate()
    }
}
