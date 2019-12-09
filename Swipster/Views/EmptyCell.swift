//
//  EmptyCell.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 07/06/2018.
//  Copyright © 2018 Swipster Inc. All rights reserved.
//

import UIKit

class EmptyCell: UIView {

    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder : aDecoder)
        commonInit()
    }

    private func commonInit(){
        Bundle.main.loadNibNamed("EmptyCell", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
}
