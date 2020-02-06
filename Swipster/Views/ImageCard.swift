//
//  ImageCard.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 22/03/2018.
//  Copyright © 2018 Swipster Inc. All rights reserved.
//

import UIKit

protocol CardsView {}

class ImageCard: CardView, CardsView {
    
    var isBioOpen = false
    var defaultPic = UIImage()
    
    var user: User? {
        didSet {
            layoutUserDetails()
        }
    }
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = UIFont(name: "ITCAvantGardePro-Bk", size: 19.0)
        label.textAlignment = .left
        label.frame = CGRect(x: 0, y: 10, width: 80, height: 24)
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    lazy var iconsContainerView: UIView = {
        let containerView = UIView()
        containerView.layer.shadowColor = UIColor(white: 0.4, alpha: 0.4).cgColor
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOpacity = 0.5
        containerView.backgroundColor = .white
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        return containerView
    }()
    
    lazy var activityIndicator: UIActivityIndicatorView = {
        let activity = UIActivityIndicatorView()
        activity.color = .white
        activity.style = .whiteLarge
        activity.startAnimating()
        activity.hidesWhenStopped = true
        return activity
    }()
    
    lazy var bioTextView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont(name: "ITCAvantGardePro-Bk", size: 13)
        tv.backgroundColor = .clear
        tv.textColor = .black
        tv.frame = CGRect(x: 3, y: 5, width: 240, height: 25)
        tv.textAlignment = .center
        return tv
    }()
    
    lazy var bioButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.white, for: .normal)
        button.setTitle("i", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.cornerRadius = 12.5
        button.clipsToBounds = true
        return button
    }()
    
    let reportButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.white, for: .normal)
        button.setTitle("Signaler", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.cornerRadius = 13
        button.clipsToBounds = true
        return button
    }()
    
    let ageLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = UIFont(name: "ITCAvantGardePro-XLt", size: 19.0)
        label.textAlignment = .right
        return label
    }()
    
    lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.isPagingEnabled = true
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.backgroundColor = .purple
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        return sv
    }()
    
    lazy var pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.tintColor = .clear
        pc.pageIndicatorTintColor = .black
        pc.currentPageIndicatorTintColor = .white
        pc.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2)
        pc.translatesAutoresizingMaskIntoConstraints = false
        return pc
    }()
    
    func layoutUserDetails(){
        var imgA = [UIImage]()
        ImageService.getImage(withURL: URL(string: user!.pictureURL)) { [weak self] (image) in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            guard let img = image else { return }
            self.defaultPic = img
            imgA.append(image!)
            if self.user!.secondPictureURL != "" {
                ImageService.getImage(withURL: URL(string: self.user!.secondPictureURL)) { (image) in
                    imgA.append(image!)
                }
                if self.user!.thirdPictureURL != "" {
                    ImageService.getImage(withURL: URL(string: self.user!.thirdPictureURL)) { (image) in
                        imgA.append(image!)
                    }
                    if self.user!.fourthPictureURL != "" {
                        ImageService.getImage(withURL: URL(string: self.user!.fourthPictureURL)) { (image) in
                            imgA.append(image!)
                        }
                    }
                }
            }
            self.setupImages(imgA)
        }
        
        ageLabel.text = String(calcAge(birthday: user!.birthday)) + " ans"
        if user?.bio != "" {
            bioTextView.text = user?.bio
            bioButton.frame = CGRect(x: frame.width/2 - 70, y: 10, width: 25, height: 25)
            reportButton.frame = CGRect(x: frame.width/2 - 35, y: 10, width: 85, height: 25)
            
            let fixedWidth = bioTextView.frame.size.width
            let newSize = bioTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
            bioTextView.frame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
            
            iconsContainerView.addSubview(bioTextView)
            iconsContainerView.frame = CGRect(x: 0, y: 0, width: 250, height: bioTextView.frame.height + 5)
            iconsContainerView.layer.cornerRadius = 15
            
        } else {
            bioButton.isHidden = true
            reportButton.translatesAutoresizingMaskIntoConstraints = false
            reportButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 10).isActive = true
            reportButton.widthAnchor.constraint(equalToConstant: 85).isActive = true
            reportButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
            reportButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        }
        nameLabel.text = user?.first_name
    }
    
    func setupImages(_ imgArray: [UIImage]) {
        var imageWidth, imageHeight: CGFloat
        
        if scrollView.frame.width != 0 || scrollView.frame.height != 0 {
            imageWidth = scrollView.frame.width
            imageHeight = scrollView.frame.height
        } else {
            imageWidth = frame.width - 24
            imageHeight = frame.height - 60
        }
        pageControl.numberOfPages = imgArray.count
        
        var yPosition: CGFloat = 0
        var scrollViewContentSize: CGFloat = 0
        
        scrollView.delegate = self
        imgArray.forEach {
            let myImageView = UIImageView(image: $0)
            myImageView.contentMode = .scaleAspectFill
            myImageView.frame.size.width = imageWidth
            myImageView.frame.size.height = imageHeight
            myImageView.frame.origin.y = yPosition
            
            scrollView.addSubview(myImageView)
            yPosition += imageHeight
            scrollViewContentSize += imageHeight
        }
        scrollView.contentSize = CGSize(width: imageWidth, height: scrollViewContentSize)
        if imgArray.count > 1 {
            addSubview(pageControl)
            pageControl.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20).isActive = true
            pageControl.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -15).isActive = true
            pageControl.widthAnchor.constraint(equalToConstant: 5).isActive = true
        }
    }
    
    override init(frame: CGRect){
        super.init(frame: frame)
        
        addSubview(scrollView)
        scrollView.widthAnchor.constraint(equalToConstant: frame.width - 24).isActive = true
        scrollView.topAnchor.constraint(equalTo: topAnchor, constant: 12).isActive = true
        scrollView.heightAnchor.constraint(equalToConstant: frame.height - 60).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        
        let nameAndButtonView = UIView()
        nameAndButtonView.frame = CGRect(x: 12, y: frame.height - 60 + 13, width: frame.width - 24, height: 40)
        activityIndicator.frame = bounds
        ageLabel.frame = CGRect(x: nameAndButtonView.frame.width - 70, y: 12, width: 70, height: 24)
        let lgpr = UITapGestureRecognizer(target: self, action: #selector(handleBioTouched))
        bioButton.addGestureRecognizer(lgpr)
        
        addSubview(nameAndButtonView)
        addSubview(activityIndicator)

        [nameLabel, ageLabel, bioButton, reportButton].forEach {
            nameAndButtonView.addSubview($0)
        }
    }
    
    override func layoutSubviews() {
        if #available(iOS 13.0, *) {
            activityIndicator.style = .large
            if traitCollection.userInterfaceStyle == .dark {
                bioTextView.textColor = .label
                iconsContainerView.backgroundColor = .secondarySystemBackground
            }
        }
    }
    
    @objc func handleBioTouched(gesture: UITapGestureRecognizer){
        if !isBioOpen {
            isBioOpen = true
            handleGestureBegan(gesture: gesture)
        } else {
            isBioOpen = false
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
                self.iconsContainerView.transform = self.iconsContainerView.transform.translatedBy(x: 0, y: self.iconsContainerView.frame.height)
                self.iconsContainerView.alpha = 0
            }, completion: { [weak self] (_) in
                self?.iconsContainerView.removeFromSuperview()
            })
        }
    }
    
    fileprivate func handleGestureBegan(gesture: UITapGestureRecognizer) {
        addSubview(iconsContainerView)
        let pressedLocation = gesture.location(in: self)
        let centeredX = (frame.width - iconsContainerView.frame.width) / 2
        
        iconsContainerView.alpha = 0
        iconsContainerView.transform = CGAffineTransform(translationX: centeredX, y: pressedLocation.y)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            self.iconsContainerView.alpha = 1
            self.iconsContainerView.transform = CGAffineTransform(translationX: centeredX, y: pressedLocation.y - self.iconsContainerView.frame.height - 40)
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ImageCard: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageNumber = round(scrollView.contentOffset.y / scrollView.frame.size.height)
        pageControl.currentPage = Int(pageNumber)
    }
}
