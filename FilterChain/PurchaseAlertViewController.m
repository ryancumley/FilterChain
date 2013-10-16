//
//  PurchaseAlertViewController.m
//  FilterChain
//
//  Created by Ryan Cumley on 10/6/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import "PurchaseAlertViewController.h"

@interface PurchaseAlertViewController ()

@end

@implementation PurchaseAlertViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _backgroundImageView.image = [UIImage imageNamed:@"PremiumTileSmall.png"];
    _seeThroughBackingView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.7];
    _headline.backgroundColor = [UIColor clearColor];
    _byline.backgroundColor = [UIColor clearColor];
    [_cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [_acceptButton setTitle:@"Buy" forState:UIControlStateNormal];
    [_restoreButton setTitle:@"Restore" forState:UIControlStateNormal];
    _acceptButton.hidden = YES;
    _restoreButton.hidden = YES;
    [_activityIndicator stopAnimating];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)loadMessagesOnlyWithHeadline:(NSString*)headline byline:(NSString*)byline {
    //used for basic alerts with no interactivity.
}

//passing nil to acceptTitle will hide the button. Passing any string will show it
- (void)loadHeadline:(NSString*)headline byline:(NSString*)byline cancelTitle:(NSString*)cancelTitle acceptTitle:(NSString*)acceptTitle restoreTitle:(NSString *)restoreTitle{
    _headline.text = headline;
    _byline.text = byline;
    [_cancelButton setTitle:cancelTitle forState:UIControlStateNormal];
    [_acceptButton setTitle:acceptTitle forState:UIControlStateNormal];
    [_restoreButton setTitle:restoreTitle forState:UIControlStateNormal];
    if (acceptTitle == nil) {
        _acceptButton.hidden = YES;
        _restoreButton.hidden = YES;
    }
    else {
        _acceptButton.hidden = NO;
        _restoreButton.hidden = NO;
    }
    
}

- (void)displayActivitySpinner {
    [_activityIndicator startAnimating];
}

- (void)hideActivitySpinner {
    [_activityIndicator stopAnimating];
}

- (void)userCancelled {
    [self.viewDelegate purchaseAlertViewIsResigning];
}

- (void)userAccepted {
    [self.actionDelegate purchaseAlertViewAccepted:YES withOptions:nil];
}

- (void)userRestored {
    [self.actionDelegate purchaseAlertViewRestored];
}

- (IBAction)pressedCancel:(id)sender {
    [self userCancelled];
}

- (IBAction)pressedAccept:(id)sender {
    [self userAccepted];
}

- (IBAction)pressedRestore:(id)sender {
    [self userRestored];
}


@end
