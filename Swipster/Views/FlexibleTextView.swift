//
//  FlexibleTextView.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 02/11/2018.
//  Copyright © 2018 Swipster Inc. All rights reserved.
//

import UIKit

class FlexibleTextView: UITextView {
    // limit the height of expansion per intrinsicContentSize
    var maxHeight: CGFloat = 0.0
    private let placeholderTextView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        tv.isUserInteractionEnabled = false
        tv.textColor = .gray
        return tv
    }()
    
    var placeholder: String? {
        get {
            return placeholderTextView.text
        }
        set {
            placeholderTextView.text = newValue
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UITextView.textDidChangeNotification, object: nil)
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        isScrollEnabled = false
        textContainerInset = UIEdgeInsets(top: 8, left: 7, bottom: 8, right: 7)
        layer.cornerRadius = 18
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        NotificationCenter.default.addObserver(self, selector: #selector(UITextInputDelegate.textDidChange(_:)), name: UITextView.textDidChangeNotification, object: self)
        placeholderTextView.font = font
        addSubview(placeholderTextView)
        
        NSLayoutConstraint.activate([
            placeholderTextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 7),
            placeholderTextView.trailingAnchor.constraint(equalTo: trailingAnchor),
            placeholderTextView.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var text: String! {
        didSet {
            invalidateIntrinsicContentSize()
            placeholderTextView.isHidden = !text.isEmpty
        }
    }
    
    override var font: UIFont? {
        didSet {
            placeholderTextView.font = font
            invalidateIntrinsicContentSize()
        }
    }
    
    override var contentInset: UIEdgeInsets {
        didSet {
            placeholderTextView.contentInset = contentInset
        }
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        
        if size.height == UIView.noIntrinsicMetric {
            // force layout
            layoutManager.glyphRange(for: textContainer)
            size.height = layoutManager.usedRect(for: textContainer).height + textContainerInset.top + textContainerInset.bottom
        }
        
        if maxHeight > 0.0 && size.height > maxHeight {
            size.height = maxHeight
            
            if !isScrollEnabled {
                isScrollEnabled = true
            }
        } else if isScrollEnabled {
            isScrollEnabled = false
        }
        
        return size
    }
    
    @objc private func textDidChange(_ note: Notification) {
        // needed incase isScrollEnabled is set to true which stops automatically calling invalidateIntrinsicContentSize()
        invalidateIntrinsicContentSize()
        placeholderTextView.isHidden = !text.isEmpty
    }
}
