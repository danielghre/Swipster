//
//  PremiumViewController.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 01/02/2019.
//  Copyright © 2019 Swipster Inc. All rights reserved.
//

import UIKit

class PremiumViewController: UIViewController, PremiumPageViewControllerDelegate {
    
    @IBAction func closeButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func laterButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func subscibe(_ sender: Any) {
        switch subscriptionLenght {
        case 1:
            print("subscribe for \(subscriptionLenght) months")
            IAPService.shared.purshase(product: .oneMonthSubscription)
        case 6:
            print("subscribe for \(subscriptionLenght) months")
        case 12:
            print("subscribe for \(subscriptionLenght) months")
        default:
            break
        }
    }
    
    var subscriptionLenght = 6
    
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var oneMonth: UIView!
    @IBOutlet weak var sixMonths: UIView!
    @IBOutlet weak var oneYear: UIView!
    
    var premiumPageViewController:  PremiumPageViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGestureRecognizerOneMonth = UITapGestureRecognizer(target: self, action: #selector(handleSelectViewForOneMonth))
        oneMonth.addGestureRecognizer(tapGestureRecognizerOneMonth)
        let tapGestureRecognizerSixMonth = UITapGestureRecognizer(target: self, action: #selector(handleSelectViewForSixMonth))
        sixMonths.addGestureRecognizer(tapGestureRecognizerSixMonth)
        let tapGestureRecognizerOneyear = UITapGestureRecognizer(target: self, action: #selector(handleSelectViewForOneYear))
        oneYear.addGestureRecognizer(tapGestureRecognizerOneyear)
    }
    
    @objc func handleSelectViewForOneMonth(){
        subscriptionLenght = 1
        oneMonth.layer.borderWidth = 6
        sixMonths.layer.borderWidth = 2
        oneYear.layer.borderWidth = 2
    }
    
    @objc func handleSelectViewForSixMonth(){
        subscriptionLenght = 6
        sixMonths.layer.borderWidth = 6
        oneMonth.layer.borderWidth = 2
        oneYear.layer.borderWidth = 2
    }
    
    @objc func handleSelectViewForOneYear(){
        subscriptionLenght = 12
        oneYear.layer.borderWidth = 6
        oneMonth.layer.borderWidth = 2
        sixMonths.layer.borderWidth = 2
    }
    
    func didUpdatePageIndex(currentIndex: Int) {
        updateUI()
    }
    
    func updateUI() {
        if let index = premiumPageViewController?.currentIndex {
            pageControl.currentPage = index
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination
        if let pageViewController = destination as? PremiumPageViewController {
            premiumPageViewController = pageViewController
            premiumPageViewController?.premiumDelegate = self
        }
    }
}
