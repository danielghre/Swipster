//
//  ChatMessageCell.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 05/04/2018.
//  Copyright © 2018 Swipster Inc. All rights reserved.
//

import UIKit
import AVFoundation

class ChatMessageCell: UICollectionViewCell {
    
    var message: Message?
    var chatLogController: ChatLogController?
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let activity = UIActivityIndicatorView()
        activity.translatesAutoresizingMaskIntoConstraints = false
        activity.hidesWhenStopped = true
        return activity
    }()
    
    let profilActivityIndicatorView: UIActivityIndicatorView = {
        let activity = UIActivityIndicatorView()
        activity.translatesAutoresizingMaskIntoConstraints = false
        activity.hidesWhenStopped = true
        return activity
    }()
    
    lazy var playButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let image = UIImage(named: "play")
        button.tintColor = UIColor.white
        button.setImage(image, for: UIControl.State())
        button.addTarget(self, action: #selector(handlePlay), for: .touchUpInside)
        return button
    }()
    
    var playerLayer: AVPlayerLayer?
    var player: AVPlayer?
    
    @objc func handlePlay() {
        if let videoUrlString = message?.videoUrl, let url = URL(string: videoUrlString) {
            player = AVPlayer(url: url)
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.frame = bubbleView.bounds
            bubbleView.layer.addSublayer(playerLayer!)
            
            player?.play()
            activityIndicatorView.startAnimating()
            playButton.isHidden = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        playerLayer?.removeFromSuperlayer()
        player?.pause()
        activityIndicatorView.stopAnimating()
    }
    
    let textView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont(name: "ITCAvantGardePro-Bk", size: 15)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear
        tv.isEditable = false
        tv.isUserInteractionEnabled = false
        tv.isSelectable = false
        return tv
    }()
    
    let bubbleView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var profileImageView: UIImageView = {
        let imageView = UIImageView()
        profilActivityIndicatorView.startAnimating()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openProfilVC)))
        return imageView
    }()
    
    lazy var messageImageView: UIImageView = {
        let imageView = UIImageView()
        activityIndicatorView.startAnimating()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomTap)))
        return imageView
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 10)
        return label
    }()
    
    @objc func handleZoomTap(_ tapGesture: UITapGestureRecognizer) {
        if message?.videoUrl != nil { return }
        
        if let imageView = tapGesture.view as? UIImageView {
            chatLogController?.performZoomInForStartingImageView(imageView)
        }
    }
    
    @objc func openProfilVC(){
        chatLogController?.handleNavBarTitleTouch()
    }
    
    var bubbleWidthAnchor, bubbleViewRightAnchor, bubbleViewLeftAnchor, timeLabelRightAnchor, timeLabelLeftAnchor: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        [bubbleView, textView, profileImageView, timeLabel].forEach {
            addSubview($0)
        }
        
        bubbleView.addSubview(messageImageView)
        messageImageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor).isActive = true
        messageImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        messageImageView.widthAnchor.constraint(equalTo: bubbleView.widthAnchor).isActive = true
        messageImageView.heightAnchor.constraint(equalTo: bubbleView.heightAnchor).isActive = true
        
        bubbleView.addSubview(playButton)
        bubbleView.addSubview(activityIndicatorView)
        profileImageView.addSubview(profilActivityIndicatorView)
        playButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        playButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        [playButton, activityIndicatorView].forEach {
            $0.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
            $0.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
        }

        [profileImageView, profilActivityIndicatorView].forEach {
            $0.leftAnchor.constraint(equalTo: leftAnchor, constant: 10).isActive = true
            $0.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            $0.widthAnchor.constraint(equalToConstant: 32).isActive = true
            $0.heightAnchor.constraint(equalToConstant: 32).isActive = true
        }
        
        bubbleViewRightAnchor = bubbleView.rightAnchor.constraint(equalTo: rightAnchor, constant: -10)
        bubbleViewRightAnchor?.isActive = true
        bubbleViewLeftAnchor = bubbleView.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8)
        bubbleView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        bubbleView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        
        bubbleWidthAnchor = bubbleView.widthAnchor.constraint(equalToConstant: 200)
        bubbleWidthAnchor?.isActive = true

        textView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 12).isActive = true
        textView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 4.5).isActive = true
        textView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor).isActive = true
        textView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        
        timeLabelRightAnchor = timeLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16)
        timeLabelRightAnchor?.isActive = true
        timeLabelLeftAnchor = timeLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 10)
        timeLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 5).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if #available(iOS 13.0, *) {
            activityIndicatorView.style = .large
            profilActivityIndicatorView.style = .medium
            profilActivityIndicatorView.color = .white
            timeLabel.textColor = .label
            if traitCollection.userInterfaceStyle == .dark {
                messageImageView.backgroundColor = .black
            } else {
                messageImageView.backgroundColor = UIColor(rgb: 0xb2bec3)
            }
        } else {
            messageImageView.backgroundColor = UIColor(rgb: 0xb2bec3)
            activityIndicatorView.style = .whiteLarge
            profilActivityIndicatorView.style = .gray
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

