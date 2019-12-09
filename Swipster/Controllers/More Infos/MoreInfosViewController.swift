//
//  MoreInfosViewController.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 20/11/2019.
//  Copyright © 2019 Daniel Ghrenassia. All rights reserved.
//

import UIKit
import AuthenticationServices
import MXSegmentedControl
import MobileCoreServices
import CropViewController
import SwiftEntryKit
import Firebase

class MoreInfosViewController: UIViewController {

    @IBOutlet weak var nameTitle: UILabel!
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var textView: UITextView!
    @IBOutlet private weak var imageViewSelector: UIImageView!
    @IBOutlet private weak var changeImageButton: UIButton!
    @IBOutlet private weak var datePickerTextField: SwipsterTextField!
    let datePicker = UIDatePicker()
    @IBOutlet private weak var changeGenderView: MXSegmentedControl!
    @IBOutlet private weak var loginButton: UIButton!
    let imagePickerController = UIImagePickerController()
    var sexe = "male"
    var email, first_name, ageUser: String?
    
    @IBAction func selectProfilPic(_ sender: UIButton) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.pruneNegativeWidthConstraints()
        
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
        
        let picLibraby = UIAlertAction(title: "Bibliothèque Photo", style: .default, handler: { [weak self] (_) in
            guard let self = self else { return }
            checkLibraryPermission { [weak self] in
                self?.imagePickerController.sourceType = .photoLibrary
                self?.present(self!.imagePickerController, animated: true)
            }
        })
        picLibraby.setValue(UIImage.init(named: "add"), forKey: "image")
        
        [takePic, picLibraby].forEach {
            $0.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            alertController.addAction($0)
        }
        
        alertController.addAction(UIAlertAction(title: "Annuler", style: .cancel))
        present(alertController, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        showDatePicker()
        configureSegmentedControl()
        configureImagePickerController()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(cancelDatePicker))
        view.addGestureRecognizer(tapGestureRecognizer)
        
        backButton.addTarget(self, action: #selector(dimissVC), for: .touchUpInside)
    }
    
    @objc func dimissVC() {
        dismiss(animated: true)
    }
    
