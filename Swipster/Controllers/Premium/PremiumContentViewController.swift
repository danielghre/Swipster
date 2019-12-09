//
//  PremiumContentViewController.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 07/02/2019.
//  Copyright © 2019 Swipster Inc. All rights reserved.
//

import UIKit

class PremiumContentViewController: UIViewController {

    @IBOutlet weak var heading: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    
    var index = 0
    var headingText = ""
    var subHeading = ""
    var imageFile = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        heading.text = headingText
        textView.text = subHeading
        imageView.image = UIImage(named: imageFile)
    }
}
