//
//  MainViewController.m
//  FilterChain
//
//  Created by Ryan Cumley on 9/6/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import "MainViewController.h"
#import <AVFoundation/AVAudioSession.h>

#define k_filterBankHeight 99.0f
#define k_filterBankOffsetFromTop 51.0f
#define k_maxActiveFilters 6
#define k_upgradePurchased @"upgradePurchased"
#define k_micPermission @"micPermission"
#define k_filterBankBackgroundColor [UIColor colorWithRed:49.0f/255.0f green:57.0f/255.0f blue:73.0f/255.0f alpha:1.0]
#define k_filterBankBackgroundRecordingColor [UIColor colorWithRed:37.0f/255.0f green:44.0f/255.0f blue:58.0f/255.0f alpha:0.5]

@interface MainViewController ()

- (void)playbackFinished;
- (void)rotatedDuringPlayback;
- (CGRect)filterBankFrameForOrientation:(UIInterfaceOrientation)orientation;
- (CGRect)clipManagerFrameForOrientation:(UIInterfaceOrientation)orientation;

@end

@implementation MainViewController

//app defined classes
@synthesize purchaseManager = _purchaseManager, clipManager = _clipManager, recordingManager = _recordingManager, filterBank = _filterBank, activeFilterManager = _activeFilterManager, previewLayer = _previewLayer;

//system classes
@synthesize clipManagerView = _clipManagerView, collectionShell = _collectionShell, controlBoxView = _controlBoxView, blinkyRedLight = _blinkyRedLight, recordingNotifier = _recordingNotifier, notifierLabel = _notifierLabel, globalBlend = _globalBlend, recordingTimer = _recordingTimer;


#pragma mark -
#pragma mark View Lifecycle

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
    _recordingNotifier.layer.masksToBounds = YES;
    _recordingNotifier.layer.cornerRadius = 5.0;
    _recordingTimer.hidden = YES;
    [_globalBlend addTarget:self action:@selector(touchDownInBlend) forControlEvents:UIControlEventTouchDown];
    [_globalBlend addTarget:self action:@selector(touchEndedInBlend) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside)];
    purchaseAlertViewIsShowing = NO;
    
    //Camera config
    _recordingManager = [[RecordingManager alloc] init];
    [_recordingManager setMvcDelegate:self];
    
    //FilterBank Config
    _filterBank = [[FilterBank alloc] init];
    _filterBank.collectionView.frame = [self filterBankFrameForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    [_controlBoxView addSubview:_filterBank.collectionView];
    [_filterBank.collectionView setBackgroundColor:k_filterBankBackgroundColor];
    [_filterBank setMvcDelegate:self];
    
    //ActiveFilterManager Config
    _activeFilterManager = [[ActiveFilterManager alloc] init];
    [_activeFilterManager setFilterBankDelegate:_filterBank];
    [_activeFilterManager setRecordingManagerDelegate:_recordingManager];
    [_activeFilterManager setMvcDelegate:self];
    
    
    [self performSelector:@selector(checkForMicrophonePermission) withObject:nil afterDelay:1.0];
}

- (void)viewDidAppear:(BOOL)animated {
    _filterBank.collectionView.frame = [self filterBankFrameForOrientation:[[UIApplication sharedApplication] statusBarOrientation]]; // handles a launch in portrait, since ViewDidLoad has the status bar in portrait at launch
    [_recordingManager configureCamera];
    [_recordingManager orientVideoCameraOutputTo:[self interfaceOrientation]];
}

- (void)viewWillLayoutSubviews {
    if (orientationChangedDuringPlayback) {
        //We just rotated while a MPMoviePlayerController covered the screen. Tell mVC to handle the rotation so it stays in sync when the user dismisses the clip
        [UIViewController attemptRotationToDeviceOrientation];
        [self navigateToClips:nil];
        orientationChangedDuringPlayback = NO; //reset the flag
    }
}

- (void)checkForMicrophonePermission {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@NO:k_micPermission}];
    
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
        [[AVAudioSession sharedInstance] performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
            if (granted) {
                // Microphone enabled code
                [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:k_micPermission];
                _micWarning.hidden = YES;
            }
            else {
                // Microphone disabled code
                [[NSUserDefaults standardUserDefaults] setObject:@NO forKey:k_micPermission];//for when access was rescinded at a later point. next full app launch will catch it
                _micWarning.hidden = NO;
            }
        }];
    }
    
}

- (IBAction)globalMixChanged:(UISlider *)sender {
    [_recordingManager updateBlendMix:[(UISlider *)sender value]];
}

- (void)touchDownInBlend {
    
    _globalBlend.layer.borderColor = [UIColor colorWithRed:143.0/255.0 green:211.0/255.0 blue:111.0/255.0 alpha:0.8].CGColor;
    _globalBlend.layer.borderWidth = 1.0;
    _globalBlend.backgroundColor = [UIColor colorWithRed:37.0/255.0 green:44.0/255.0 blue:58.0/255.0 alpha:1.0];
}

