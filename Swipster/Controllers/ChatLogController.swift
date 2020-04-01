//
//  ChatLogController.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 05/04/2018.
//  Copyright © 2018 Swipster Inc. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVFoundation
import Photos
import SwiftEntryKit
import CoreLocation

class ChatLogController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    
    var chatUser: User? {
        didSet {
            observeMessages()
        }
    }
    
    lazy var messages = [Message]()
    var my: User!
    lazy var profileImageView = UIImageView()
    let cellId = "cellId"
    let nameButton =  UIButton(type: .custom)
    lazy var imagePickerController = UIImagePickerController()
    var shouldManageSendButtonEnabledState = true
    let ref = Database.database().reference()
    lazy var profilImageLoader = UIActivityIndicatorView()
    
    deinit {
        print("OS Reclaiming memory for chat")
    }
    
    func getMyInfos(){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        ref.child("users").child(uid).observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard let dict = snapshot.value as? [String: Any] else { return }
            let user = User(dictionary: dict)
            self?.my = user
            self?.my.parentUID = uid
        }
    }
    
    @objc func handleNavBarTitleTouch(){
        let storyboard = UIStoryboard(name: "Profil", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "profil") as! ProfilViewController
        controller.user = chatUser
        controller.position = my.position
        if #available(iOS 13.0, *) {
            controller.modalPresentationStyle = .automatic
        }
        present(controller, animated: true)
    }
    
    var messageCounter = 0
    func observeMessages() {
        guard let uid = Auth.auth().currentUser?.uid, let toId = chatUser?.uid else { return }
        let userMessagesRef = ref.child("user-messages").child(uid).child(toId)
        userMessagesRef.observe(.childAdded, with: { [weak self] (snapshot) in
            let messagesRef = self?.ref.child("messages").child(snapshot.key)
            messagesRef!.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                guard let self = self else { return }
                guard let dictionary = snapshot.value as? [String: AnyObject] else { return }
                self.messages.append(Message(dictionary: dictionary))
                self.messages[self.messageCounter].messageId = snapshot.key
                DispatchQueue.main.async(execute: {
                    self.collectionView?.reloadData()
                    let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
                })
                self.messageCounter = self.messageCounter + 1
            })
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getMyInfos()
        
        textField.delegate = self
        configureImagePicker()
        configureCollectionView()
    }
    
    func configureImagePicker() {
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = ["public.image", "public.movie"]
    }
    
    func configureCollectionView() {
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 20, right: 0)
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = UIColor.white
        collectionView.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.keyboardDismissMode = .interactive
        collectionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(removeKeyboard)))
        setupKeyboardObservers()
        
        let button = UIButton(type: .custom)
        button.setImage(UIImage (named: "Report"), for: .normal)
        button.frame = CGRect(x: 0.0, y: 0.0, width: 29.5, height: 23.0)
        button.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        let barButtonItem = UIBarButtonItem(customView: button)
        navigationItem.rightBarButtonItem = barButtonItem
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        let width = UIScreen.main.bounds.width
        layout.sectionInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        layout.itemSize = CGSize(width: width / 2, height: width / 2)
        layout.minimumInteritemSpacing = 20
        layout.minimumLineSpacing = 20
        collectionView!.collectionViewLayout = layout
    }
    
    @objc func removeKeyboard(sender: UITapGestureRecognizer){
        textField.resignFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let font = UIFont(name: "Bellota-Regular", size: 22) {
            let fontAttributes = [NSAttributedString.Key.font: font]
            let myText = chatUser!.first_name as NSString
            let size = myText.size(withAttributes: fontAttributes)
            nameButton.frame = CGRect(x: 50, y: 0, width: size.width, height: 40)
            nameButton.titleLabel?.font = font
        }
        
        nameButton.setTitleColor(.white, for: .normal)
        nameButton.setTitle(chatUser?.first_name, for: .normal)
        nameButton.addTarget(self, action: #selector(handleNavBarTitleTouch), for: .touchUpInside)

        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        profileImageView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        
        profilImageLoader.startAnimating()
        profilImageLoader.frame = profileImageView.bounds
        profilImageLoader.color = .white
        profilImageLoader.hidesWhenStopped = true
        profileImageView.addSubview(profilImageLoader)
        ImageService.getImage(withURL: URL(string: chatUser!.pictureURL)) { [weak self] (image) in
            self?.profilImageLoader.stopAnimating()
            self?.profileImageView.image = image
        }
        profileImageView.isUserInteractionEnabled = true
        let gestureRecognizerOne = UITapGestureRecognizer(target: self, action: #selector(handleNavBarTitleTouch))
        profileImageView.addGestureRecognizer(gestureRecognizerOne)

        let navView = UIView(frame: CGRect(x: 0, y: 0, width: nameButton.frame.width + profileImageView.frame.width + 10, height: 60))
        navView.addSubview(profileImageView)
        navView.addSubview(nameButton)
        navigationItem.titleView = navView
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        nameButton.removeFromSuperview()
        profileImageView.removeFromSuperview()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if #available(iOS 13.0, *) {
            profilImageLoader.style = .medium
            if traitCollection.userInterfaceStyle == .dark {
                collectionView.backgroundColor = .secondarySystemBackground
                customInputView.backgroundColor = .secondarySystemBackground
                textField.backgroundColor = .quaternarySystemFill
            } else {
                customInputView.backgroundColor = .white
                textField.backgroundColor = UIColor(rgb: 0xEFEFF4)
                collectionView.backgroundColor = .systemBackground
            }
        } else {
            profilImageLoader.style = .white
        }
    }
    
    @objc func addTapped() {
        let alertController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Signaler " + (chatUser?.first_name)!, style: .destructive, handler: { [weak self] (_) in
            guard let self = self else { return }
            report(user: self.chatUser!, fromUID: self.my.parentUID!, fromName: self.my.first_name, isMatch: true, completion: {})
        }))
        alertController.addAction(UIAlertAction(title: "Annuler", style: .cancel))
        present(alertController, animated: true)
    }
    
    var customInputView: UIView!
    var sendButton, addMediaButtom: UIButton!
    let textField = FlexibleTextView()
    
    override var inputAccessoryView: UIView? {
        
        if customInputView == nil {
            customInputView = CustomView()
            customInputView.layer.shadowColor = UIColor.lightGray.cgColor
            customInputView.layer.shadowOpacity = 1
            customInputView.layer.shadowOffset = .zero
            customInputView.layer.shadowRadius = 1
            customInputView.backgroundColor = .white
            customInputView.autoresizingMask = .flexibleHeight
            
            textField.placeholder = "Rédigez un message..."
            textField.font = .systemFont(ofSize: 15)
            textField.backgroundColor = UIColor(rgb: 0xEFEFF4)
            textField.tintColor = .purple
            textField.textColor = .black
            textField.maxHeight = 80
            if #available(iOS 13.0, *) {
                textField.textColor = .label
            } else {
                textField.textColor = .black
            }
            customInputView.addSubview(textField)
            
            sendButton = UIButton(type: .system)
            sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            sendButton.setTitle("Envoyer", for: .normal)
            sendButton.tintColor = .purple
            sendButton.isEnabled = false
            sendButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
            sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
            customInputView.addSubview(sendButton)
            
            addMediaButtom = UIButton(type: .system)
            addMediaButtom.tintColor = .purple
            addMediaButtom.setImage(UIImage(imageLiteralResourceName: "camera-filled-icon").withRenderingMode(.alwaysTemplate), for: .normal)
            addMediaButtom.contentEdgeInsets = UIEdgeInsets(top: 9, left: 0, bottom: 5, right: 0)
            addMediaButtom.addTarget(self, action: #selector(handleUploadTap), for: .touchUpInside)
            customInputView.addSubview(addMediaButtom)
            
            textField.translatesAutoresizingMaskIntoConstraints = false
            
            for button in [sendButton, addMediaButtom] {
                button!.translatesAutoresizingMaskIntoConstraints = false
                button!.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: NSLayoutConstraint.Axis.horizontal)
                button!.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: NSLayoutConstraint.Axis.horizontal)
            }
            
            addMediaButtom.leadingAnchor.constraint(equalTo: customInputView.leadingAnchor, constant: 8).isActive = true
            addMediaButtom.trailingAnchor.constraint(equalTo: textField.leadingAnchor,constant: -8).isActive = true
            addMediaButtom.bottomAnchor.constraint(equalTo: customInputView.layoutMarginsGuide.bottomAnchor, constant: -5).isActive = true
            
            textField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8).isActive = true
            textField.topAnchor.constraint(equalTo: customInputView.topAnchor, constant: 8).isActive = true
            textField.bottomAnchor.constraint(equalTo: customInputView.layoutMarginsGuide.bottomAnchor, constant: -8).isActive = true
            
            sendButton.leadingAnchor.constraint(equalTo: textField.trailingAnchor).isActive = true
            sendButton.trailingAnchor.constraint(equalTo: customInputView.trailingAnchor, constant: -8).isActive = true
            sendButton.bottomAnchor.constraint(equalTo: customInputView.layoutMarginsGuide.bottomAnchor, constant: -8).isActive = true
        }
        return customInputView
    }
    
    @objc func handleUploadTap() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let takePic = UIAlertAction(title: "Caméra", style: .default, handler: { [weak self] (_) in
            guard let self = self else { return }
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                self.imagePickerController.sourceType = .camera
                self.imagePickerController.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
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
        
        let picLibraby = UIAlertAction(title: "Bibliothèque Photo et Vidéo", style: .default, handler: { [weak self] (_) in
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
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            handleVideoSelectedForUrl(videoUrl)
        } else {
            handleImageSelectedForInfo(info as [UIImagePickerController.InfoKey : AnyObject])
        }
        showLoadingView(text: "Envoi en cours...")
        dismiss(animated: true)
    }
    
    @objc fileprivate func handleVideoSelectedForUrl(_ url: URL) {
        let fileName = UUID().uuidString + ".mov"
        let ref = Storage.storage().reference().child("message_movies").child(fileName)
        let uploadTask = ref.putFile(from: url, metadata: nil, completion: { (metadata, error) in
            
            if error != nil {
                showPopupMessage(title: "Erreur !", buttonTitle: "Compris !", description: "Veuillez réessayer ultérieurement !", image: #imageLiteral(resourceName: "ic_error_all_light_48pt")) {
                    SwiftEntryKit.dismiss()
                }
                return
            }
            
            ref.downloadURL(completion: { [weak self] (url, error) in
                if error == nil {
                    if let downloadUrl = url {
                        let videoUrl = downloadUrl.absoluteString
                        if let thumbnailImage = self?.thumbnailImageForFileUrl(url!) {
                            let imageName = "\(UUID().uuidString).jpg"
                            let storageRef = Storage.storage().reference().child("message_images").child(imageName)
                            uploadImageToFirebase(ref: storageRef, image: thumbnailImage, completion: { [weak self] (imageUrl) in
                                let properties: [String: AnyObject] = ["imageUrl": imageUrl as AnyObject, "imageWidth": thumbnailImage.size.width as AnyObject, "imageHeight": thumbnailImage.size.height as AnyObject, "videoUrl": videoUrl as AnyObject]
                                self?.sendMessageWithProperties(properties)
                            })
                        }
                    }
                } else {
                    showPopupMessage(title: "Erreur !", buttonTitle: "Compris !", description: "Veuillez réessayer ultérieurement !", image: #imageLiteral(resourceName: "ic_error_all_light_48pt")) {
                        SwiftEntryKit.dismiss()
                    }
                }
            })
        })
        
        uploadTask.observe(.progress) { [weak self] (snapshot) in
            if let completedUnitCount = snapshot.progress?.completedUnitCount {
                self?.navigationItem.title = String(completedUnitCount)
            }
        }
        
        uploadTask.observe(.success) { [weak self] (snapshot) in
            self?.navigationItem.title = self?.chatUser?.first_name
        }
    }
    
    fileprivate func thumbnailImageForFileUrl(_ fileUrl: URL) -> UIImage? {
        let asset = AVAsset(url: fileUrl)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
            let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60), actualTime: nil)
            return UIImage(cgImage: thumbnailCGImage)
            
        } catch {
            showPopupMessage(title: "Erreur !", buttonTitle: "Compris !", description: "Veuillez réessayer ultérieurement !", image: #imageLiteral(resourceName: "ic_error_all_light_48pt")) {
                SwiftEntryKit.dismiss()
            }
        }
        
        return nil
    }
    
    @objc fileprivate func handleImageSelectedForInfo(_ info: [UIImagePickerController.InfoKey: AnyObject]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info[UIImagePickerController.InfoKey.cropRect] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            let imageName = "\(UUID().uuidString).jpg"
            let storageRef = Storage.storage().reference().child("message_images").child(imageName)
            uploadImageToFirebase(ref: storageRef, image: selectedImage, completion: { [weak self] (imageUrl) in
                self?.sendMessageWithImageUrl(imageUrl, image: selectedImage)
            })
        }
    }
    
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
    }
    
    @objc func handleKeyboardDidShow() {
        if messages.count > 0 {
            let indexPath = IndexPath(item: messages.count - 1, section: 0)
            collectionView?.scrollToItem(at: indexPath, at: .top, animated: true)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleKeyboardWillShow(_ notification: Notification) {
        let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        let keyboardDuration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        
        containerViewBottomAnchor?.constant = -keyboardFrame!.height
        UIView.animate(withDuration: keyboardDuration!, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    @objc func handleKeyboardWillHide(_ notification: Notification) {
        let keyboardDuration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        
        containerViewBottomAnchor?.constant = 0
        UIView.animate(withDuration: keyboardDuration!, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        cell.chatLogController = self
        let message = messages[indexPath.item]
        cell.message = message
        cell.textView.text = message.text
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        lpgr.delegate = self
        lpgr.minimumPressDuration = 0.3
        lpgr.delaysTouchesBegan = true
        cell.bubbleView.addGestureRecognizer(lpgr)
        
        let timestampDate = Date(timeIntervalSince1970: Double(message.timestamp!))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let time = dateFormatter.string(from: timestampDate)
        
        cell.timeLabel.text = time
        
        setupCell(cell, message: message)
        
        if let text = message.text {
            //a text message
            cell.bubbleWidthAnchor?.constant = estimateFrameForText(text).width + 32
            cell.textView.isHidden = false
        } else if message.imageUrl != nil {
            //fall in here if its an image message
            cell.bubbleWidthAnchor?.constant = 200
            cell.textView.isHidden = true
        }
        
        cell.playButton.isHidden = message.videoUrl == nil
        
        return cell
    }

    var cellText = ""
    var messageId = ""
    var indexPath = IndexPath()
    @objc func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state == UIGestureRecognizer.State.began {
            let point = gestureReconizer.location(in: collectionView)
            indexPath = collectionView.indexPathForItem(at: point)!
            let cell: ChatMessageCell? = collectionView.cellForItem(at: indexPath) as! ChatMessageCell?
            cellText = cell?.textView.text ?? ""
            messageId = cell?.message?.messageId ?? "not found"
            let menu = UIMenuController.shared
            menu.menuItems?.removeAll()
            let copyButton = UIMenuItem(title: "Copier", action: #selector(self.copyText))
            let deleteButton = UIMenuItem(title: "Supprimer", action: #selector(self.deleteSingleMessage))
            menu.menuItems = [copyButton, deleteButton]
            menu.update()
            let centerInBubble = (cell?.bubbleView.frame.width)! / 2
            menu.setTargetRect(CGRect(x: centerInBubble - 10, y: 3, width: 20, height: 20), in: cell?.bubbleView ?? UIView())
            menu.setMenuVisible(true, animated: true)
        }
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(deleteSingleMessage) || action == #selector(copyText) {
            return true
        }
        return false
    }
    
    @objc func copyText(){
        UIPasteboard.general.string = cellText
    }
    
    @objc func deleteSingleMessage(){
        if indexPath.item != 0 {
            
            let url = [messages[indexPath.item].imageUrl, messages[indexPath.item].videoUrl]
            for url in url {
                if let url = url {
                    let storageRef = Storage.storage().reference(forURL: url)
                    storageRef.delete { error in
                        if let error = error {
                            print(error)
                            return
                        }
                    }
                }
            }
            
            ref.child("user-messages").child(chatUser!.parentUID!).child(my.parentUID!).child(messageId).setValue(nil)
            ref.child("user-messages").child(my.parentUID!).child(chatUser!.parentUID!).child(messageId).setValue(nil)
            ref.child("messages").child(messageId).removeValue(completionBlock: { [weak self] error, ref  in
                guard let self = self else { return }
                if error != nil {
                    print(error ?? "")
                    return
                }
                self.messageCounter = self.messageCounter - 1
                self.messages.remove(at: self.indexPath.item)
                self.collectionView.deleteItems(at: [self.indexPath])
                self.collectionView.reloadData()
            })
            
        } else {
            showPopupMessage(title: "Impossible", buttonTitle: "Compris !", description: "Pour supprimer le premier message, supprimez votre match !", image: #imageLiteral(resourceName: "ic_error_all_light_48pt")) {
                SwiftEntryKit.dismiss()
            }
        }
    }
    
    fileprivate func setupCell(_ cell: ChatMessageCell, message: Message) {
        if let profileImageUrl = chatUser?.pictureURL {
            ImageService.getImage(withURL: URL(string: profileImageUrl)) { (image) in
                cell.profilActivityIndicatorView.stopAnimating()
                cell.profileImageView.image = image
            }
        }
        
        if message.fromId == Auth.auth().currentUser?.uid {
            cell.bubbleView.backgroundColor = UIColor(rgb: 0x961872).withAlphaComponent(0.7)
            cell.profileImageView.isHidden = true
            cell.textView.textColor = .white
            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false
            cell.timeLabelRightAnchor?.isActive = true
            cell.timeLabelLeftAnchor?.isActive = false
            
        } else {
            if #available(iOS 13.0, *) {
                if traitCollection.userInterfaceStyle == .dark {
                    cell.bubbleView.backgroundColor = .quaternarySystemFill
                    cell.textView.textColor = .white
                } else {
                    cell.bubbleView.backgroundColor = UIColor(rgb: 0xF0F0F0)
                    cell.textView.textColor = .black
                }
            } else {
                cell.bubbleView.backgroundColor = UIColor(rgb: 0xF0F0F0)
            }
            cell.profileImageView.isHidden = false
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
            cell.timeLabelRightAnchor?.isActive = false
            cell.timeLabelLeftAnchor?.isActive = true
        }
        
        if let messageImageUrl = message.imageUrl {
            ImageService.getImage(withURL: URL(string: messageImageUrl)) { (image) in
                cell.messageImageView.image = image
                cell.activityIndicatorView.stopAnimating()
            }
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = UIColor.clear
        } else {
            cell.activityIndicatorView.stopAnimating()
            cell.messageImageView.isHidden = true
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var height: CGFloat = 80
        
        let message = messages[indexPath.item]
        if let text = message.text {
            height = estimateFrameForText(text).height + 20
        } else if let imageWidth = message.imageWidth, let imageHeight = message.imageHeight {
            // h1 / w1 = h2 / w2
            // solve for h1
            // h1 = h2 / w2 * w1
            
            height = CGFloat(imageHeight / imageWidth * 200)
            
        }
        
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: height)
    }
    
    fileprivate func estimateFrameForText(_ text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [kCTFontAttributeName as NSAttributedString.Key: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    var containerViewBottomAnchor: NSLayoutConstraint?
    
    @objc func handleSend() {
        if textField.text != "" {
            let properties = ["text": textField.text!]
            sendMessageWithProperties(properties as [String : AnyObject])
            sendButton.isEnabled = false
        }
    }
    
    fileprivate func sendMessageWithImageUrl(_ imageUrl: String, image: UIImage) {
        let properties: [String: AnyObject] = ["imageUrl": imageUrl as AnyObject, "imageWidth": image.size.width as AnyObject, "imageHeight": image.size.height as AnyObject]
        sendMessageWithProperties(properties)
    }
    
    fileprivate func sendMessageWithProperties(_ properties: [String: AnyObject]) {
        textField.text = nil
        let childRef = ref.child("messages").childByAutoId()
        let toId = chatUser!.uid
        let fromId = Auth.auth().currentUser!.uid
        let timestamp = Int(Date().timeIntervalSince1970)
        
        var values: [String: AnyObject] = ["toId": toId as AnyObject, "fromId": fromId as AnyObject, "timestamp": timestamp as AnyObject]
        
        properties.forEach({values[$0] = $1})
        
        childRef.updateChildValues(values) { (error, ref) in
            if error != nil {
                showPopupMessage(title: "Erreur !", buttonTitle: "Compris !", description: "Veuillez réessayer ultérieurement !", image: #imageLiteral(resourceName: "ic_error_all_light_48pt")) {
                    SwiftEntryKit.dismiss()
                }
                return
            }
            
            let userMessagesRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
            
            let messageId = childRef.key
            userMessagesRef.updateChildValues([messageId!: 1])
            
            let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toId).child(fromId)
            recipientUserMessagesRef.updateChildValues([messageId!: 1])
            SwiftEntryKit.dismiss(.all)
        }
        
        var bodyText: String?
        if properties["text"] != nil {
            bodyText = properties["text"] as? String
        } else if properties["videoUrl"] != nil{
            bodyText = "📹 Vidéo"
        } else {
            bodyText = "📷 Photo"
        }
  
        let notifMessage: [String: Any] = [
            "to" : chatUser!.fcmToken,
            "notification" :
                ["title" : my.first_name + " vous a envoyé un message", "body" : bodyText as Any, "badge" : 1, "sound" : "default", "pictureURL" : my.pictureURL, "uid" : my.parentUID!]
        ]
        
        sendPushNotification(notData: notifMessage)
    }
    
    var startingFrame: CGRect?
    var blackBackgroundView: UIView?
    var startingImageView: UIImageView?
    var zoomingImageView: UIImageView!
    
    func performZoomInForStartingImageView(_ startingImageView: UIImageView) {
        
        textField.resignFirstResponder()
        self.startingImageView = startingImageView
        startingImageView.isHidden = true
        
        startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
        
        zoomingImageView = UIImageView(frame: startingFrame!)
        zoomingImageView.backgroundColor = UIColor.red
        zoomingImageView.image = startingImageView.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.contentMode = .scaleAspectFill
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(zoomOutFromBlur)))
        
        if let keyWindow = UIApplication.shared.keyWindow {
            blackBackgroundView = UIView(frame: keyWindow.frame)
            blackBackgroundView?.backgroundColor = UIColor.white.withAlphaComponent(0.2)
            let blurEffect: UIBlurEffect?
            if #available(iOS 13.0, *) {
                blurEffect = UIBlurEffect(style: .systemThinMaterial)
            } else {
                blurEffect = UIBlurEffect(style: .light)
            }
            let blurEffectView = UIVisualEffectView()
            blurEffectView.frame = blackBackgroundView!.bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            blackBackgroundView?.addSubview(blurEffectView)
            blackBackgroundView?.isUserInteractionEnabled = true
            blackBackgroundView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(zoomOutFromBlur)))
            keyWindow.addSubview(blackBackgroundView!)
            
            keyWindow.addSubview(zoomingImageView)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                blurEffectView.effect = blurEffect
                self.blackBackgroundView?.alpha = 1
                self.inputAccessoryView?.alpha = 0
                
                // math?
                // h2 / w1 = h1 / w1
                // h2 = h1 / w1 * w1
                let height = self.startingFrame!.height / self.startingFrame!.width * keyWindow.frame.width
                
                self.zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                self.zoomingImageView.center = keyWindow.center
                
            }, completion: { [weak self] (completed) in
                guard let self = self else { return }
                let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchGesture))
                self.zoomingImageView.addGestureRecognizer(pinchGesture)
                let pan = UIPanGestureRecognizer(target: self, action: #selector(self.pan(sender:)))
                pan.delegate = self
                self.zoomingImageView.addGestureRecognizer(pan)
                
            })
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    var isZooming = false
    @objc func pinchGesture(sender: UIPinchGestureRecognizer){
        if sender.state == .began {
            let currentScale = zoomingImageView.frame.size.width / zoomingImageView.bounds.size.width
            let newScale = currentScale*sender.scale
            if newScale > 1 {
                isZooming = true
            }
        } else if sender.state == .changed {
            guard let view = sender.view else { return }
            let pinchCenter = CGPoint(x: sender.location(in: view).x - view.bounds.midX,
                                      y: sender.location(in: view).y - view.bounds.midY)
            let transform = view.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y)
                .scaledBy(x: sender.scale, y: sender.scale)
                .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
            let currentScale = zoomingImageView.frame.size.width / zoomingImageView.bounds.size.width
            var newScale = currentScale*sender.scale
            if newScale < 1 {
                newScale = 1
                let transform = CGAffineTransform(scaleX: newScale, y: newScale)
                zoomingImageView.transform = transform
                sender.scale = 1
            } else if newScale > 3 {
                newScale = 3
            }
            else {
                view.transform = transform
                sender.scale = 1
            }
        } else if sender.state == .ended || sender.state == .failed || sender.state == .cancelled {
            guard let center = self.originalImageCenter else { return }
            UIView.animate(withDuration: 0.3, animations: {
                self.zoomingImageView.transform = CGAffineTransform.identity
                self.zoomingImageView.center = center
            }, completion: { [weak self] _ in
                self?.isZooming = false
            })
        }

    }
    
    var originalImageCenter:CGPoint?
    @objc func pan(sender: UIPanGestureRecognizer) {
        if isZooming && sender.state == .began {
            originalImageCenter = sender.view?.center
        } else if isZooming && sender.state == .changed {
            let translation = sender.translation(in: view)
            if let view = sender.view {
                view.center = CGPoint(x:view.center.x + translation.x, y:view.center.y + translation.y)
            }
            sender.setTranslation(CGPoint.zero, in: zoomingImageView.superview)
        }
    }

    @objc func zoomOutFromBlur(){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            guard let originalRadius = self.startingImageView?.layer.cornerRadius else { return }
            guard let originalBorderColor = self.startingImageView?.layer.borderColor else { return }
            guard let originalBorderWidth = self.startingImageView?.layer.borderWidth else { return }
            self.zoomingImageView.layer.cornerRadius = originalRadius
            self.zoomingImageView.clipsToBounds = true
            self.zoomingImageView.layer.borderColor = originalBorderColor
            self.zoomingImageView.layer.borderWidth = originalBorderWidth
            self.zoomingImageView.frame = self.startingFrame!
            self.blackBackgroundView?.alpha = 0
            self.inputAccessoryView?.alpha = 1
            
        }, completion: { [weak self] (completed) in
            self?.zoomingImageView.removeFromSuperview()
            self?.startingImageView?.isHidden = false
            self?.blackBackgroundView?.removeFromSuperview()
        })
    }
}

class CustomView: UIView {
    
    override var intrinsicContentSize: CGSize {
        return CGSize.zero
    }
}

extension ChatLogController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        let trimmedText = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if shouldManageSendButtonEnabledState {
            let isEnabled = !trimmedText.isEmpty
            sendButton.isEnabled = isEnabled
        }
    }
}
