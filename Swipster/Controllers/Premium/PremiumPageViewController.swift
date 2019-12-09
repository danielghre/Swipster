//
//  PremiumPageViewController.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 07/02/2019.
//  Copyright © 2019 Swipster Inc. All rights reserved.
//

import UIKit

protocol PremiumPageViewControllerDelegate: class {
    func didUpdatePageIndex(currentIndex: Int)
}

class PremiumPageViewController: UIPageViewController {
    
    weak var premiumDelegate: PremiumPageViewControllerDelegate?
    
    var pageHeadings = ["Finis les publicités", "Distinguez vous", "Augmentez vos chances"]
    var pageImages = ["blockAds", "morePics", "distance"]
    var pageSubHeadings = ["Profitez d'une experience absolue sans être géné par la publicité !", "Vous pourrez ajouter jusqu'à 3 photos supplémentaires à votre profil !", "Aucune limite de distance ne vous arrêtera !"]
    
    var currentIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        delegate = self
        
        if let startingViewController = contentViewController(at: 0) {
            setViewControllers([startingViewController], direction: .forward, animated: true)
        }
    }
    
    func contentViewController(at index: Int) -> PremiumContentViewController? {
        if index < 0 || index >= pageHeadings.count {
            return nil
        }
        
        let storyboard = UIStoryboard(name: "Premium", bundle: nil)
        if let pageContentViewController = storyboard.instantiateViewController(withIdentifier: "PremiumContentViewController") as? PremiumContentViewController {
            pageContentViewController.imageFile = pageImages[index]
            pageContentViewController.headingText = pageHeadings[index]
            pageContentViewController.subHeading = pageSubHeadings[index]
            pageContentViewController.index = index
            
            return pageContentViewController
        }
        
        return nil
    }
    
    func forwardPage() {
        currentIndex += 1
        if let nextViewController = contentViewController(at: currentIndex) {
            setViewControllers([nextViewController], direction: .forward, animated: true)
        }
    }
}

extension PremiumPageViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        var index = (viewController as! PremiumContentViewController).index
        index -= 1
        
        return contentViewController(at: index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        var index = (viewController as! PremiumContentViewController).index
        index += 1
        
        return contentViewController(at: index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            if let contentViewController = pageViewController.viewControllers?.first as? PremiumContentViewController {
                currentIndex = contentViewController.index
                
                premiumDelegate?.didUpdatePageIndex(currentIndex: currentIndex)
            }
        }
    }
}