- (void)touchEndedInBlend {
    _globalBlend.backgroundColor = [UIColor clearColor];
    _globalBlend.layer.borderColor = [UIColor clearColor].CGColor;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




#pragma mark -
#pragma mark Rotation Handling

- (BOOL)shouldAutorotate {
    [super shouldAutorotate];
    
    //Block if a recording is in progress, otherwise allow it.
    if (_recordingManager.isRecording | purchaseAlertViewIsShowing) {
        return NO;
    }
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    //Camera capture is expensive, let's give it a break until we've finished the rotation
    if (_recordingManager.isRecording) {
        [self stopTimer];
        [_recordingManager stopRecording];
    }
    [_recordingManager stopCameraCapture];
    [_clipManagerView setFrame:[self clipManagerFrameForOrientation:toInterfaceOrientation]];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [_recordingManager startCameraCapture];
    UIInterfaceOrientation endingOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    [_recordingManager orientVideoCameraOutputTo:endingOrientation];
    
    //update the filterBank
    [_filterBank.collectionView setFrame:[self filterBankFrameForOrientation:endingOrientation]];
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
        collectionShellFrame = CGRectMake(-offsetModifier * appFrame.size.width, 0.0, appFrame.size.width, appFrame.size.height);
    }
    return collectionShellFrame;
}






#pragma mark -
#pragma mark App Specific tasks and actions

