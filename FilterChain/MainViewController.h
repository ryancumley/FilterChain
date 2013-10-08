//
//  MainViewController.h
//  FilterChain
//
//  Created by Ryan Cumley on 9/6/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "RecordingManager.h"
#import "ClipManager.h"
#import "FilterBank.h"
#import "GPUImage.h"
#import "ActiveFilterManager.h"
#import "InAppPurchaseManager.h"
#import "PurchaseAlertViewController.h"

@interface MainViewController : UIViewController <ActiveFilterToMVC, UIAlertViewDelegate, FilterBankToMVC, RecordingManagerToMVC, PurchaseAlertViewDelegate>
{
    CGRect filterBankFrame;
    CGRect collectionShellFrame;
    BOOL clipCollectionIsVisible;
    BOOL orientationChangedDuringPlayback;
    int timeSec;
    int timeMin;
    NSTimer *timer;
    UIView* purchaseAlertView;
    UIView* blockingView;
    BOOL purchaseAlertViewIsShowing;
}

@property (strong, nonatomic) InAppPurchaseManager* purchaseManager;
@property (strong, nonatomic) ClipManager* clipManager;
@property (strong, nonatomic) RecordingManager* recordingManager;
@property (strong, nonatomic) FilterBank* filterBank;
@property (strong, nonatomic) ActiveFilterManager* activeFilterManager;
@property (strong, nonatomic) IBOutlet GPUImageView* previewLayer;

@property (strong, nonatomic) IBOutlet UIView* clipManagerView;
@property (strong, nonatomic) IBOutlet UIView* collectionShell;
@property (strong, nonatomic) IBOutlet UIView* controlBoxView;
@property (strong, nonatomic) IBOutlet UIView* blinkyRedLight;
@property (strong, nonatomic) IBOutlet UIView* recordingNotifier;
@property (strong, nonatomic) IBOutlet UILabel* notifierLabel;
@property (strong, nonatomic) IBOutlet UISlider* globalBlend;
@property (strong, nonatomic) IBOutlet UILabel* recordingTimer;
@property (strong, nonatomic) IBOutlet UIButton* micWarning;

- (IBAction)navigateToClips:(id)sender;
- (IBAction)navigateToCamera:(id)sender;
- (IBAction)userPressedRecord:(UIButton *)sender;
- (IBAction)pressedMicWarning:(id)sender;

- (void)previewClipForUrl:(NSURL *)targetUrl;
- (void)awakeVideoCamera;
- (void)hideRecordingNotifier;
- (void)stopTimer;

@end
