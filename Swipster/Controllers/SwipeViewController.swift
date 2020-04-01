//
//  SwipeViewController.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 22/03/2018.
//  Copyright © 2018 Swipster Inc. All rights reserved.
//

import CoreLocation
import Firebase
import GoogleMobileAds
import SwiftEntryKit

class SwipeViewController: UIViewController  {
    
    @IBOutlet private weak var buttonView: UIView!
    @IBOutlet private weak var errorTitle: UILabel!
    @IBOutlet private weak var errorText: UILabel!
    @IBOutlet private weak var activatePublicButton: UIButton!
    
    var locationManager = CLLocationManager()
    
    lazy var cards = [CardsView]()

    var choice: choiceDone?
    
    lazy var matchView = MatchView()
    
    var emojiOptionsOverlay: EmojiOptionsOverlay!
    let cardAttributes: [(downscale: CGFloat, alpha: CGFloat)] = [(1, 1), (0.92, 0.8), (0.84, 0.6), (0.76, 0.4)]
    let cardInteritemSpacing: CGFloat = 15
    
    let ref = Database.database().reference()
    let uid = Auth.auth().currentUser?.uid
    
    lazy var pulseLayer = PulseLayer()
    
    @IBOutlet private weak var bannerView: GADBannerView!
    lazy var nativeAds = [GADUnifiedNativeAd]()
    var adLoader: GADAdLoader!
    
