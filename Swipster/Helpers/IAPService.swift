//
//  IAPService.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 14/12/2018.
//  Copyright © 2018 Swipy Inc. All rights reserved.
//

import StoreKit
import SwiftEntryKit
import Firebase
import FirebaseDatabase

enum IAPProduct: String {
    case nonConsumable = "com.swipsterinc.swipster.removeads"
    case oneMonthSubscription = "com.swipsterinc.swipster.onemonthsubscription"
//    case sixMonthsSubscription = "com.swipsterinc.swipster.sixmonthssubscription"
//    case oneyearSubscription = "com.swipsterinc.swipster.oneyearsubscription"
}

class IAPService: NSObject {
    
    private override init() {}
    static let shared = IAPService()
    
    var products = [SKProduct]()
    let paymentQueue = SKPaymentQueue.default()
    
    func getProducts(){
        
        let products: Set = [IAPProduct.nonConsumable.rawValue,
                             IAPProduct.oneMonthSubscription.rawValue]
        let request = SKProductsRequest(productIdentifiers: products)
        request.delegate = self
        request.start()
        paymentQueue.add(self)
    }
    
    func purshase(product: IAPProduct){
        if (SKPaymentQueue.canMakePayments()) {
            showLoadingView(text: "Veuillez patienter...")
            guard let productToPurshase = products.filter({ $0.productIdentifier == product.rawValue}).first else { return }
            let payment = SKPayment(product: productToPurshase)
            paymentQueue.add(payment)
        }else {
            showPopupMessage(title: "Impossible !", buttonTitle: "Compris !", description: "Veuillez autoriser les achats intégrés !", image: #imageLiteral(resourceName: "ic_error_all_light_48pt")) {
                SwiftEntryKit.dismiss()
            }
        }
    }
    
    func restorePurshases() {
        showLoadingView(text: "Veuillez patienter...")
        paymentQueue.restoreCompletedTransactions()
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue) {
        for transaction in queue.transactions {
            let t: SKPaymentTransaction = transaction
            let prodID = t.payment.productIdentifier as String
            if prodID == "com.swipsterinc.swipster.removeads" {
                queue.finishTransaction(t)
                savePurshased()
                SwiftEntryKit.dismiss(.all)
                showPopupMessage(title: "Récupération réussis !", buttonTitle: "Compris !", description: "Vous n'aurez plus de publicité sur l'application",image: #imageLiteral(resourceName: "ic_done_all_light_48pt")) {
                    SwiftEntryKit.dismiss()
                }
            }
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        SwiftEntryKit.dismiss(.all)
        print(error.localizedDescription)
        showPopupMessage(title: "Impossible !", buttonTitle: "Compris !", description: "Une erreur est survenu, veuillez réessayez plus tard !", image: #imageLiteral(resourceName: "ic_error_all_light_48pt")) {
            SwiftEntryKit.dismiss()
        }
    }
}

extension IAPService: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = response.products
    }
}

extension IAPService: SKPaymentTransactionObserver {
    
    func savePurshased(){
        let save = UserDefaults.standard
        save.set(true, forKey: "Purchased")
        save.synchronize()
        let ref = Database.database().reference()
        let uid = Auth.auth().currentUser?.uid
        let usersReference = ref.child("users").child(uid!)
        
        let values = ["purchased": true]
        
        usersReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if err != nil {
                print(err ?? "")
                return
            }
        })
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions{
            switch transaction.transactionState.status() {
            case "purchased":
                savePurshased()
                paymentQueue.finishTransaction(transaction)
                SwiftEntryKit.dismiss(.all)
                showPopupMessage(title: "Merci !", buttonTitle: "Compris !", description: "Votre achat a bien été effectué !", image: #imageLiteral(resourceName: "ic_done_all_light_48pt")) {
                    SwiftEntryKit.dismiss()
                }
                break
            case "failed":
                paymentQueue.finishTransaction(transaction)
                SwiftEntryKit.dismiss(.all)
                showPopupMessage(title: "Impossible !", buttonTitle: "Compris !", description: "L'achat a été abandonné !", image: #imageLiteral(resourceName: "ic_error_all_light_48pt")) {
                    SwiftEntryKit.dismiss()
                }
                break
            case "deferred":
                SwiftEntryKit.dismiss(.all)
                break
            case "restored":
                paymentQueue.finishTransaction(transaction)
                savePurshased()
                SwiftEntryKit.dismiss(.all)
                showPopupMessage(title: "Récupération réussis !", buttonTitle: "Compris !", description: "Vous n'aurez plus de publicité sur l'application", image: #imageLiteral(resourceName: "ic_done_all_light_48pt")) {
                    SwiftEntryKit.dismiss()
                }
                break
            default:
                break
            }
            
        }
    }
}

extension SKPaymentTransactionState {
    func status() -> String{
        switch self {
        case .deferred: return "deferred"
        case .failed: return "failed"
        case .purchased: return "purchased"
        case .purchasing: return "purchasing"
        case .restored: return "restored"
        @unknown default:
            fatalError()
        }
    }
}