- (IBAction)navigateToClips:(id)sender {
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
    [_clipManager setMoviePlayerDelegate:self];
    
    //free up resources from recording gracefully
    if (_recordingManager.isRecording) {
        [self stopTimer];
        [_recordingManager stopRecording];
        [_clipManager refreshStoredClips];
    }
    [_recordingManager pauseCameraCapture];
    
    //present the clips
    clipCollectionIsVisible = YES;
    [self.view bringSubviewToFront:_clipManagerView];
    CGRect displayClips = [self clipManagerFrameForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    [UIView animateWithDuration:0.1
                     animations:^(void) {
                         _clipManagerView.frame = displayClips;
                     }
     ];
}

- (IBAction)navigateToCamera:(id)sender {
    [_recordingManager resumeCameraCapture];
    [_activeFilterManager updatePipeline];
    
     clipCollectionIsVisible = NO;
    CGRect displayClips = [self clipManagerFrameForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
     [UIView animateWithDuration:0.1
                     animations:^(void) {
                         _clipManagerView.frame = displayClips;
                     }
     ];
    
    [_clipManager.view removeFromSuperview];
    _clipManager = nil;
}

- (IBAction)userPressedRecord:(UIButton *)sender {
    BOOL isRecording = [_recordingManager isRecording];
    if (isRecording) {
        _blinkyRedLight.alpha = 0.1f;
        [self stopTimer];
        _blinkyRedLight.userInteractionEnabled = YES; //enabling interaction of the glowing red view covering the button effectively prevents the user from pressing record again until we're ready to deal with a new recording.
        [_recordingManager stopRecording];
        //[_clipManager refreshStoredClips]; happens when navigating to clipManager.view now instead of here.
    }
    else {
        [_recordingManager startNewRecording];
        [self startTimer];
    }
}

- (IBAction)pressedMicWarning:(id)sender {
    [[[UIAlertView alloc] initWithTitle:@"Microphone Permission Denied" message:@"You must enable permission to access the microphone. Right now all your videos will be silent. Settings > Privacy > Microphone" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil] show];
}

- (void)awakeVideoCamera {
    if (_recordingManager == nil) {
        return;
    }
    [_recordingManager startCameraCapture];
}

-(void)startTimer {
    [_recordingTimer setHidden:NO];
    timeSec = 0;
    timeSec = 0;
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)timerTick:(NSTimer *)timer {
    timeSec++;
    if (timeSec == 60)
    {
        timeSec = 0;
        timeMin++;
    }
    //Format the string 00:00
    NSString* timeNow = [NSString stringWithFormat:@"%02d:%02d", timeMin, timeSec];
    _recordingTimer.text = timeNow;
}

- (void)stopTimer {
    [_recordingTimer setHidden:YES];
    [timer invalidate];
    timeSec = 0;
    timeMin = 0;
    NSString* timeNow = [NSString stringWithFormat:@"%02d:%02d", timeMin, timeSec];
    _recordingTimer.text = timeNow;
}






#pragma mark -
#pragma mark RecordingManagerToMVC delegate methods

- (void)startVisualRecordingFeedback {
    [_filterBank.collectionView setBackgroundColor:k_filterBankBackgroundRecordingColor];
    [self beginFlashingRecordButton];
    [_recordingNotifier setHidden:NO];
    _notifierLabel.text = @"Recording";
    [self performSelector:@selector(hideRecordingNotifier) withObject:nil afterDelay:1.5];
    
}

- (void)stopVisualRecordingFeedback {
    [_recordingNotifier setHidden:NO];
    _notifierLabel.text = @"Saving Clip";
    [_filterBank.collectionView setBackgroundColor:k_filterBankBackgroundColor];
    [_blinkyRedLight setUserInteractionEnabled:NO];
    [_blinkyRedLight setAlpha:0.0f];
    [self performSelector:@selector(hideRecordingNotifier) withObject:nil afterDelay:1.0];
}

- (void)beginFlashingRecordButton {
    _blinkyRedLight.alpha = 0.0;
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionAutoreverse |
                                UIViewAnimationOptionAllowUserInteraction |
                                UIViewAnimationOptionRepeat
                     animations:^(void) {
                         _blinkyRedLight.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                     }
     ];
}

- (void)hideRecordingNotifier {
    [_recordingNotifier setHidden:YES];
}






#pragma mark -
#pragma mark Movie Player Handling

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



#pragma mark -
#pragma mark ActiveFilterToMVC Protocol

- (void)removeLiveFilterWithTag:(int)tag {
    //We need to replace the (tag)th filter's thumb image, slider value, and hidden status with the (tag + 1)th filter's values
    LiveFilterView* n = (LiveFilterView*)[self.view viewWithTag:tag];
    if (tag == k_maxActiveFilters) {
        n.hidden = YES;
        return;
    }
    
    //Now start at the targeted tag, look ahead one, and shuffle the values down
    LiveFilterView* nPlusOne;
    for (int i = tag; i < k_maxActiveFilters; i++) {
        n =(LiveFilterView*)[self.view viewWithTag:i];
        nPlusOne = (LiveFilterView*)[self.view viewWithTag:(i + 1)];
        if (!nPlusOne.hidden) {
            UIImage* new = [nPlusOne.slider.currentThumbImage copy];
            [n.slider setThumbImage:new forState:UIControlStateNormal];
            [n.slider setThumbImage:new forState:UIControlStateHighlighted];
            [n.slider setValue:[nPlusOne.slider value] animated:YES];
            [nPlusOne isSliderStationary] ? [n makeSliderStaionary:YES] : [n makeSliderStaionary:NO];
            [n hideKillButton];
            continue;
        }
        else { //hides the terminal filters for sets of filters < k_maxActiveFilters
            [n setHidden:YES];
            return;
        }
    }
    [nPlusOne setHidden:YES];//If all filters were visible, and an earlier filter was killed, this takes care of the Terminal Filter. Could have checked for i == (k_maxActiveFilters - 1) in the loop, but placing it here calls it only once.
}








#pragma mark -
#pragma mark PurchaseAlertViewDelegate Protocol

- (void)purchaseAlertViewIsTakingOverWithView:(UIView *)view {
    CGRect appFrame = [[UIScreen mainScreen] bounds];
    CGRect blockingViewFrame;
    CGPoint center;
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        center = CGPointMake(appFrame.size.height/2, appFrame.size.width/2);
        blockingViewFrame = CGRectMake(0.0, 0.0, appFrame.size.height, appFrame.size.width);
    }
    else {
        center = CGPointMake(appFrame.size.width/2, appFrame.size.height/2);
        blockingViewFrame = CGRectMake(0.0, 0.0, appFrame.size.width, appFrame.size.height);
    }

    blockingView = [[UIView alloc] initWithFrame:blockingViewFrame];
    [blockingView setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5]];
    [blockingView setUserInteractionEnabled:YES];//intercepts touches much like an UIAlertView would.
    [self.view addSubview:blockingView];
    
    purchaseAlertView = view;
    purchaseAlertView.center = center;
    [self.view addSubview:purchaseAlertView];
    purchaseAlertViewIsShowing = YES;
    
    
}

- (void)purchaseAlertViewIsResigning {
    //do any requried cleanup
    [blockingView removeFromSuperview];
    blockingView = nil;
    [purchaseAlertView removeFromSuperview];
    purchaseAlertViewIsShowing = NO;
}





#pragma mark -
#pragma mark FilterBankToMVC Protocol

- (void)userSelectedAPremiumFilter {
    if  (_purchaseManager == nil) {
        //PurchaseManager Config
        _purchaseManager = [[InAppPurchaseManager alloc] init];
        [_purchaseManager setPurchasePresentationDelegate:self];
        NSUserDefaults* standardDefaults = [NSUserDefaults standardUserDefaults];
        [standardDefaults registerDefaults:@{@NO:k_upgradePurchased}];
        [standardDefaults synchronize];
    }
    
    [_purchaseManager loadStore];
    [_purchaseManager launchInAppPurchaseDialog];
}

@end
