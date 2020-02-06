//
//  LoadingPulse.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 19/11/2019.
//  Copyright © 2019 Swipster Inc. All rights reserved.
//

import UIKit

class LoadingPulse {
    
    lazy var pulseArray = [CAShapeLayer]()
    
    func animatePulsatingLayerAt(index:Int) {
        pulseArray[index].strokeColor = UIColor(white: 1, alpha: 0.4).cgColor
        pulseArray[index].fillColor = UIColor(white: 1, alpha: 0.4).cgColor
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 0.0
        scaleAnimation.toValue = 0.9
        
        let opacityAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        opacityAnimation.fromValue = 0.9
        opacityAnimation.toValue = 0.0

        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [scaleAnimation, opacityAnimation]
        groupAnimation.duration = 2
        groupAnimation.repeatCount = .greatestFiniteMagnitude
        groupAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        pulseArray[index].add(groupAnimation, forKey: "groupanimation")
    }
    
    func stopPulse() {
        for i in 0...1 {
            pulseArray[i].removeFromSuperlayer()
        }
    }
    
    func createPulse(view: UIView) {
        let circularPath = UIBezierPath(arcCenter: .zero, radius: UIScreen.main.bounds.size.width/2.0, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        for _ in 0...1 {
            let pulseLayer = CAShapeLayer()
            pulseLayer.path = circularPath.cgPath
            pulseLayer.lineWidth = 3.0
            pulseLayer.fillColor = UIColor.clear.cgColor
            pulseLayer.lineCap = CAShapeLayerLineCap.round
            pulseLayer.position = CGPoint(x: view.frame.size.width/2.0, y: view.frame.size.height/2.0)
            view.layer.addSublayer(pulseLayer)
            pulseArray.append(pulseLayer)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            self.animatePulsatingLayerAt(index: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
                self.animatePulsatingLayerAt(index: 1)
            })
        })
    }
}
