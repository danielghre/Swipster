//
//  EmojiOptionsOverlay.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 22/03/2018.
//  Copyright © 2018 Swipster Inc. All rights reserved.
//

import UIKit

class EmojiOptionsOverlay: UIView {
    
    let emojiPadding: CGFloat = 10
    let emojiSize = CGSize(width: 40, height: 40)
    let emojiInitialOffset: CGFloat = 90
    let emojiInitialAlpha: CGFloat = 0.45
    
    let backgroundLeftView = UIView()
    let backgroundRightView = UIView()
    let like1Emoji = UIImageView(image: UIImage(named: "hot")?.withRenderingMode(.alwaysTemplate))
    let like2Emoji = UIImageView(image: UIImage(named: "cheers")?.withRenderingMode(.alwaysTemplate))
    let like3Emoji = UIImageView(image: UIImage(named: "love")?.withRenderingMode(.alwaysTemplate))
    let dislike2Emoji = UIImageView(image: UIImage(named: "proot"))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        isUserInteractionEnabled = false
        layer.zPosition = CGFloat(Float.greatestFiniteMagnitude)
        
        for view in [backgroundLeftView, backgroundRightView] {
            view.backgroundColor = UIColor(white: 1, alpha: 0.85)
            view.layer.masksToBounds = true
            addSubview(view)
        }
        
        backgroundLeftView.frame = CGRect(x: 0, y: (frame.height/2) - 35, width: 65, height: 70)
        backgroundLeftView.roundCorners([.topRight, .bottomRight], radius: 10)
        
        backgroundRightView.frame = CGRect(x: frame.width, y: (frame.height/2) - 105, width: 65, height: 210)
        backgroundRightView.roundCorners([.topLeft, .bottomLeft], radius: 10)
        
        like1Emoji.frame = CGRect(x: frame.width - emojiPadding - emojiSize.width, y: (frame.height/2) + (emojiSize.height * 0.5) + emojiPadding + 15, width: 35, height: emojiSize.height)
        
        like2Emoji.frame = CGRect(x: frame.width - emojiPadding - emojiSize.width, y: (frame.height/2) - (emojiSize.height * 0.5), width: emojiSize.width, height: emojiSize.height)
        
        like3Emoji.frame = CGRect(x: frame.width - emojiPadding - emojiSize.width, y: (frame.height/2) - (emojiSize.height * 1.5) - emojiPadding - 15, width: emojiSize.width, height: emojiSize.height)
        
        dislike2Emoji.frame = CGRect(x: emojiPadding, y: (frame.height/2) - (emojiSize.height * 0.5), width: emojiSize.width, height: emojiSize.height)
        addSubview(dislike2Emoji)
        
        backgroundRightView.frame.origin.x += emojiInitialOffset
        for image in [like1Emoji, like2Emoji, like3Emoji] {
            image.tintColor = UIColor(red: 166/255, green: 166/255, blue: 166/255, alpha: 0.8)
            image.frame.origin.x += emojiInitialOffset
            addSubview(image)
        }
        
        dislike2Emoji.alpha = emojiInitialAlpha
        dislike2Emoji.frame.origin.x -= emojiInitialOffset
        backgroundLeftView.frame.origin.x -= emojiInitialOffset
        
        hideView(state: true)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func hideView(state: Bool){
        for view in [backgroundLeftView, backgroundRightView, like1Emoji, like2Emoji, like3Emoji, dislike2Emoji] {
            view.isHidden = state
        }
    }
    
    var isLikeEmojisVisible = false
    var isDislikeEmojisVisible = false
    
    public func showEmoji(for option: CardOption) {
        hideView(state: false)
        if option == .like1 || option == .like2 || option == .like3 {
            
            if isDislikeEmojisVisible {
                hideDislikeEmojis()
            }
            
            if !isLikeEmojisVisible {
                showLikeEmojis()
            }
            
            for emoji in [like1Emoji, like2Emoji, like3Emoji] {
                emoji.image = emoji.image!.withRenderingMode(.alwaysTemplate)
                emoji.tintColor = UIColor(red: 166/255, green: 166/255, blue: 166/255, alpha: 0.8)
            }
            
            switch option {
            case .like1:
                like1Emoji.image = like1Emoji.image!.withRenderingMode(.alwaysOriginal)
            case .like2:
                like2Emoji.image = like2Emoji.image!.withRenderingMode(.alwaysOriginal)
            case .like3:
                like3Emoji.image = like3Emoji.image!.withRenderingMode(.alwaysOriginal)
            default:
                break
            }
            
        } else {
            if isLikeEmojisVisible {
                hideLikeEmojis()
            }
            
            if !isDislikeEmojisVisible {
                showDislikeEmojis()
            }
            
            dislike2Emoji.alpha = emojiInitialAlpha
            switch option {
            case .dislike2:
                dislike2Emoji.alpha = 1
            default:
                break
            }
        }
    }
    
    public func hideFaceEmojis() {
        hideView(state: true)
        if isLikeEmojisVisible {
            hideLikeEmojis()
        }
        if isDislikeEmojisVisible {
            hideDislikeEmojis()
        }
    }
    
    var isHidingLikeEmojis = false
    private func hideLikeEmojis() {
        if isHidingLikeEmojis { return }
        isHidingLikeEmojis = true
        UIView.animate(withDuration: 0.2, delay: 0.0, animations: {
            [self.like1Emoji, self.like2Emoji, self.like3Emoji].forEach {
                $0.frame.origin.x += self.emojiInitialOffset
            }
            self.backgroundRightView.frame.origin.x += 155
        }) { [weak self] (_) in
            self?.isHidingLikeEmojis = false
        }
        isLikeEmojisVisible = false
    }
    
    var isShowingLikeEmojis = false
    private func showLikeEmojis() {
        if isShowingLikeEmojis { return }
        isShowingLikeEmojis = true
        UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: [], animations: {
            [self.like1Emoji, self.like2Emoji, self.like3Emoji].forEach {
                $0.frame.origin.x -= self.emojiInitialOffset
            }
            self.backgroundRightView.frame.origin.x -= 155
        }) { [weak self] (_) in
            self?.isShowingLikeEmojis = false
        }
        isLikeEmojisVisible = true
    }
    
    var isHidingDislikeEmojis = false
    private func hideDislikeEmojis() {
        if isHidingDislikeEmojis { return }
        isHidingDislikeEmojis = true
        UIView.animate(withDuration: 0.2, delay: 0.0, animations: {
            self.dislike2Emoji.frame.origin.x -= self.emojiInitialOffset
            self.backgroundLeftView.frame.origin.x -= self.emojiInitialOffset
        }) { [weak self] (_) in
            self?.isHidingDislikeEmojis = false
        }
        isDislikeEmojisVisible = false
    }
    
    var isShowingDislikeEmojis = false
    private func showDislikeEmojis() {
        if isShowingDislikeEmojis { return }
        isShowingDislikeEmojis = true
        UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: [], animations: {
            self.dislike2Emoji.frame.origin.x += self.emojiInitialOffset
            self.backgroundLeftView.frame.origin.x += self.emojiInitialOffset
        }) { [weak self] (_) in
            self?.isShowingDislikeEmojis = false
        }
        isDislikeEmojisVisible = true
    }
}
