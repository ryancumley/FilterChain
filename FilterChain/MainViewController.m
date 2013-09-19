//
//  MainViewController.m
//  FilterChain
//
//  Created by Ryan Cumley on 9/6/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import "MainViewController.h"

#define k_filterBankHeight 99.0f
#define k_filterBankOffsetFromTop 51.0f

@interface MainViewController ()

@end

@implementation MainViewController

@synthesize clipManager = _clipManager, recordingManager = _recordingManager, controlBoxManager = _controlBoxManager, filterBank = _filterBank, activeFilterManager = _activeFilterManager, previewLayer = _previewLayer, clipManagerView = _clipManagerView, collectionShell = _collectionShell, toggleSwitch = _toggleSwitch, blinkyRedLight = _blinkyRedLight;
@synthesize switchingFilter = _switchingFilter, pipeline = _pipeline;

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
    //View Config
    _blinkyRedLight.userInteractionEnabled = NO; //allows user to press record (blinking view covers the button)
    
    //Camera config
    _switchingFilter = [[GPUImageFilter alloc] init];
    _recordingManager = [[RecordingManager alloc] init];
    [_switchingFilter addTarget:_previewLayer];
    
    //ClipManager Config
    clipCollectionIsVisible = NO;
    CGRect offScreen = [self clipManagerFrameForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    _clipManagerView.frame = offScreen;
    [self.view addSubview:_clipManagerView];
    
    _clipManager = [[ClipManager alloc] init];
    _clipManager.collectionView.frame = _collectionShell.frame;
    _clipManager.collectionView.backgroundColor = [UIColor clearColor];
    [_collectionShell addSubview:_clipManager.collectionView];
    [_clipManager refreshStoredClips];
    
    //FilterBank Config
    _filterBank = [[FilterBank alloc] init];
    _filterBank.collectionView.frame = [self filterBankFrameForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    [_controlBoxManager.view addSubview:_filterBank.collectionView];
    
    //ActiveFilterManager Config
    _activeFilterManager = [[ActiveFilterManager alloc] init];
    
    
    
}



- (IBAction)navigateToClips:(id)sender {
    if (_recordingManager.isRecording) {
        [_recordingManager stopRecording];
        [_clipManager refreshStoredClips];
    }
    [_recordingManager stopCameraCapture];
    
    clipCollectionIsVisible = YES;
    CGRect displayClips = [self clipManagerFrameForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    [UIView animateWithDuration:0.1
                     animations:^(void) {
                         _clipManagerView.frame = displayClips;
                     }
     ];
}

- (IBAction)navigateToCamera:(id)sender {
    [_recordingManager awakeVideoCamera];
    
     clipCollectionIsVisible = NO;
    CGRect displayClips = [self clipManagerFrameForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
     [UIView animateWithDuration:0.1
                     animations:^(void) {
                         _clipManagerView.frame = displayClips;
                     }
     ];

}

- (IBAction)userPressedRecord:(UIButton *)sender {
    BOOL isRecording = [_recordingManager isRecording];
    if (isRecording) {
        _blinkyRedLight.alpha = 1.0f;
        _blinkyRedLight.userInteractionEnabled = YES; //enabling interaction of the glowing red view covering the button effectively prevents the user from pressing record again until we're ready to deal with a new recording.
        [_recordingManager stopRecording];
        [_clipManager refreshStoredClips];
    }
    else {
        [_recordingManager startNewRecording];
    }
}

- (IBAction)filterKillSwitchPressed:(UISwitch *)sender {
    [_activeFilterManager updatePipeline]; 
}

- (void)previewClipForUrl:(NSURL *)targetUrl {
    MPMoviePlayerViewController *mpvc = [[MPMoviePlayerViewController alloc] initWithContentURL:targetUrl];
    mpvc.moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
    [self presentMoviePlayerViewControllerAnimated:mpvc];
}

- (void)awakeVideoCamera {
    if (_recordingManager == nil) {
        return;
    }
    [_recordingManager awakeVideoCamera];
    
}

- (void)refreshPipelineWithFilters:(NSArray *)filters {
    if (_toggleSwitch.on) {
        [_recordingManager.pipeline replaceAllFilters:filters];
    }
    else {
        [_recordingManager.pipeline replaceAllFilters:nil];
    }
    
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate {
    [super shouldAutorotate];
    
    //Pass the rotation down
    return YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [_recordingManager configureCamera];
    [_recordingManager orientVideoCameraOutputTo:[self interfaceOrientation]];
    
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    //Camera capture is expensive, let's give it a break until we've finished the rotation
    if (_recordingManager.isRecording) {
        [_recordingManager stopRecording];
    }
    [_recordingManager stopCameraCapture];
    
    [_clipManagerView setFrame:[self clipManagerFrameForOrientation:toInterfaceOrientation]];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [_recordingManager awakeVideoCamera];
    
    UIInterfaceOrientation endingOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    [_recordingManager orientVideoCameraOutputTo:endingOrientation];
    
    //update the filterBank
    [_filterBank.collectionView setFrame:[self filterBankFrameForOrientation:endingOrientation]];
    
    //update the collectionShell
    //[_clipManagerView setFrame:[self clipManagerFrameForOrientation:endingOrientation]];
    
}

- (CGRect)filterBankFrameForOrientation:(UIInterfaceOrientation)orientation {
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        //Handle landscape orientation
        filterBankFrame = CGRectMake(0.0, k_filterBankOffsetFromTop, appFrame.size.height, k_filterBankHeight);
    }
    else {
        //Handle portrait orientation
        filterBankFrame = CGRectMake(0.0, k_filterBankOffsetFromTop, appFrame.size.width, k_filterBankHeight);
    }
    return filterBankFrame;
}

- (CGRect)clipManagerFrameForOrientation:(UIInterfaceOrientation)orientation {
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    int offsetModifier = clipCollectionIsVisible ? 0 : 1;
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        //Handle landscape orientation
        collectionShellFrame = CGRectMake(-offsetModifier * appFrame.size.height, 0.0, appFrame.size.height, appFrame.size.width); //flip height and width
    }
    else {
        //Handle portrait orientation
        collectionShellFrame = CGRectMake(-offsetModifier * appFrame.size.width, 0.0, appFrame.size.width, appFrame.size.height); //flip height and width
    }
    return collectionShellFrame;
}


@end
