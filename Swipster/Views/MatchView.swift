//
//  MatchView.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 08/04/2018.
//  Copyright © 2018 Swipster Inc. All rights reserved.
//

import UIKit

class MatchView: UIView {

    @IBOutlet private var contentView: UIView!
    @IBOutlet weak var myPic: UIImageView!
    @IBOutlet weak var matchPic: UIImageView!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var swiper: UIImageView!
    @IBOutlet private weak var gradientView: GradientView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder : aDecoder)
        commonInit()
    }
    
    private func commonInit(){
        let opacity:CGFloat = 1
        let borderColor = UIColor(rgb: 0x8E147D)
        
        Bundle.main.loadNibNamed("MatchView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        swiper.tintColor = UIColor.white
        gradientView.layer.borderWidth = 4
        gradientView.layer.borderColor = UIColor.white.withAlphaComponent(0.75).cgColor
        matchPic.setRounded()
        matchPic.layer.borderColor = borderColor.withAlphaComponent(opacity).cgColor
        matchPic.clipsToBounds = true
        matchPic.layer.borderWidth = 4.5
        myPic.setRounded()
        myPic.layer.borderColor = borderColor.withAlphaComponent(opacity).cgColor
        myPic.clipsToBounds = true
        myPic.layer.borderWidth = 4.5
        okButton.layer.borderWidth = 3
        okButton.layer.cornerRadius = 20
        okButton.layer.borderColor = borderColor.withAlphaComponent(opacity).cgColor
        
    }
    
}
