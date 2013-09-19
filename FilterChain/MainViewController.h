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

@interface MainViewController : UIViewController
{
    CGRect filterBankFrame;
    CGRect collectionShellFrame;
    BOOL clipCollectionIsVisible;
}

@property (strong, nonatomic) IBOutlet RecordingManager* recordingManager;
@property (strong, nonatomic) ClipManager* clipManager;
@property (strong, nonatomic) FilterBank* filterBank;
@property (strong, nonatomic) ActiveFilterManager* activeFilterManager;
@property (strong, nonatomic) IBOutlet ControlBoxManager* controlBoxManager;
@property (strong, nonatomic) IBOutlet GPUImageView* previewLayer;
@property (strong, nonatomic) IBOutlet UISwitch* toggleSwitch;
@property (strong, nonatomic) IBOutlet UIView* clipManagerView;
@property (strong, nonatomic) IBOutlet UIView* collectionShell;
@property (strong, nonatomic) IBOutlet UIView* blinkyRedLight;

@property (strong, nonatomic) GPUImageFilter* switchingFilter;
@property (strong, nonatomic) GPUImageFilterPipeline* pipeline;


- (IBAction)navigateToClips:(id)sender;
- (IBAction)navigateToCamera:(id)sender;
- (IBAction)userPressedRecord:(UIButton *)sender;
- (IBAction)filterKillSwitchPressed:(UISwitch *)sender;

- (void)previewClipForUrl:(NSURL *)targetUrl;
- (void)awakeVideoCamera;
- (void)refreshPipelineWithFilters:(NSArray*)filters;

- (CGRect)filterBankFrameForOrientation:(UIInterfaceOrientation)orientation;
- (CGRect)clipManagerFrameForOrientation:(UIInterfaceOrientation)orientation;

@end
