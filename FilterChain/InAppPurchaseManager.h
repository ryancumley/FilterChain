//
//  InAppPurchaseManager.h
//  FilterChain
//
//  Created by Ryan Cumley on 10/2/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

#define k_InAppPurchaseManagerProductsFetchedNotification @"k_InAppPurchaseManagerProductsFetchedNotification"

@interface InAppPurchaseManager : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

{
    SKProduct* premiumFiltersUpgrade;
    SKProductsRequest* productsRequest;
    BOOL productIsReachableAtApple;
}

@property (nonatomic, assign) id purchasePresentationDelegate;

- (void)loadStore;
- (void)launchInAppPurchaseDialog;
- (void)purchaseProUpgrade;


@end

@protocol InAppPurchasingDisplayManager <NSObject>

- (void)presentDetailsOfUpgrade:(NSString*)title description:(NSString*)description price:(NSDecimalNumber*)price;

@end
