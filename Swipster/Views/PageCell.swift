//
//  PageCell.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 24/10/2018.
//  Copyright © 2018 Swipster Inc. All rights reserved.
//

import UIKit

struct Page {
    let title, message, imageName: String
}

class PageCell: UICollectionViewCell {
    var page: Page? {
        didSet {
            
            guard let page = page else { return }
            
            imageView.image = UIImage(named: page.imageName)
            
            let color = UIColor(white: 1, alpha: 1)
            
            let attributedText = NSMutableAttributedString(string: page.title, attributes: [NSAttributedString.Key.font:  UIFont(name: "Helvetica-BoldOblique", size: 37)!, NSAttributedString.Key.foregroundColor: color])
            
            attributedText.append(NSAttributedString(string: "\n\n\(page.message)", attributes: [NSAttributedString.Key.font:  UIFont(name: "Bellota-Regular", size: 15)!, NSAttributedString.Key.foregroundColor: color]))
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let length = attributedText.string.count
            attributedText.addAttribute(kCTParagraphStyleAttributeName as NSAttributedString.Key, value: paragraphStyle, range: NSRange(location: 0, length: length))
            
            textView.attributedText = attributedText
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = .yellow
        iv.clipsToBounds = true
        return iv
    }()
    
    let textView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.backgroundColor = .purple
        tv.contentInset = UIEdgeInsets(top: 24, left: 0, bottom: 0, right: 0)
        return tv
    }()
    
    let lineSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.9, alpha: 1)
        return view
    }()
    
    func setupViews() {
        
        [imageView, textView, lineSeparatorView].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        [imageView, textView].forEach {
            $0.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            $0.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            $0.bottomAnchor.constraint(equalTo: textView.topAnchor).isActive = true
        }

        backgroundColor = .purple
        
        imageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        
        textView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.3).isActive = true
        textView.leftAnchor.constraint(equalTo: leftAnchor, constant: 16).isActive = true
        textView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        textView.rightAnchor.constraint(equalTo: rightAnchor, constant: -16).isActive = true
        
        lineSeparatorView.heightAnchor.constraint(equalToConstant: 0).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
