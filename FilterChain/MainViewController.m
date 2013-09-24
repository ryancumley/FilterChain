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
#define k_filterBankBackgroundColor [UIColor colorWithRed:64.0f/255.0f green:71.0f/255.0f blue:90.0f/255.0f alpha:1.0]

@interface MainViewController ()

@end

@implementation MainViewController


@synthesize clipManager = _clipManager, recordingManager = _recordingManager, controlBoxManager = _controlBoxManager, filterBank = _filterBank, activeFilterManager = _activeFilterManager, previewLayer = _previewLayer, clipManagerView = _clipManagerView, collectionShell = _collectionShell, blinkyRedLight = _blinkyRedLight, recordingNotifier = _recordingNotifier, notifierLabel = _notifierLabel;

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
    [self hideRecordingNotifier];
    
    //Camera config
    _recordingManager = [[RecordingManager alloc] init];
    
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
    [_filterBank.collectionView setBackgroundColor:k_filterBankBackgroundColor];
    
    //ActiveFilterManager Config
    _activeFilterManager = [[ActiveFilterManager alloc] init];
}

- (void)hideRecordingNotifier {
    [_recordingNotifier setHidden:YES];
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

- (IBAction)globalMixChanged:(UISlider *)sender {
    [_recordingManager updateBlendMix:[(UISlider *)sender value]];
}

- (void)previewClipForUrl:(NSURL *)targetUrl {
    MPMoviePlayerViewController *mpvc = [[MPMoviePlayerViewController alloc] initWithContentURL:targetUrl];
    mpvc.moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotatedDuringPlayback) name:UIDeviceOrientationDidChangeNotification object:nil];
    [self presentMoviePlayerViewControllerAnimated:mpvc];
}

- (void)playbackFinished {
    //stop observing, we've heard all that we need now
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    
}

- (void)rotatedDuringPlayback {
    orientationChangedDuringPlayback = YES;
}

- (void)awakeVideoCamera {
    if (_recordingManager == nil) {
        return;
    }
    [_recordingManager awakeVideoCamera];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate {
    [super shouldAutorotate];
    
    //Block if a recording is in progress, otherwise allow it.
    if (_recordingManager.isRecording) {
        return NO;
    }
    return YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [_recordingManager configureCamera];
    [_recordingManager orientVideoCameraOutputTo:[self interfaceOrientation]];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
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
}

- (void)viewWillLayoutSubviews {
    if (orientationChangedDuringPlayback) {
        //We just rotated while a MPMoviePlayerController covered the screen. Tell mVC to handle the rotation so it stays in sync when the user dismisses the clip
        [UIViewController attemptRotationToDeviceOrientation];
        [self navigateToClips:nil];
        orientationChangedDuringPlayback = NO; //reset the flag
    }
}

- (CGRect)filterBankFrameForOrientation:(UIInterfaceOrientation)orientation {
    CGRect appFrame = [[UIScreen mainScreen] bounds];
    if (UIInterfaceOrientationIsLandscape(orientation)) {//using bounds here instead of applicationFrame for iOS7 compatibility
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
    CGRect appFrame = [[UIScreen mainScreen] bounds]; //using bounds here instead of applicationFrame for iOS7 compatibility
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
