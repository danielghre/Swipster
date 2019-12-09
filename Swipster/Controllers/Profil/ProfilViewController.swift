//
//  ProfilViewController.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 17/01/2019.
//  Copyright © 2019 Swipster Inc. All rights reserved.
//

import UIKit
import CoreLocation

class ProfilViewController: UIViewController, UIGestureRecognizerDelegate {
    
    var user: User?
    var position: CLLocation?
    
    @IBOutlet private weak var defaultProfilImage: UIImageView!
    @IBOutlet private weak var secondProfilImage: UIImageView!
    @IBOutlet private weak var thirdProfilImage: UIImageView!
    @IBOutlet private weak var fourthProfilImage: UIImageView!
    @IBOutlet private weak var nameAndAgeLabel: UILabel!
    @IBOutlet private weak var descriptiontextView: UITextView!
    @IBOutlet private weak var arrow: UIImageView!
    @IBOutlet private weak var dismissController: GradientView!
    @IBOutlet private weak var location: UILabel!
    @IBOutlet private weak var noOtherPicturesLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        arrow.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/2))
        let tgr = UITapGestureRecognizer(target: self, action: #selector(dismissVC))
        dismissController.addGestureRecognizer(tgr)
        if user != nil {
            setupUser()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                nameAndAgeLabel.textColor = .white
                descriptiontextView.textColor = .white
            } else {
                nameAndAgeLabel.textColor = UIColor(rgb: 0x414141)
                descriptiontextView.textColor = UIColor(rgb: 0x414141)
            }
        }
    }
    
    @objc func dismissVC(){
        let pulse = CASpringAnimation(keyPath: "transform.scale")
        pulse.duration = 0.3
        pulse.fromValue = 0.95
        pulse.toValue = 1.0
        pulse.initialVelocity = 0.5
        dismissController.layer.add(pulse, forKey: "pulse")
        dismiss(animated: true)
    }
    
    var initialTouchPoint: CGPoint = CGPoint(x: 0,y: 0)
    @IBAction func dragToDismiss(_ sender: UIPanGestureRecognizer) {
        let touchPoint = sender.location(in: view?.window)
        if sender.state == UIGestureRecognizer.State.began {
            initialTouchPoint = touchPoint
        } else if sender.state == UIGestureRecognizer.State.changed {
            if touchPoint.y - initialTouchPoint.y > 0 {
                view.frame = CGRect(x: 0, y: touchPoint.y - initialTouchPoint.y, width: view.frame.size.width, height: view.frame.size.height)
            }
        } else if sender.state == UIGestureRecognizer.State.ended || sender.state == UIGestureRecognizer.State.cancelled {
            if touchPoint.y - initialTouchPoint.y > 100 {
                dismiss(animated: true)
            } else {
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                })
            }
        }
    }
    
    func setupUser(){
        ImageService.getImage(withURL: URL(string: user!.pictureURL)) { [weak self] (image) in
            self?.defaultProfilImage.image = image
        }
        ImageService.getImage(withURL: URL(string: user!.secondPictureURL)) { [weak self] (image) in
            self?.secondProfilImage.image = image
        }
        ImageService.getImage(withURL: URL(string: user!.thirdPictureURL)) { [weak self] (image) in
            self?.thirdProfilImage.image = image
        }
        ImageService.getImage(withURL: URL(string: user!.fourthPictureURL)) { [weak self] (image) in
            self?.fourthProfilImage.image = image
        }
        nameAndAgeLabel.text = "\(user!.first_name), \(calcAge(birthday: user!.birthday)) ans"
        if user!.bio == ""{
            descriptiontextView.textColor = UIColor.lightGray
            descriptiontextView.text = "Aucune description..."
            descriptiontextView.font = UIFont.italicSystemFont(ofSize: 14)
        } else {
            descriptiontextView.text = user!.bio
        }
        
        let coordinateUser = CLLocation(latitude: Double(user!.latitude)!, longitude: Double(user!.longitude)!)
        let distanceInMeters = position!.distance(from: coordinateUser)
        let distanceInKms = Int(distanceInMeters/1000)
        
        location.text = "\(distanceInKms)Kms"
        
        if user?.secondPictureURL == "" && user?.thirdPictureURL == "" && user?.fourthPictureURL == "" {
            [secondProfilImage, thirdProfilImage, fourthProfilImage].forEach {
                $0?.isHidden = true
            }
            noOtherPicturesLabel.isHidden = false
        }
        
        if user?.secondPictureURL == "" {
            secondProfilImage.isHidden = true
        }
        if user?.thirdPictureURL == "" {
            thirdProfilImage.isHidden = true
        }
        if user?.fourthPictureURL == "" {
            fourthProfilImage.isHidden = true
        }
        
        defaultProfilImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(zoomDefault)))
        secondProfilImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(zoomSecond)))
        thirdProfilImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(zoomThird)))
        fourthProfilImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(zoomFourth)))
    }
    
    @objc func zoomDefault(){
        performZoomInForStartingImageView(defaultProfilImage)
    }
    
    @objc func zoomSecond(){
        performZoomInForStartingImageView(secondProfilImage)
    }
    
    @objc func zoomThird(){
        performZoomInForStartingImageView(thirdProfilImage)
    }
    
    @objc func zoomFourth(){
        performZoomInForStartingImageView(fourthProfilImage)
    }
    
    var startingFrame: CGRect?
    var blackBackgroundView: UIView?
    var startingImageView: UIImageView?
    var zoomingImageView: UIImageView!
    
    func performZoomInForStartingImageView(_ startingImageView: UIImageView) {
        
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
            }else if newScale > 3 {
                newScale = 3
            }
            else {
                view.transform = transform
                sender.scale = 1
            }
        } else if sender.state == .ended || sender.state == .failed || sender.state == .cancelled {
            guard let center = originalImageCenter else { return }
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