    var user: User?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? MenuViewController {
            vc.user = user
            vc.delegate = self
        } else if segue.identifier == "swipeFromRight" || segue.identifier == "slideFromRight" {
            chatBarButton.image = #imageLiteral(resourceName: "chat")
        }
    }
    
    @IBAction func activateProfil(_ sender: Any) {
        ref.child("users").child(uid!).updateChildValues(["public": "true"], withCompletionBlock: { [weak self] (err, ref) in
            guard let self = self else { return }
            if err == nil {
                self.activatePublicButton.isHidden = true
                self.errorTitle.isHidden = true
                self.errorText.isHidden = true
                self.pulseLayer.animate()
                self.user?.active = "true"
                self.showCards()
            } else {
                showPopupMessage(title: "Impossible..", buttonTitle: "Compris !", description: "Une erreur est survenu, veuillez réessayer plus tard !", image: #imageLiteral(resourceName: "ic_error_all_light_48pt")) {
                    SwiftEntryKit.dismiss()
                }
            }
        })
    }
    
    @IBOutlet private weak var loveImageView: UIButton!
    @IBAction func loveImageViewButton(_ sender: UIButton) {
        loveImageView.isUserInteractionEnabled = false
        choice = .love
        choiceByButton()
        sender.pulsate()
    }
    
    @IBOutlet private weak var cheersImageView: UIButton!
    @IBAction func cheersImgeViewButton(_ sender: UIButton) {
        cheersImageView.isUserInteractionEnabled = false
        choice = .cheers
        choiceByButton()
        sender.pulsate()

    }
    
    @IBOutlet private weak var hotImageView: UIButton!
    @IBAction func hotImageViewButton(_ sender: UIButton) {
        hotImageView.isUserInteractionEnabled = false
        choice = .hot
        choiceByButton()
        sender.pulsate()
//        let storyboard = UIStoryboard(name: "Premium", bundle: nil)
//        let vc = storyboard.instantiateViewController(withIdentifier: "premium")
//        self.present(vc, animated: true, completion: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        pulseLayer.position = view.center
        pulseLayer.radius = view.frame.width / 2 - 30
        view.layer.addSublayer(pulseLayer)
        
        if !hideAds() {
            bannerView.rootViewController = self
            bannerView.load(GADRequest())
        }
    }
    
    @IBOutlet private weak var chatBarButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        saveUserToLocal()
        
        emojiOptionsOverlay = EmojiOptionsOverlay(frame: view.frame)
        view.addSubview(emojiOptionsOverlay)
        
        dynamicAnimator = UIDynamicAnimator(referenceView: view)
        
        configureLocationManager()
    }
    
    func saveUserToLocal() {
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: "active") {
            defaults.set(true, forKey: "active")
            defaults.synchronize()
        }
    }
    
    func configureNativeAd() {
        if !hideAds() {
//            let adUnitID = "ca-app-pub-3940256099942544/8407707713"
            let adUnitID = "ca-app-pub-6971741950795531/9849969479" // live
            let numAdsToLoad = 1
            let options = GADMultipleAdsAdLoaderOptions()
            options.numberOfAds = numAdsToLoad
            adLoader = GADAdLoader(adUnitID: adUnitID,
                                   rootViewController: self,
                                   adTypes: [.unifiedNative],
                                   options: [options])
            adLoader.delegate = self
            adLoader.load(GADRequest())
        }
    }
    
    func configureLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    func settingsPerso() {
        let usersReference = ref.child("users")
        usersReference.keepSynced(true)
        usersReference.observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard let self = self else { return }
            if snapshot.hasChild(self.uid!) {
                getFcmToken()
                self.ref.child("users").child(self.uid!).observeSingleEvent(of: .value) { [weak self] (snapshot) in
                    guard let self = self else { return }
                    guard let dict = snapshot.value as? [String: Any] else { return }
                    let me = User(dictionary: dict)
                    if me.first_name != "" {
                        self.user = me
                        self.view.isUserInteractionEnabled = true
                        self.user?.seenArray = dict["seen"] as? [String: String]
                        ImageService.getImage(withURL: URL(string: me.pictureURL)) { (image) in }
                        self.user?.parentUID = self.uid
                        if me.position != nil {
                            self.showCards()
                        }
                        if me.purchased == true {
                            self.bannerView.isHidden = true
                            let save = UserDefaults.standard
                            save.set(true, forKey: "Purchased")
                            save.synchronize()
                        } else {
                            UserDefaults.standard.removeObject(forKey: "Purchased")
                            UserDefaults.standard.synchronize()
                        }
                    } else {
                        self.logoutUserSwipe()
                    }
                }
            } else {
                self.logoutUserSwipe()
            }
        }
    }
    
    func logoutUserSwipe() {
        logoutUser {
            self.navigationController?.viewControllers.removeAll()
            let storyboard = UIStoryboard(name: "LoginScreen", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "welcomeView")
            UIApplication.shared.keyWindow?.setRootViewController(vc, options: .init(direction: .toBottom, style: .linear))
            SwiftEntryKit.dismiss(.displayed)
        }
    }
    
    func showCards() {
        if user?.active == "false" {
            pulseLayer.stop()
            errorTitle.text = "Votre profil est masqué"
            let attributedString = NSMutableAttributedString(string: "Activez la fonction publique pour découvrir les profils autour de vous !")
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 5
            paragraphStyle.alignment = .center
            attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))
            errorText.attributedText = attributedString
            errorTitle.isHidden = false
            errorText.isHidden = false
            activatePublicButton.isHidden = false
        } else {
            let query = ref.child("users")
            query.observeSingleEvent(of: .value) { [weak self] (snapshot) in
                guard let self = self else { return }
                for child in snapshot.children.allObjects as! [DataSnapshot] {
                    if child.key != self.uid && !(self.user?.seenArray?[child.key] != nil) {
                        guard let dict = child.value as? [String: Any] else { return }
                        let user = User(dictionary: dict)
                        if user.active == "true" && user.position != nil && self.user?.position != nil {
                            let distanceInMeters = self.user?.position?.distance(from: (user.position)!)
                            let distanceInKms = distanceInMeters!/1000
                            let age = calcAge(birthday: user.birthday)
                            let distance = Double(self.user!.lookingDist)!
                            
                            if (self.user?.uid != user.uid && (user.gender == (self.user!.lookingFor) || (self.user!.lookingFor) == "both") && distanceInKms <= distance && age <= Int(self.user!.maxAge)! && age >= Int(self.user!.minAge)!) {
                                let card = ImageCard(frame: CGRect(x: 0, y: 0, width: self.view.frame.width - 70, height: self.view.frame.height * 0.49))
                                card.user = user
                                card.user?.parentUID = child.key
                                card.reportButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.handleReportTouched)))
                                self.cards.append(card)
                            }
                        }
                    }
                }
                if (self.cards.count == 0) {
                    self.pulseLayer.stop()
                    self.hideButtons(state: true)
                } else {
                    self.layoutCards()
                }
                if self.cards.count > 5 {
                    self.configureNativeAd()
                }
            }
        }
    }
    
    @objc func handleReportTouched(gesture: UITapGestureRecognizer){
        report(user: (cards[0] as! ImageCard).user!, fromUID: user?.parentUID ?? "uid not found", fromName: user!.first_name, isMatch: false, completion: { [weak self] in
            self?.swipeTheUserForSignal()
        })
    }
    
    func swipeTheUserForSignal () {
        SwiftEntryKit.dismiss(.all)
        (cards[0] as! ImageCard).showOptionLabel(option: .dislike2)
        emojiOptionsOverlay.showEmoji(for: .dislike2)
        rotateImage(xTranslation: -10, yTranslation: 0)
        choice = .nothing
        add()
    }
    
    deinit {
        print("deinit from swipe")
    }
    
    func layoutCards() {
        let firstCard = cards[0] as! UIView
        view.addSubview(firstCard)
        hideButtons(state: false)
        if pulseLayer.isAnimating {
            pulseLayer.stop()
        }
        firstCard.layer.zPosition = CGFloat(cards.count)
        firstCard.center = view.center
        firstCard.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleCardPan)))
        
        if hideAds() {
            firstCard.frame.origin.y += 15
        } else {
            firstCard.frame.origin.y += 0
        }
        
        for i in 1...3 {
            if i > (cards.count - 1) { continue }
            
            let card = cards[i] as! UIView
            
            card.layer.zPosition = CGFloat(cards.count - i)
            
            let downscale = cardAttributes[i].downscale
            let alpha = cardAttributes[i].alpha
            card.transform = CGAffineTransform(scaleX: downscale, y: downscale)
            card.alpha = alpha
            
            // space between each cards
            card.center.x = view.center.x
            card.frame.origin.y = (cards[0] as! UIView).frame.origin.y - (CGFloat(i) * cardInteritemSpacing)
            
            if i == 3 {
                card.frame.origin.y += 1.5
            }
            
            view.addSubview(card)
        }
        view.bringSubviewToFront(cards[0] as! UIView)
    }
    
    func showNextCard() {
        if cards.count <= 1 {
            pulseLayer.stop()
            self.hideButtons(state: true)
            return
        }
        let animationDuration: TimeInterval = 0.2
        for i in 1...3 {
            if i > (cards.count - 1) { continue }
            let card = cards[i] as! UIView
            let newDownscale = cardAttributes[i - 1].downscale
            let newAlpha = cardAttributes[i - 1].alpha
            UIView.animate(withDuration: animationDuration, delay: (TimeInterval(i - 1) * (animationDuration / 2)), usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: [], animations: {
                card.transform = CGAffineTransform(scaleX: newDownscale, y: newDownscale)
                card.alpha = newAlpha
                if i == 1 {
                    if hideAds() {
                        card.center = CGPoint(x: self.view.center.x, y: self.view.center.y + 15)
                    } else {
                        card.center = self.view.center
                    }
                } else {
                    card.center.x = self.view.center.x
                    card.frame.origin.y = (self.cards[1] as! UIView).frame.origin.y - (CGFloat(i - 1) * self.cardInteritemSpacing)
                }
            }, completion: { [weak self] (_) in
                if i == 1 {
                    guard let self = self else { return }
                    card.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.handleCardPan)))
                }
            })
        }
        // add a new card (now the 4th card in the deck) to the very back
        if 4 > (cards.count - 1) {
            if cards.count != 1 {
                view.bringSubviewToFront(cards[1] as! UIView)
            }
            return
        }
        let newCard = cards[4] as! UIView
        newCard.layer.zPosition = CGFloat(cards.count - 4)
        let downscale = cardAttributes[3].downscale
        let alpha = cardAttributes[3].alpha
        
        // initial state of new card
        newCard.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        newCard.alpha = 0
        newCard.center.x = view.center.x
        newCard.frame.origin.y = (cards[1] as! UIView).frame.origin.y - (4 * cardInteritemSpacing)
        view.addSubview(newCard)
        
        // animate to end state of new card
        UIView.animate(withDuration: animationDuration, delay: (3 * (animationDuration / 2)), usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: [], animations: {
            newCard.transform = CGAffineTransform(scaleX: downscale, y: downscale)
            newCard.alpha = alpha
            newCard.center.x = self.view.center.x
            newCard.frame.origin.y = (self.cards[1] as! UIView).frame.origin.y - (3 * self.cardInteritemSpacing) + 1.5
        })
        // first card needs to be in the front for proper interactivity
        view.bringSubviewToFront(cards[1] as! UIView)
    }
    
    /// This function continuously checks to see if the card's center is on the screen anymore. If it finds that the card's center is not on screen, then it triggers removeOldFrontCard() which removes the front card from the data structure and from the view.
    var cardIsHiding = false
    func hideFrontCard() {
        if #available(iOS 10.0, *) {
            var cardRemoveTimer: Timer? = nil
            cardRemoveTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] (_) in
                guard self != nil else { return }
                if !(self!.view.bounds.contains((self!.cards[0] as! UIView).center)) {
                    cardRemoveTimer!.invalidate()
                    self?.cardIsHiding = true
                    UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseIn], animations: {
                        (self?.cards[0] as! UIView).alpha = 0.0
                    }, completion: { (_) in
                        self?.removeOldFrontCard()
                        self?.cardIsHiding = false
                    })
                }
            })
        } else {
            UIView.animate(withDuration: 0.2, delay: 1.5, options: [.curveEaseIn], animations: {
                (self.cards[0] as! UIView).alpha = 0.0
            }, completion: { [weak self] (_) in
                self?.removeOldFrontCard()
            })
        }
    }
    
    func removeOldFrontCard() {
        (cards[0] as! UIView).removeFromSuperview()
        cards.remove(at: 0)
        hotImageView.isUserInteractionEnabled = true
        cheersImageView.isUserInteractionEnabled = true
        loveImageView.isUserInteractionEnabled = true
    }
    
    var dynamicAnimator: UIDynamicAnimator!
    var cardAttachmentBehavior: UIAttachmentBehavior!
    /// This method handles the swiping gesture on each card and shows the appropriate emoji based on the card's center.
    @objc func handleCardPan(sender: UIPanGestureRecognizer) {
        // if we're in the process of hiding a card, don't let the user interace with the cards yet
        if cardIsHiding { return }
        // change this to your discretion - it represents how far the user must pan up or down to change the option
        let optionLength: CGFloat = 60
        // distance user must pan right or left to trigger an option
        let requiredOffsetFromCenter: CGFloat = 15
        
        let c0 = cards[0] as! UIView
        
        let panLocationInView = sender.location(in: view)
        let panLocationInCard = sender.location(in: cards[0] as? UIView)
        switch sender.state {
        case .began:
            dynamicAnimator.removeAllBehaviors()
            let offset = UIOffset.init(horizontal: panLocationInCard.x - c0.bounds.midX, vertical: panLocationInCard.y - c0.bounds.midY);
            // card is attached to center
            cardAttachmentBehavior = UIAttachmentBehavior(item: c0, offsetFromCenter: offset, attachedToAnchor: panLocationInView)
            dynamicAnimator.addBehavior(cardAttachmentBehavior)
        case .changed:
            cardAttachmentBehavior.anchorPoint = panLocationInView
            if c0.center.x > (view.center.x + requiredOffsetFromCenter) {
                if c0.center.y < (view.center.y - optionLength) {
                    if cards[0] is ImageCard {
                        (cards[0] as! ImageCard).showOptionLabel(option: .like3)
                    }
                    emojiOptionsOverlay.showEmoji(for: .like3)
                    choice = .love
                    
                } else if c0.center.y > (view.center.y + optionLength) {
                    if cards[0] is ImageCard {
                        (cards[0] as! ImageCard).showOptionLabel(option: .like1)
                    }
                    emojiOptionsOverlay.showEmoji(for: .like1)
                    choice = .hot
                    
                } else {
                    if cards[0] is ImageCard {
                        (cards[0] as! ImageCard).showOptionLabel(option: .like2)
                    }
                    emojiOptionsOverlay.showEmoji(for: .like2)
                    choice = .cheers
                }
            }
            else if c0.center.x < (view.center.x - requiredOffsetFromCenter) {
                if cards[0] is ImageCard {
                    (cards[0] as! ImageCard).showOptionLabel(option: .dislike2)
                }
                emojiOptionsOverlay.showEmoji(for: .dislike2)
                choice = .nothing
            }
            else {
                if cards[0] is ImageCard {
                    (cards[0] as! ImageCard).hideOptionLabel()
                }
                emojiOptionsOverlay.hideFaceEmojis()
            }
            
        case .ended:
            dynamicAnimator.removeAllBehaviors()
            emojiOptionsOverlay.hideFaceEmojis()
            
            if !(c0.center.x > (view.center.x + requiredOffsetFromCenter) || c0.center.x < (view.center.x - requiredOffsetFromCenter)) {
                
                var center = CGPoint()
                if hideAds() {
                    center = CGPoint(x: view.frame.width / 2, y: view.frame.height / 2 + 15)
                } else {
                    center = view.center
                }

                let snapBehavior = UISnapBehavior(item: c0, snapTo: center)
                dynamicAnimator.addBehavior(snapBehavior)
            } else {
                let velocity = sender.velocity(in: view)
                let pushBehavior = UIPushBehavior(items: [c0], mode: .instantaneous)
                if choice == .nothing {
                    pushBehavior.pushDirection = CGVector(dx: -10, dy: velocity.y/10)
                } else {
                    pushBehavior.pushDirection = CGVector(dx: velocity.x/10, dy: velocity.y/10)
                }
                pushBehavior.magnitude = 175
                dynamicAnimator.addBehavior(pushBehavior)
                // spin after throwing
                var angular = CGFloat.pi / 2 // angular velocity of spin
                
                let currentAngle: Double = atan2(Double(c0.transform.b), Double(c0.transform.a))
                
                if currentAngle > 0 {
                    angular = angular * 1
                } else {
                    angular = angular * -1
                }
                let itemBehavior = UIDynamicItemBehavior(items: [c0])
                itemBehavior.friction = 0.2
                itemBehavior.allowsRotation = true
                itemBehavior.addAngularVelocity(CGFloat(angular), for: c0)
                dynamicAnimator.addBehavior(itemBehavior)
                choiceBySwipe()
            }
        default:
            break
        }
    }
    
    func choiceBySwipe() {
        if cards[0] is AdCardView {
            adLoader.load(GADRequest())
        }
        showNextCard()
        hideFrontCard()
        if cards[0] is ImageCard {
            print((cards[0] as! ImageCard).user?.parentUID ?? "not found")
        }
        add()
    }
    
    func choiceByButton() {
        if cards[0] is AdCardView {
            adLoader.load(GADRequest())
            rotateImage(xTranslation: 10, yTranslation: 0)
        } else {
            switch choice {
            case .love:
                (cards[0] as! ImageCard).showOptionLabel(option: .like3)
                emojiOptionsOverlay.showEmoji(for: .like3)
                rotateImage(xTranslation: 10, yTranslation: -20)
                add()
                break
            case .cheers:
                (cards[0] as! ImageCard).showOptionLabel(option: .like2)
                emojiOptionsOverlay.showEmoji(for: .like2)
                rotateImage(xTranslation: 10, yTranslation: 0)
                add()
                break
            case .hot:
                (cards[0] as! ImageCard).showOptionLabel(option: .like1)
                emojiOptionsOverlay.showEmoji(for: .like1)
                rotateImage(xTranslation: 10, yTranslation: 20)
                add()
                break
            default:
                break
            }
        }
    }
    
    func seenPeople(choice: String) {
        let usersReference = [ref.child("users").child(uid!).child("seen"), ref.child("users").child(uid!).child(choice)]
        for ref in usersReference {
            let cardParent = cards[0] as! ImageCard
            let values = [cardParent.user?.parentUID: "true"]
            
            ref.updateChildValues(values, withCompletionBlock: { (err, ref) in
                if err != nil {
                    print(err ?? "")
                    return
                }
            })
        }
    }

    func add() {
        guard let choiceToString = choice?.rawValue else { return }
        if cards[0] is ImageCard {
            let parentUID = (cards[0] as! ImageCard).user?.parentUID
            let matchIMG = (cards[0] as! ImageCard).defaultPic
            if choice != .nothing {
                ref.child("users").child(parentUID!).child(choiceToString).observeSingleEvent(of: .value) { [weak self] (snapshot) in
                    guard let self = self else { return }
                    let uid = self.user!.uid.isEmpty ? "nil" : self.user!.uid
                    if snapshot.hasChild(uid) || snapshot.hasChild(self.user!.parentUID!) {
                        var properties: [String: String] = [:]
                        switch self.choice {
                        case .love:
                            properties = ["text": "😍😍😍"]
                            break
                        case .cheers:
                            properties = ["text": "🍻🍻🍻"]
                            break
                        case .hot:
                            properties = ["text": "🔥🔥🔥"]
                            break
                        default:
                            break;
                        }
                        self.sendMessageWithProperties(properties as [String : AnyObject], parentUID: parentUID!)
                        self.isMatching(parentUID: parentUID!, matchIMG: matchIMG)
                    }
                }
            }
            seenPeople(choice: choiceToString)
        }
    }
    
    func isMatching(parentUID: String, matchIMG: UIImage) {
        let notifMessage: [String: Any] = [
            "to" : (cards[0] as! ImageCard).user!.fcmToken,
            "notification" :
                ["title" : "Swipster", "body" : "Vous avez un nouveau match !", "badge" : 1, "sound" : "default", "pictureURL" : user!.pictureURL, "uid" : uid!]
        ]
        sendPushNotification(notData: notifMessage)
        matchView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        ImageService.getImage(withURL: URL(string: user!.pictureURL)) { [weak self] (image) in
            self?.matchView.myPic.image = image
        }
        matchView.matchPic.image = matchIMG
        matchView.layer.zPosition = 10
        matchView.okButton.addTarget(self, action: #selector(closeMatchView), for: .touchUpInside)
        matchView.alpha = 0
        guard let choiceToString = choice?.rawValue else { return }
        matchView.swiper.image = UIImage(named: choiceToString)
        matchView.swiper.image = matchView.swiper.image!.withRenderingMode(.alwaysTemplate)
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.view.addSubview(self.matchView)
            self.matchView.alpha = 1
        })
        let usersReference = ref.child("matches").child(uid!)
        
        let values = [parentUID: "true"]
        
        usersReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if err != nil {
                print(err ?? "")
                return
            }
        })
        if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
        }
    }
    
    fileprivate func sendMessageWithProperties(_ properties: [String: AnyObject], parentUID: String) {
        let childRef = ref.child("messages").childByAutoId()
        let toId = parentUID
        let timestamp = Int(Date().timeIntervalSince1970)

        var values: [String: AnyObject] = ["toId": toId as AnyObject, "fromId": uid as AnyObject, "timestamp": timestamp as AnyObject]

        properties.forEach({values[$0] = $1})

        childRef.updateChildValues(values) { [weak self] (error, ref) in
            guard let self = self else { return }
            if error != nil {
                print(error!)
                return
            }
        
            let userMessagesRef = Database.database().reference().child("user-messages").child(self.uid!).child(toId)
            
            let messageId = childRef.key
            userMessagesRef.updateChildValues([messageId!: 1])
            
            let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toId).child(self.uid!)
            recipientUserMessagesRef.updateChildValues([messageId!: 1])
            self.chatBarButton.image = #imageLiteral(resourceName: "chatNotif").withRenderingMode(.alwaysOriginal)
        }
    }
    
    @objc func closeMatchView() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.matchView.alpha = 0
        }) { [weak self] (_) in
            self?.matchView.removeFromSuperview()
        }
        if cards.count == 0 {
            hideButtons(state: true)
        }
