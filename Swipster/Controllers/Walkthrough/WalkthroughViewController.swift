//
//  WalkthroughViewController.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 16/12/2018.
//  Copyright © 2018 Swipy Inc. All rights reserved.
//

import UIKit

class WalkthroughViewController: UIViewController, WalkthroughPageViewControllerDelegate {
    
    @IBOutlet var pageControl: UIPageControl!
    
    @IBOutlet var nextButton: UIButton! {
        didSet {
            nextButton.layer.cornerRadius = 25.0
            nextButton.layer.masksToBounds = true
        }
    }
    
    @IBOutlet var skipButton: UIButton!
    
    var walkthroughPageViewController: WalkthroughPageViewController?
    
    @IBAction func skipButtonTapped(sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func nextButtonTapped(sender: UIButton) {
        nextButton.pulsate()
        if let index = walkthroughPageViewController?.currentIndex {
            switch index {
            case 0...2:
                walkthroughPageViewController?.forwardPage()
                
            case 3:
                dismiss(animated: true)
                
            default: break
            }
        }
        
        updateUI()
    }
    
    func updateUI() {
        if let index = walkthroughPageViewController?.currentIndex {
            switch index {
            case 0...2:
                nextButton.setTitle("SUIVANT", for: .normal)
                skipButton.isHidden = false
                
            case 3:
                nextButton.setTitle("Compris !", for: .normal)
                skipButton.isHidden = true
                
            default:
                break
            }
            
            pageControl.currentPage = index
        }
    }
    
    func didUpdatePageIndex(currentIndex: Int) {
        updateUI()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination
        if let pageViewController = destination as? WalkthroughPageViewController {
            walkthroughPageViewController = pageViewController
            walkthroughPageViewController?.walkthroughDelegate = self
        }
    }
    
    
}
