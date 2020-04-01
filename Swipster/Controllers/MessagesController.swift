//
//  ChatViewController.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 22/03/2018.
//  Copyright © 2018 Swipster Inc. All rights reserved.
//

import UIKit
import Firebase
import SwiftEntryKit

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}

class MessagesController: UITableViewController {
    
    let cellId = "cellId"
    var timer: Timer?
    lazy var messages = [Message]()
    lazy var messagesDictionary = [String: Message]()
    var fetchingMore = false
    var lastFetchUserId: String?
    
    @IBAction func menuBtn(_ sender: Any) {
        customDismiss()
    }
    
    func customDismiss() {
        let transition: CATransition = CATransition()
        transition.duration = 0.25
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.type = CATransitionType.moveIn
        transition.subtype = CATransitionSubtype.fromLeft
        view.window!.layer.add(transition, forKey: nil)
        dismiss(animated: false, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchUserMessages()
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        tableView.tableFooterView = UIView()
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeRight.direction = UISwipeGestureRecognizer.Direction.right
        view.addGestureRecognizer(swipeRight)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                tableView.backgroundColor = .secondarySystemBackground
                tableView.tableHeaderView?.backgroundColor = .secondarySystemBackground
            } else {
                tableView.backgroundColor = .systemBackground
                tableView.tableHeaderView?.backgroundColor = .systemBackground
            }
        }
    }
    
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        customDismiss()
    }
    
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Supprimer le match"
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        alertViewPerformForDelete(indexPath: indexPath)
    }
    
    // above iOS 11 delete row
    @available(iOS 11.0, *)
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Supprimer") { [weak self] (action, view, completionHandler) in
            self?.alertViewPerformForDelete(indexPath: indexPath)
            completionHandler(false)
        }
        delete.backgroundColor = #colorLiteral(red: 1, green: 0.3241998255, blue: 0.3247863948, alpha: 1)
        delete.image = #imageLiteral(resourceName: "ic_error_all_light_48pt")
        
        let config = UISwipeActionsConfiguration(actions: [delete])
        return config
    }
    
    func alertViewPerformForDelete(indexPath: IndexPath){
        showCenterAlertView(title: "Supprimer l'affinité", message: "Vous ne pourrez plus vous envoyer de messages..", okButton: "OUI", cancelButton: "NON") {
            SwiftEntryKit.dismiss()
            showLoadingView(text: "Suppression du match...")
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let message = self.messages[indexPath.row]
            if let chatPartnerId = message.chatPartnerId() {
                self.deleteMessage(chatPartnerId: chatPartnerId, completion: {
                    Database.database().reference().child("user-messages").child(uid).child(chatPartnerId).removeValue(completionBlock: { [weak self] (error, ref) in
                        
                        if error != nil {
                            print("Failed to delete message:", error!)
                            return
                        }
                        
                        self?.messagesDictionary.removeValue(forKey: chatPartnerId)
                        self?.attemptReloadOfTable()
                        
                    })
                    Database.database().reference().child("user-messages").child(chatPartnerId).child(uid).removeValue(completionBlock: { [weak self] (error, ref) in
                        
                        if error != nil {
                            print("Failed to delete message:", error!)
                            return
                        }
                        
                        self?.messagesDictionary.removeValue(forKey: chatPartnerId)
                        self?.attemptReloadOfTable()
                        SwiftEntryKit.dismiss(.all)
                    })
                })
            }
        }
    }
    
    func deleteMessage(chatPartnerId: String, completion: @escaping () -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let messagesReference = Database.database().reference().child("messages")
        Database.database().reference().child("user-messages").child(uid).child(chatPartnerId).observe(.value, with: { (snapshot) in
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                messagesReference.child(child.key).observeSingleEvent(of: .value) { (snapshot) in
                    guard let dict = snapshot.value as? [String: Any] else { return }
                    let message = Message(dictionary: dict)
                    let url = [message.imageUrl, message.videoUrl]
                    for url in url {
                        if let url = url {
                            let storageRef = Storage.storage().reference(forURL: url)
                            storageRef.delete { error in
                                if let error = error {
                                    print(error)
                                    return
                                }
                                messagesReference.child(child.key).removeValue(completionBlock: { (error, ref) in
                                    if error != nil {
                                        print("Failed to delete message:", error!)
                                        return
                                    }
                                })

                            }
                        } else {
                            messagesReference.child(child.key).removeValue(completionBlock: { (error, ref) in
                                if error != nil {
                                    print("Failed to delete message:", error!)
                                    return
                                }
                            })
                        }
                    }
                }
            }
            completion()
        })
    }
    
    func EmptyMessage(title: String, message:String, viewController:UITableViewController) {
        let emptyCell = EmptyCell()
        emptyCell.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        emptyCell.titleLabel.text = title
        emptyCell.messageLabel.text = message
        tableView.backgroundView = emptyCell
    }
    
    func fetchUserMessages() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("user-messages").child(uid)
        
        let queryRef: DatabaseQuery
        
        queryRef = messages.last == nil ? ref.queryLimited(toFirst: 15) : ref.queryOrderedByKey().queryStarting(atValue: lastFetchUserId).queryLimited(toFirst: 15)
        
        queryRef.observe(.childAdded, with: { [weak self] (snapshot) in
            guard let self = self else { return }
            self.tableView.backgroundView = nil
            let userId = snapshot.key
            self.lastFetchUserId = userId
            Database.database().reference().child("user-messages").child(uid).child(userId).queryLimited(toLast: 1).observe(.childAdded, with: { [weak self] (snapshot) in
                let messageId = snapshot.key
                if snapshot.key != self?.lastFetchUserId {
                    self?.fetchMessageWithMessageId(messageId)
                }
            })
            self.fetchingMore = false
        })
        
        ref.observe(.childRemoved, with: { [weak self] (snapshot) in
            self?.messagesDictionary.removeValue(forKey: snapshot.key)
            self?.attemptReloadOfTable()
        })
    }
    
    fileprivate func fetchMessageWithMessageId(_ messageId: String) {
        let messagesReference = Database.database().reference().child("messages").child(messageId)
        messagesReference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let message = Message(dictionary: dictionary)
                if let chatPartnerId = message.chatPartnerId() {
                    self?.messagesDictionary[chatPartnerId] = message
                }
                self?.attemptReloadOfTable()
            }
        })
    }
    
    fileprivate func attemptReloadOfTable() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(handleReloadTable), userInfo: nil, repeats: false)
    }
    
    @objc func handleReloadTable() {
        messages = Array(messagesDictionary.values)
        messages.sort(by: { (message1, message2) -> Bool in
            return message1.timestamp > message2.timestamp
        })

        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
        })
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if messages.count == 0 {
            EmptyMessage(title: "DOMMAGE", message: "Vous n'avez encore aucun match...\n\n Modifiez vos paramètres de découvertes !", viewController: self)
        }
        return messages.count
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height

        if !fetchingMore {
            if offsetY > contentHeight - scrollView.frame.height {
                beginBatchFetch()
            }
        }
    }
    
    func beginBatchFetch(){
        fetchingMore = true
        fetchUserMessages()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        let message = messages[indexPath.row]
        cell.message = message
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let message = messages[indexPath.row]
        guard let chatPartnerId = message.chatPartnerId() else { return }
        let ref = Database.database().reference().child("users").child(chatPartnerId)
        ref.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            guard let dictionary = snapshot.value as? [String: AnyObject] else { return }
            var user = User(dictionary: dictionary)
            user.uid = chatPartnerId
            user.parentUID = snapshot.key
            self?.showChatControllerForUser(user)
            
        })
    }
    
    func showChatControllerForUser(_ user: User) {
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.chatUser = user
        navigationController?.pushViewController(chatLogController, animated: true)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
}
