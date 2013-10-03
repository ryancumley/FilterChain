//
//  InAppPurchaseManager.m
//  FilterChain
//
//  Created by Ryan Cumley on 10/2/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import "InAppPurchaseManager.h"

@implementation InAppPurchaseManager

- (void)requestPremiumFiltersUpgradeProductData {
    NSSet *productIdentifiers = [NSSet setWithObject:@"FCPU_001" ];
    productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    productsRequest.delegate = self;
    [productsRequest start];
}

#pragma mark - 
#pragma mark SKProductsRequestDelegate Methods

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    NSArray *products = response.products;
    premiumFiltersUpgrade = [products count] == 1 ? [products firstObject] : nil;
    if (premiumFiltersUpgrade)
    {
        NSLog(@"Product title: %@" , premiumFiltersUpgrade.localizedTitle);
        NSLog(@"Product description: %@" , premiumFiltersUpgrade.localizedDescription);
        NSLog(@"Product price: %@" , premiumFiltersUpgrade.price);
        NSLog(@"Product id: %@" , premiumFiltersUpgrade.productIdentifier);
    }
    
    for (NSString *invalidProductId in response.invalidProductIdentifiers)
    {
        NSLog(@"Invalid product id: %@" , invalidProductId);
    }
}

#pragma mark - 
#pragma mark SKPaymentTransactionObserverDelegate Methods

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    
}



@end
