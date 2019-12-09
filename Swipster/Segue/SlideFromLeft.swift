//
//  AppDelegate.swift
//  Swipy
//
//  Created by Daniel Ghrenassia on 22/03/2018.
//  Copyright © 2018 Daniel Ghrenassia Team. All rights reserved.
//

import UIKit

class SlideFromLeft: UIStoryboardSegue {
    
    override func perform() {
        let src = source
        let dst = destination
        
        src.view.superview?.insertSubview(dst.view, aboveSubview: src.view)
        dst.modalPresentationStyle = .fullScreen
        dst.view.transform = CGAffineTransform(translationX: -src.view.frame.size.width, y: 0)
        UIView.animate(withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            dst.view.transform = CGAffineTransform(translationX: 0, y: 0)
        }) { (finished) in
            src.modalPresentationStyle = .fullScreen
            src.present(dst, animated: false)
        }
    }
}
