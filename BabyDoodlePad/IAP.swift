//
//  IAP.swift
//  BabyDoodlePad
//
//  Created by tai chen on 28/11/2018.
//  Copyright © 2018 TPBSoftware. All rights reserved.
//

import UIKit
import StoreKit

protocol IAPDelegate {
    func purchaseSuccess()
    func restoreSuccess()
}

class IAP : NSObject {
    
    var iapDelegate : IAPDelegate!
    static let instance = IAP()
    
    let upgradeID = "com.TPBSoftware.BabyDoodlePad.upgrade"
    var products = [SKProduct]()
    
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    func fetchProducts() {
        if products.count > 0 {
            return
        }
        let productIDs = Set([upgradeID])
        let request = SKProductsRequest(productIdentifiers: productIDs)
        request.delegate = self
        request.start()
    }
    
    func purchase() {
        if products.count > 0 {
            print("PURCHASE...")
            let payment = SKPayment(product: products[0])
            SKPaymentQueue.default().add(payment)
        }else{
            print("no such product")
        }
        
    }
    
    func restorePurchases() {
        print("restore purchasees")
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func canMakePayment() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
}


extension IAP : SKProductsRequestDelegate, SKPaymentTransactionObserver {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        for product in response.products {
            print("add product: \(product.localizedTitle)")
            products.append(product)
            break
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                print("PURCHASED \(transaction)")
                SKPaymentQueue.default().finishTransaction(transaction)
                UserDefaults.standard.set(true, forKey: "upgrade")
                iapDelegate.purchaseSuccess()
                print("set true for upgrade")
                break
            case .failed:
                print("FAILED \(transaction)")
                SKPaymentQueue.default().finishTransaction(transaction)
                break
            default:
                break
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        //     print("restore completed")
        for transaction in queue.transactions {
            switch transaction.transactionState {
            case .purchased:
                print("PURCHASED \(transaction)")
                SKPaymentQueue.default().finishTransaction(transaction)
                UserDefaults.standard.set(true, forKey: "upgrade")
                iapDelegate.purchaseSuccess()
                break
            case .failed:
                print("FAILED \(transaction)")
                SKPaymentQueue.default().finishTransaction(transaction)
                break
            case .restored:
                print("RESTORED \(transaction.payment.productIdentifier)")
                UserDefaults.standard.set(true, forKey: "upgrade")
                iapDelegate.purchaseSuccess()
                //        print("set true for upgrade - show alert!")
           //     iapDelegate.restoreSuccessAlert()
                break
            default:
                break
            }
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}
