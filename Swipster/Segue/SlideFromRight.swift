//
//  AppDelegate.swift
//  Swipy
//
//  Created by Daniel Ghrenassia on 22/03/2018.
//  Copyright © 2018 Daniel Ghrenassia Team. All rights reserved.
//

import UIKit

class SlideFromRight: UIStoryboardSegue {
    
    override func perform() {
        let src = source
        let dst = destination
        
        dst.modalPresentationStyle = .fullScreen
        src.view.superview?.insertSubview(dst.view, aboveSubview: src.view)
        dst.view.transform = CGAffineTransform(translationX: src.view.frame.size.width*2, y: 0)
        UIView.animate(withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            dst.view.transform = CGAffineTransform(translationX: 0, y: 0)
        }) { (finished) in
            src.modalPresentationStyle = .fullScreen
            src.present(dst, animated: false)
        }
    }
}