//        MessagesController().showChatControllerForUser(cards[0].user!)
    }
    
    func rotateImage(xTranslation: Int, yTranslation: Int){
        dynamicAnimator.removeAllBehaviors()
        let pushBehavior = UIPushBehavior(items: [cards[0] as! UIView], mode: .instantaneous)
        pushBehavior.pushDirection = CGVector(dx: xTranslation, dy: yTranslation)
        pushBehavior.magnitude = 175
        dynamicAnimator.addBehavior(pushBehavior)
        // spin after throwing
        var angular = CGFloat.pi / 2 // angular velocity of spin
        
        let currentAngle: Double = atan2(Double((cards[0] as! UIView).transform.b), Double((cards[0] as! UIView).transform.a))
        
        if currentAngle > 0 {
            angular = angular * 1
        } else {
            angular = angular * -1
        }
        let itemBehavior = UIDynamicItemBehavior(items: [cards[0] as! UIView])
        itemBehavior.friction = 0.2
        itemBehavior.allowsRotation = true
        itemBehavior.addAngularVelocity(CGFloat(angular), for: cards[0] as! UIView)
        dynamicAnimator.addBehavior(itemBehavior)
        
        showNextCard()
        hideFrontCard()
        
        emojiOptionsOverlay.hideFaceEmojis()
    }
    
    func hideButtons(state: Bool) {
        errorTitle.isHidden = !state
        errorTitle.text = "Oops..."
        errorText.isHidden = !state
        errorText.text = "Il n'y a personne autour de vous.\n\nModifiez vos paramètres..."
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        if state == false {
            bannerView.bottomAnchor.constraint(equalTo: buttonView.topAnchor, constant: -8).isActive = true
        } else if state == true && cards.count <= 1 {
            bannerView.bottomAnchor.constraint(equalTo: buttonView.topAnchor, constant: -8).isActive = false
            if #available(iOS 11.0, *) {
                bannerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
            } else {
                bannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            }
        }
        buttonView.isHidden = state
    }
}

