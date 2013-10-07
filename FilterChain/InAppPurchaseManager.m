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

@synthesize purchaseAlertViewController = _purchaseAlertViewController;

- (void)loadStore
{
    // restarts any purchases if they were interrupted last time the app was open
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    productIsReachableAtApple = NO;
    
}

- (void)launchInAppPurchaseDialog {
    _purchaseAlertViewController = [[PurchaseAlertViewController alloc] initWithNibName:@"PurchaseAlertView" bundle:[NSBundle mainBundle]];
    [_purchaseAlertViewController setViewDelegate:[[[[UIApplication sharedApplication] delegate] window] rootViewController]];
    [_purchaseAlertViewController setActionDelegate:self];
    [_purchaseAlertViewController.viewDelegate purchaseAlertViewIsTakingOverWithView:_purchaseAlertViewController.view];
    [_purchaseAlertViewController loadHeadline:@"Enable Premium Filters" byline:@"Conacting Apple's AppStore" cancelTitle:@"Cancel" acceptTitle:nil];
    [_purchaseAlertViewController displayActivitySpinner];
    
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
        NSString* explanation = @"Enable \"In-App Purchases\" from the Restrictions to proceed";
        [_purchaseAlertViewController loadHeadline:notAllowedMessage byline:explanation cancelTitle:@"Dismiss" acceptTitle:nil];
        return;
    }
    
    //We verified the availability of the product with Apple when we originally loaded the store
    //Inform and fail if the product is unreachable for some reason
    if (!productIsReachableAtApple) {
        //Alert view with message
        NSString *notAvaialbleMessage = @"Error: The AppStore is not reachable right now";
        NSString *explanation = @"Make sure you're connected to the internet! Otherwise, try again in a few minutes";
        [_purchaseAlertViewController loadHeadline:notAvaialbleMessage byline:explanation cancelTitle:@"Dismiss" acceptTitle:nil];
        return;
    }
    
    //User has permission to buy, and the product is ready at Apple. Let's make some money
    SKPayment *payment = [SKPayment paymentWithProduct:premiumFiltersUpgrade];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    [_purchaseAlertViewController displayActivitySpinner];
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
        // send out a notification that we’ve finished the transaction. FilterBank is listening and will call "reloadData" accordingly
        [[NSNotificationCenter defaultCenter] postNotificationName:k_InAppPurchaseManagerTransactionSucceededNotification object:self userInfo:userInfo];
    }
    else
    {
        // send out a notification for the failed transaction. Nobody is listening right now, but perhaps in a later version???
        [[NSNotificationCenter defaultCenter] postNotificationName:k_InAppPurchaseManagerTransactionFailedNotification object:self userInfo:userInfo];
    }
}

// called when a transaction is pending with Apple. Not clear if I need to do anything with this, as the queue should update and post a complete, or failed message when it does
- (void)completingTransaction:(SKPaymentTransaction*)transaction {
    
}

- (void)completeTransaction:(SKPaymentTransaction*)transaction
{
    [self recordTransaction:transaction];
    [self provideContent:transaction.payment.productIdentifier];
    [self finishTransaction:transaction wasSuccessful:YES];
    [_purchaseAlertViewController.viewDelegate purchaseAlertViewIsResigning];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{
    [self recordTransaction:transaction.originalTransaction];
    [self provideContent:transaction.originalTransaction.payment.productIdentifier];
    [self finishTransaction:transaction wasSuccessful:YES];
    [_purchaseAlertViewController.viewDelegate purchaseAlertViewIsResigning];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        // error!
        NSString* error = transaction.error.localizedDescription;
        [_purchaseAlertViewController loadHeadline:error byline:@"" cancelTitle:@"Dismiss" acceptTitle:nil];
        [self finishTransaction:transaction wasSuccessful:NO];
    }
    else
    {
        // this is fine, the user just cancelled, so don’t notify
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        [_purchaseAlertViewController.viewDelegate purchaseAlertViewIsResigning];
    }
}




#pragma mark - 
#pragma mark SKProductsRequestDelegate Methods

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    [_purchaseAlertViewController hideActivitySpinner];
    NSArray *products = response.products;
    premiumFiltersUpgrade = [products count] == 1 ? [products firstObject] : nil;
    if (premiumFiltersUpgrade)
    {
        productIsReachableAtApple = YES;
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [numberFormatter setLocale:premiumFiltersUpgrade.priceLocale];
        NSString *formattedPrice= [numberFormatter stringFromNumber:premiumFiltersUpgrade.price];
        NSString* headline = [NSString stringWithFormat:@"Unlock Premium Filters for %@",formattedPrice];
        NSString* byline = @"Activate additional filters. Available for use immediately";
        [_purchaseAlertViewController loadHeadline:headline byline:byline cancelTitle:@"Cancel" acceptTitle:@"Buy Now"];
    }
    
    for (NSString *invalidProductId in response.invalidProductIdentifiers)
    {
        productIsReachableAtApple = NO;
    }
}





#pragma mark - 
#pragma mark SKPaymentTransactionObserverDelegate Methods

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    [_purchaseAlertViewController hideActivitySpinner];
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




#pragma mark -
#pragma mark PurchaseAlertViewActionDelegate Protocol

- (void)purchaseAlertViewAccepted:(BOOL)accepted withOptions:(NSDictionary*)options {
    [self purchaseProUpgrade];
}

@end
