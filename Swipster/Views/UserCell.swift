//
//  UserCell.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 05/04/2018.
//  Copyright © 2018 Swipster Inc. All rights reserved.
//

import FirebaseDatabase
import Firebase

class UserCell: UITableViewCell {
    
    let ref = Database.database().reference()
    
    var message: Message? {
        didSet {
            setupNameAndProfileImage()
            detailTextLabel?.font = UIFont(name: "AvenirNext-Regular", size: 16.0)
            detailTextLabel?.textColor = UIColor(rgb: 0x6F7179)
            
            if let id = message?.chatPartnerId() {
                let ref = Database.database().reference().child("users").child(id)
                ref.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                    guard let self = self else { return }
                    if(self.message?.fromId == snapshot.key) {
                        if (self.message?.videoUrl != nil) {
                            self.detailTextLabel?.text = "⇠ " + "📹 Vidéo"
                        } else if (self.message?.imageUrl != nil){
                            self.detailTextLabel?.text = "⇠ " +  "📷 Photo"
                        } else {
                            self.detailTextLabel?.text = "⇠ " + (self.message?.text)!
                        }
                        
                    } else {
                        if (self.message?.videoUrl != nil) {
                            self.detailTextLabel?.text = "📹 Vidéo"
                        } else if (self.message?.imageUrl != nil){
                            self.detailTextLabel?.text = "📷 Photo"
                        } else {
                            self.detailTextLabel?.text = self.message?.text
                        }
                    }
                })
            }
            
            if let seconds = message?.timestamp {
                let timestampDate = Date(timeIntervalSince1970: Double(seconds))
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "HH:mm"
                let time = dateFormatter.string(from: timestampDate)
                timeLabel.text = time
            }
        }
    }
    
    fileprivate func setupNameAndProfileImage() {
        
        if let id = message?.chatPartnerId() {
            let ref = Database.database().reference().child("users").child(id)
            ref.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                guard let self = self else { return }
                if let dictionary = snapshot.value as? [String: AnyObject] {
                    self.textLabel?.font = UIFont(name: "ITCAvantGardePro-Bk", size: 19.0)
                    self.textLabel?.text = dictionary["first_name"] as? String
                    
                    if let profileImageUrl = dictionary["pictureURL"] as? String {
                        ImageService.getImage(withURL: URL(string: profileImageUrl)) { [weak self] (image) in
                            self?.activityIndicator.stopAnimating()
                            self?.profileImageView.image = image
                        }
                    }
                }
                
            })
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if #available(iOS 13.0, *) {
            activityIndicator.style = .medium
            activityIndicator.color = .label
            if traitCollection.userInterfaceStyle == .dark {
                backgroundColor = .quaternarySystemFill
            } else {
                backgroundColor = .white
            }
        } else {
            activityIndicator.style = .gray
        }
        
        textLabel?.frame = CGRect(x: 75, y: textLabel!.frame.origin.y - 1, width: textLabel!.frame.width, height: textLabel!.frame.height)
        
        var ww = detailTextLabel!.frame.width
        ww = detailTextLabel!.frame.width > 120 ? 220 : detailTextLabel!.frame.width
        
        detailTextLabel?.frame = CGRect(x: 75, y: detailTextLabel!.frame.origin.y + 1, width: ww, height: detailTextLabel!.frame.height)
    }
    
    lazy var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 25
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "ITCAvantGardePro-Bk", size: 15.0)
        label.textColor = UIColor(rgb: 0x6F7179)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let activityIndicator: UIActivityIndicatorView = {
        let activity = UIActivityIndicatorView()
        activity.layer.masksToBounds = true
        activity.hidesWhenStopped = true
        activity.translatesAutoresizingMaskIntoConstraints = false
        activity.startAnimating()
        return activity
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        [activityIndicator, profileImageView, timeLabel].forEach {
            addSubview($0)
        }
        
        [activityIndicator, profileImageView].forEach {
            $0.leftAnchor.constraint(equalTo: leftAnchor, constant: 10).isActive = true
            $0.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            $0.widthAnchor.constraint(equalToConstant: 50).isActive = true
            $0.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }
        
        timeLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16).isActive = true
        timeLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

