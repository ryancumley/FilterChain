//
//  PurchaseAlertViewController.h
//  FilterChain
//
//  Created by Ryan Cumley on 10/6/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PurchaseAlertViewController : UIViewController


@property (strong, nonatomic) IBOutlet UIImageView* backgroundImageView;
@property (strong, nonatomic) IBOutlet UIView* seeThroughBackingView;
@property (strong, nonatomic) IBOutlet UILabel* headline;
@property (strong, nonatomic) IBOutlet UILabel* byline;
@property (strong, nonatomic) IBOutlet UIButton* cancelButton;
@property (strong, nonatomic) IBOutlet UIButton* acceptButton;
@property (strong, nonatomic) IBOutlet UIView* activitySpinnerView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView* activityIndicator;

@property (nonatomic, assign) id viewDelegate;
@property (nonatomic, assign) id actionDelegate;

- (void)loadMessagesOnlyWithHeadline:(NSString*)headline byline:(NSString*)byline;
- (void)loadHeadline:(NSString*)headline byline:(NSString*)byline cancelTitle:(NSString*)cancelTitle acceptTitle:(NSString*)acceptTitle;
- (void)displayActivitySpinner;
- (void)hideActivitySpinner;
- (void)userCancelled;
- (void)userAccepted;

@end

@protocol PurchaseAlertViewDelegate <NSObject>

- (void)purchaseAlertViewIsTakingOverWithView:(UIView*)view;
- (void)purchaseAlertViewIsResigning;

@end

@protocol PurchaseAlertViewActionDelegate <NSObject>

- (void)purchaseAlertViewAccepted:(BOOL)accepted withOptions:(NSDictionary*)options;

@end
