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
#import "ControlBoxManager.h"
#import "FilterBank.h"
#import "GPUImage.h"
#import "ActiveFilterManager.h"
#import "InAppPurchaseManager.h"

@interface MainViewController : UIViewController <ActiveFilterToMVC, InAppPurchasingDisplayManager, UIAlertViewDelegate, FilterBankToMVC>
{
    CGRect filterBankFrame;
    CGRect collectionShellFrame;
    BOOL clipCollectionIsVisible;
    BOOL orientationChangedDuringPlayback;
}

@property (strong, nonatomic) InAppPurchaseManager* purchaseManager;
@property (strong, nonatomic) IBOutlet RecordingManager* recordingManager;
@property (strong, nonatomic) ClipManager* clipManager;
@property (strong, nonatomic) FilterBank* filterBank;
@property (strong, nonatomic) ActiveFilterManager* activeFilterManager;
@property (strong, nonatomic) IBOutlet ControlBoxManager* controlBoxManager;
@property (strong, nonatomic) IBOutlet GPUImageView* previewLayer;
@property (strong, nonatomic) IBOutlet UIView* clipManagerView;
@property (strong, nonatomic) IBOutlet UIView* collectionShell;
@property (strong, nonatomic) IBOutlet UIView* blinkyRedLight;
@property (strong, nonatomic) IBOutlet UIView* recordingNotifier;
@property (strong, nonatomic) IBOutlet UILabel* notifierLabel;
@property (strong, nonatomic) IBOutlet UISlider* globalBlend;

- (IBAction)navigateToClips:(id)sender;
- (IBAction)navigateToCamera:(id)sender;
- (IBAction)userPressedRecord:(UIButton *)sender;

- (void)previewClipForUrl:(NSURL *)targetUrl;
- (void)awakeVideoCamera;
- (void)hideRecordingNotifier;

- (void)playbackFinished;
- (void)rotatedDuringPlayback;

- (CGRect)filterBankFrameForOrientation:(UIInterfaceOrientation)orientation;
- (CGRect)clipManagerFrameForOrientation:(UIInterfaceOrientation)orientation;

@end