extension SwipeViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        
        view.isUserInteractionEnabled = false
        pulseLayer.animate()
        
        if isAppAlreadyLaunchedOnce() == false {
            let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
            if let walkthroughViewController = storyboard.instantiateViewController(withIdentifier: "WalkthroughViewController") as? WalkthroughViewController {
                present(walkthroughViewController, animated: true)
                view.isUserInteractionEnabled = true
            }
        }
        switch status {
        case .restricted, .denied:
            pulseLayer.stop()
            let storyBoard : UIStoryboard = UIStoryboard(name: "Location", bundle:nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "LocationViewController") as! LocationViewController
            nextViewController.modalPresentationStyle = .fullScreen
            present(nextViewController, animated: true)
            break

        case .authorizedWhenInUse, .authorizedAlways:
            if user == nil {
                settingsPerso()
            } else {
                view.isUserInteractionEnabled = true
                return
            }
            let latitude: CLLocationDegrees = (locationManager.location?.coordinate.latitude)!
            let longitude: CLLocationDegrees = (locationManager.location?.coordinate.longitude)!
            let usersReference = ref.child("users")
            usersReference.child(self.uid!).observeSingleEvent(of: .value) { [weak self] (snapshot) in
                guard let self = self else { return }
                guard let dict = snapshot.value as? [String: Any] else { return }
                let me = User(dictionary: dict)
                if me.isPremium != true {
                    let values = ["latitude": String(latitude), "longitude": String(longitude)]
                    usersReference.child(self.uid!).updateChildValues(values, withCompletionBlock: { (err, ref)  in
                        if err != nil {
                            return
                        }
                        self.user?.latitude = String(latitude)
                        self.user?.longitude = String(longitude)
                        self.user?.position = CLLocation(latitude: latitude, longitude: longitude)
                        if self.cards.isEmpty {
                            self.settingsPerso()
                        }
                    })
                } else {
//                    self.settingsPerso()
                }
            }
            break
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}

extension SwipeViewController: GADUnifiedNativeAdLoaderDelegate {
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADUnifiedNativeAd) {
        let adCardView = AdCardView(frame: CGRect(x: 0, y: 0, width: view.frame.width - 70, height: view.frame.height * 0.52))
        adCardView.nativeAd = nativeAd
        if cards.count > 5 {
            cards.insert(adCardView, at: 5)
        }
    }
    
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: GADRequestError) {
        print("did fail \(error)")
    }
}

extension SwipeViewController: MenuUpdateDelegate {
    func didUpdate() {
        for i in 0...4 {
            if cards.indices.contains(i) {
                let card = cards[i] as! UIView
                card.removeFromSuperview()
            }
        }
        cards.removeAll()
        buttonView.isHidden = true
        pulseLayer.animate()
        pulseLayer.radius = view.frame.width / 2 - 30
        settingsPerso()
    }
}
