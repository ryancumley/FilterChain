//
//  InAppPurchaseManager.m
//  FilterChain
//
//  Created by Ryan Cumley on 10/2/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import "InAppPurchaseManager.h"

#define k_InAppPurchaseProUpgradeProductId @"FCPU_001"
#define k_InAppPurchaseManagerTransactionFailedNotification @"k_InAppPurchaseManagerTransactionFailedNotification"
#define k_InAppPurchaseManagerTransactionSucceededNotification @"k_InAppPurchaseManagerTransactionSucceededNotification"
#define k_upgradePurchased @"upgradePurchased"


@implementation InAppPurchaseManager

- (void)loadStore
{
    // restarts any purchases if they were interrupted last time the app was open
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    productIsReachableAtApple = NO;
}

- (void)launchInAppPurchaseDialog {
       
    // get the product description and set the productIsReachableAtApple flag
    [self requestPremiumFiltersUpgradeProductData];
    
}

- (void)requestPremiumFiltersUpgradeProductData {
    NSSet *productIdentifiers = [NSSet setWithObject:k_InAppPurchaseProUpgradeProductId];
    productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    productsRequest.delegate = self;
    [productsRequest start]; //Apple will return asynchronously with the productsRequest: didRecieveResponse: delegate call, which will itself tell mvc to display the alertView dialog
}


- (BOOL)canMakePayments
{
    return [SKPaymentQueue canMakePayments];
}

- (void)purchaseProUpgrade
{
    //Verify that the user has permission to make purchases
    BOOL allowed = [self canMakePayments];
    if (!allowed) {
        //Alert view with message
        NSString* notAllowedMessage = @"Error: You do not have Permission to make Purchases";
        NSString* explanation = @"Disable the 'download new apps' restriction in your device's settings to proceed";
        UIAlertView* cantPayAlert = [[UIAlertView alloc] initWithTitle:notAllowedMessage message:explanation delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil];
        [cantPayAlert show];
        return;
    }
    
    //We verified the availability of the product with Apple when we originally loaded the store
    //Inform and fail if the product is unreachable for some reason
    if (!productIsReachableAtApple) {
        //Alert view with message
        NSString *notAvaialbleMessage = @"Error: The upgrade is not reachable on the AppStore right now";
        NSString *explanation = @"Try again in a few minutes, and if it's still not working, send us an e-mail to let us know the upgrade is down. ryan@ryancumley.com";
        UIAlertView* notAvailable = [[UIAlertView alloc] initWithTitle:notAvaialbleMessage message:explanation delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil];
        [notAvailable show];
        return;
    }
    
    //User has permission to buy, and the product is ready at Apple. Let's make some money
    SKPayment *payment = [SKPayment paymentWithProduct:premiumFiltersUpgrade];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

#pragma -
#pragma Purchase helpers

- (void)recordTransaction:(SKPaymentTransaction *)transaction
{
    if ([transaction.payment.productIdentifier isEqualToString:k_InAppPurchaseProUpgradeProductId])
    {
        // save the transaction receipt to disk
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"proUpgradeReciept":transaction.transactionReceipt}];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)provideContent:(NSString *)productId
{
    if ([productId isEqualToString:k_InAppPurchaseProUpgradeProductId])
    {
        // enable the pro features
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:k_upgradePurchased];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)finishTransaction:(SKPaymentTransaction *)transaction wasSuccessful:(BOOL)wasSuccessful
{
    // remove the transaction from the payment queue.
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:transaction, @"transaction" , nil];
    if (wasSuccessful)
    {
        // send out a notification that we’ve finished the transaction
        [[NSNotificationCenter defaultCenter] postNotificationName:k_InAppPurchaseManagerTransactionSucceededNotification object:self userInfo:userInfo];
    }
    else
    {
        // send out a notification for the failed transaction
        [[NSNotificationCenter defaultCenter] postNotificationName:k_InAppPurchaseManagerTransactionFailedNotification object:self userInfo:userInfo];
    }
}

// called when a transaction is pending with Apple. Not clear if I need to do anything with this, as the queue should update and post a complete, or failed message when it does
// for now, I'll just post a helpful message to the user
- (void)completingTransaction:(SKPaymentTransaction*)transaction {
    
}

- (void)completeTransaction:(SKPaymentTransaction*)transaction
{
    [self recordTransaction:transaction];
    [self provideContent:transaction.payment.productIdentifier];
    [self finishTransaction:transaction wasSuccessful:YES];
}

// called when a transaction has been restored and and successfully completed
- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{
    [self recordTransaction:transaction.originalTransaction];
    [self provideContent:transaction.originalTransaction.payment.productIdentifier];
    [self finishTransaction:transaction wasSuccessful:YES];
}

// called when a transaction has failed
- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        // error!
        [self finishTransaction:transaction wasSuccessful:NO];
    }
    else
    {
        // this is fine, the user just cancelled, so don’t notify
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }
}

#pragma mark - 
#pragma mark SKProductsRequestDelegate Methods

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    NSArray *products = response.products;
    premiumFiltersUpgrade = [products count] == 1 ? [products firstObject] : nil;
    if (premiumFiltersUpgrade)
    {
        productIsReachableAtApple = YES;
        [self.purchasePresentationDelegate presentDetailsOfUpgrade:premiumFiltersUpgrade.localizedTitle description:premiumFiltersUpgrade.localizedDescription price:premiumFiltersUpgrade.price];
        /*
        NSLog(@"Product title: %@" , premiumFiltersUpgrade.localizedTitle);
        NSLog(@"Product description: %@" , premiumFiltersUpgrade.localizedDescription);
        NSLog(@"Product price: %@" , premiumFiltersUpgrade.price);
        NSLog(@"Product id: %@" , premiumFiltersUpgrade.productIdentifier);
         */
    }
    
    for (NSString *invalidProductId in response.invalidProductIdentifiers)
    {
        NSLog(@"Invalid product id: %@" , invalidProductId);
        productIsReachableAtApple = NO;
    }
}

#pragma mark - 
#pragma mark SKPaymentTransactionObserverDelegate Methods

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchasing:
                [self completingTransaction:transaction];
                break;
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
                break;
            default:
                break;
        }
    }
}

- (void) paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray *)downloads {
    //At the moment, we don't download any content with the purchase. This method is required for this protocol however, so I'm implementing it here.
    return;
}



@end
