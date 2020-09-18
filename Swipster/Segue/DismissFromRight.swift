//
//  DismissFromRight.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 09/03/2020.
//  Copyright © 2020 Swipster Inc. All rights reserved.
//

import UIKit

class DismissFromRight: UIStoryboardSegue {
    
    override func perform() {
        let src = source
        let transition: CATransition = CATransition()
        transition.duration = 0.25
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.type = CATransitionType.moveIn
        transition.subtype = CATransitionSubtype.fromRight
        src.view.window!.layer.add(transition, forKey: nil)
        src.dismiss(animated: false, completion: nil)
    }
}
