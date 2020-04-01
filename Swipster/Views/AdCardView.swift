//
//  AdCardView.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 22/03/2019.
//  Copyright © 2019 Swipster Inc. All rights reserved.
//

import Firebase

class AdCardView: GADUnifiedNativeAdView, CardsView {
    
    override var nativeAd: GADUnifiedNativeAd? {
        didSet {
            configureData()
        }
    }
    
    let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let mainImage: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 20
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.textColor = .black
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.sizeToFit()
        label.isUserInteractionEnabled = false
        return label
    }()
    
    var advertiserLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.isUserInteractionEnabled = false
        label.adjustsFontSizeToFitWidth = true
        label.textColor = .black
        label.font = .italicSystemFont(ofSize: 10)
        return label
    }()
    
    var descriptionText: UITextView = {
        let textView = UITextView()
        textView.textColor = .darkGray
        textView.isUserInteractionEnabled = false
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isSelectable = false
        textView.isScrollEnabled = false
        textView.showsVerticalScrollIndicator = false
        textView.translatesAutoresizingMaskIntoConstraints = true
        textView.sizeToFit()
        textView.isScrollEnabled = false
        return textView
    }()
    
    var brandLogo: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = false
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 10
        imageView.backgroundColor = .orange
        return imageView
    }()

    var downloadButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 91/255, green: 188/255, blue: 108/255, alpha: 1)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.isUserInteractionEnabled = false
        button.layer.cornerRadius = 15
//        button.downloadButton.isUserInteractionEnabled = false
        button.heightAnchor.constraint(equalToConstant: 42).isActive = true
        return button
    }()
    
    override func layoutSubviews() {
        mainImage.roundCorners([.topLeft, .topRight], radius: 10.0)
        titleLabel.leftAnchor.constraint(equalTo: backgroundView.leftAnchor, constant: 10).isActive = true
        advertiserLabel.leftAnchor.constraint(equalTo: backgroundView.leftAnchor, constant: 10).isActive = true
        descriptionText.leftAnchor.constraint(equalTo: backgroundView.leftAnchor, constant: 10).isActive = true
        downloadButton.leftAnchor.constraint(equalTo: backgroundView.leftAnchor, constant: 30).isActive = true
        descriptionText.textContainerInset = UIEdgeInsets.zero
        descriptionText.textContainer.lineFragmentPadding = 0
        if #available(iOS 13.0, *) {
            titleLabel.textColor = .label
            advertiserLabel.textColor = .label
            if traitCollection.userInterfaceStyle == .dark {
                descriptionText.textColor = .white
                backgroundView.backgroundColor = .secondarySystemBackground
            } else {
                descriptionText.textColor = .darkGray
                backgroundView.backgroundColor = .white
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setNativeFormat()
        
        addSubview(backgroundView)
        backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5).isActive = true
        backgroundView.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true

        mainImage.heightAnchor.constraint(equalToConstant: frame.height / 3).isActive = true

        let stackView = UIStackView(arrangedSubviews: [mainImage, titleLabel, advertiserLabel, descriptionText, brandLogo, downloadButton])
        stackView.axis = .vertical
        stackView.backgroundColor = .orange
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isLayoutMarginsRelativeArrangement = true
        if #available(iOS 11.0, *) {
            stackView.setCustomSpacing(5, after: mainImage)
            stackView.setCustomSpacing(5, after: advertiserLabel)
            stackView.setCustomSpacing(15, after: descriptionText)
            stackView.setCustomSpacing(15, after: brandLogo)
        } else {
            // Fallback on earlier versions
        }

        backgroundView.addSubview(stackView)
        stackView.leftAnchor.constraint(equalTo: backgroundView.leftAnchor).isActive = true
        stackView.rightAnchor.constraint(equalTo: backgroundView.rightAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: backgroundView.topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -10).isActive = true
        
        
        backgroundColor = UIColor(white: 1, alpha: 0.15)
        layer.cornerRadius = 10
    }
    
    func setNativeFormat() {
        headlineView = titleLabel
        bodyView = descriptionText
        advertiserView = advertiserLabel
        iconView = brandLogo
        callToActionView = downloadButton
    }
    
    func configureData() {
        titleLabel.text = nativeAd?.headline
        titleLabel.isHidden = nativeAd?.headline == nil
        advertiserLabel.text = nativeAd?.advertiser
        advertiserLabel.isHidden = nativeAd?.advertiser == nil
        descriptionText.text = nativeAd?.body
        descriptionText.isHidden = nativeAd?.body == nil
        downloadButton.setTitle(nativeAd?.callToAction, for: .normal)
        downloadButton.isHidden = nativeAd?.callToAction == nil
        brandLogo.image = nativeAd?.icon?.image
        brandLogo.isHidden = nativeAd?.icon?.image == nil
        mainImage.image = nativeAd?.images?[0].image
        mainImage.isHidden = nativeAd?.images?[0].image == nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