    func configureImagePickerController() {
        imagePickerController.delegate = self
        imagePickerController.navigationBar.isTranslucent = false
        imagePickerController.navigationBar.barTintColor = .purple
        imagePickerController.navigationBar.tintColor = .white
        imagePickerController.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name: "Bellota-Regular", size: 25)!]
        imagePickerController.mediaTypes = ["public.image"]
    }
    
    func configureImagePicker() {
        imageViewSelector.layer.borderColor = UIColor(rgb: 0x961872).cgColor
        imageViewSelector.layer.cornerRadius = imageViewSelector.frame.width / 2
        changeImageButton.layer.cornerRadius = changeImageButton.frame.width / 2
        imageViewSelector.layer.borderWidth = 3
    }
    
    override func viewWillLayoutSubviews() {
        
        if let name = first_name {
            nameTitle.text = "Hello \(name) !"
        }
        configureImagePicker()
        configureDateTextField()
        
        if #available(iOS 13.0, *) {
            backButton.tintColor = .label
        } else {
            backButton.tintColor = .black
        }
        textView.textContainerInset = UIEdgeInsets.zero
        textView.textContainer.lineFragmentPadding = 0
        loginButton.layer.cornerRadius = loginButton.frame.height / 2
    }
    
    func configureDateTextField() {
        datePickerTextField.tintColor = .clear
        datePickerTextField.clipsToBounds = true
        datePickerTextField.layer.borderWidth = 1
        datePickerTextField.layer.cornerRadius = datePickerTextField.frame.height / 2
        if #available(iOS 13.0, *) {
            datePickerTextField.layer.borderColor = UIColor.label.cgColor
        } else {
            datePickerTextField.layer.borderColor = UIColor.black.cgColor
        }
    }
    
    func showDatePicker() {

        datePicker.datePickerMode = .date
        datePicker.locale = Locale.init(identifier: "fr-FR")
        datePicker.translatesAutoresizingMaskIntoConstraints = false

        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 35))
        toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Annuler", style: .plain, target: self, action: #selector(cancelDatePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "OK", style: .plain, target: self, action: #selector(doneDatePicker))

        toolBar.setItems([doneButton,spaceButton,cancelButton], animated: false)

        datePickerTextField.inputAccessoryView = toolBar
        datePickerTextField.inputView = datePicker
        
    }
    
    @objc func doneDatePicker(){
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        let age = formatter.string(from: datePicker.date)
        ageUser = age
        if calcAge(birthday: age) >= 18 {
            view.endEditing(true)
            let dateFormatter = DateFormatter()
            formatter.dateFormat = "d MMMM YYYY"
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .none
            dateFormatter.locale = Locale(identifier: "fr_FR")
            datePickerTextField.text = dateFormatter.string(from: datePicker.date)
        } else {
            let alert = UIAlertController(title: "Vous n'êtes pas majeure !", message: "Swipster n'est disponible que pour les personnes ayant plus de 18 ans actuellement.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alert, animated: true)
        }
    }
    
    @objc func cancelDatePicker(){
        view.endEditing(true)
    }
    
    func configureSegmentedControl() {
        changeGenderView.append(title: "Un homme")
        changeGenderView.append(title: "Une femme")
        changeGenderView.font = UIFont(name: "ITCAvantGardePro-Bk", size: 17)!
        changeGenderView.selectedTextColor = UIColor.purple
        changeGenderView.indicator.lineView.backgroundColor = UIColor.purple
        changeGenderView.addTarget(self, action: #selector(changeIndex(segmentedControl:)), for: .valueChanged)
    }
    
    @objc func changeIndex(segmentedControl: MXSegmentedControl) {
        if #available(iOS 10.0, *) {
            let impact = UIImpactFeedbackGenerator()
            impact.impactOccurred()
        }
        switch segmentedControl.selectedIndex {
        case 0:
            sexe = "male"
        case 1:
            sexe = "female"
        default:
            break
        }
    }
    
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        if imageViewSelector.image != nil {
            if !datePickerTextField.text!.isEmpty {
                guard let image = imageViewSelector.image else { return }
                guard let uid = Auth.auth().currentUser?.uid else { return }
                let storageRef = Storage.storage().reference().child("profile_images").child("\(uid).jpg")
                uploadImageToFirebase(ref: storageRef, image: image) { [weak self] (imageUrl) in
                    let lookingFor = self?.sexe == "male" ? "female" : "male"
                    let values = ["first_name": self?.first_name, "birthday": self?.ageUser, "email": self?.email, "gender": self?.sexe, "pictureURL": imageUrl, "lookingFor": lookingFor, "lookingDistance": "26", "minAge":"18", "maxAge":"26", "public": "true"]
                    createUser(uid: uid, values: values as [String : AnyObject], completion: { [weak self] in
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "swipe")
                        vc.modalPresentationStyle = .fullScreen
                        self?.present(vc, animated: true, completion: {
                            SwiftEntryKit.dismiss()
                        })
                    })
                }
            } else {
                let alert = UIAlertController(title: "Erreur !", message: "Veuillez selectionner votre date de naissance !", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                present(alert, animated: true)
            }
        } else {
            let alert = UIAlertController(title: "Erreur !", message: "Veuillez selectionner votre photo de profil !", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alert, animated: true)
        }
    }
    
}

extension MoreInfosViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let image = (info[UIImagePickerController.InfoKey.originalImage] as? UIImage) else { return }
        let cropController = CropViewController(croppingStyle: .circular, image: image)
        cropController.delegate = self
        if picker.sourceType == .camera {
            picker.dismiss(animated: true, completion: {
                self.present(cropController, animated: true, completion: nil)
            })
        } else {
            picker.pushViewController(cropController, animated: true)
        }
    }
}

extension MoreInfosViewController: CropViewControllerDelegate {
    public func cropViewController(_ cropViewController: CropViewController, didCropToCircularImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        updateImageViewWithImage(image, fromCropViewController: cropViewController)
    }
    
    public func updateImageViewWithImage(_ image: UIImage, fromCropViewController cropViewController: CropViewController) {
        imageViewSelector.image = image
        cropViewController.dismiss(animated: true, completion: nil)
    }
}

