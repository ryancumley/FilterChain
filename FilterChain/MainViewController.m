//
//  MainViewController.m
//  FilterChain
//
//  Created by Ryan Cumley on 9/6/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import "MainViewController.h"

//#define k_SlideLeftFrame CGRectMake(-320.0, 0.0, 320.0, 568.0)
//#define k_SlideRightFrame CGRectMake(0.0, 0.0, 320.0, 568.0)
#define k_filterBankFrame CGRectMake(0.0, 51.0, 320.0, 99.0)

@interface MainViewController ()

@end

@implementation MainViewController

@synthesize clipManager = _clipManager, recordingManager = _recordingManager, controlBoxManager = _controlBoxManager, filterBank = _filterBank, activeFilterManager = _activeFilterManager, previewLayer = _previewLayer, clipManagerView = _clipManagerView, collectionShell = _collectionShell, toggleSwitch = _toggleSwitch;
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
    
    //Camera config
    _switchingFilter = [[GPUImageFilter alloc] init];
    _recordingManager = [[RecordingManager alloc] init];
    [_recordingManager configureCamera];
    [_switchingFilter addTarget:_previewLayer];
    
    //ClipManager Config
    CGRect offScreen = CGRectMake(-self.view.frame.size.width, 0, self.view.frame.size.width, self.view.frame.size.height);
    _clipManagerView.frame = offScreen;
    [self.view addSubview:_clipManagerView];
    
    _clipManager = [[ClipManager alloc] init];
    _clipManager.collectionView.frame = _collectionShell.frame;
    _clipManager.collectionView.backgroundColor = [UIColor clearColor];
    [_collectionShell addSubview:_clipManager.collectionView];
    [_clipManager refreshStoredClips];
    
    //FilterBank Config
    _filterBank = [[FilterBank alloc] init];
    _filterBank.collectionView.frame = k_filterBankFrame;
    [_controlBoxManager.view addSubview:_filterBank.collectionView];
    
    //ActiveFilterManager Config
    _activeFilterManager = [[ActiveFilterManager alloc] init];
    
    
    
}



- (IBAction)navigateToClips:(id)sender {
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    CGRect displayClips = CGRectMake(0.0, 0.0, appFrame.size.width, appFrame.size.height);
    [UIView animateWithDuration:0.1
                     animations:^(void) {
                         _clipManagerView.frame = displayClips;
                     }
     ];
}

- (IBAction)navigateToCamera:(id)sender {
     CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
     CGRect displayClips = CGRectMake(-appFrame.size.width, 0.0, appFrame.size.width, appFrame.size.height);
     [UIView animateWithDuration:0.1
                     animations:^(void) {
                         _clipManagerView.frame = displayClips;
                     }
     ];

}

- (IBAction)userPressedRecord:(UIButton *)sender {
    BOOL isRecording = [_recordingManager isRecording];
    if (isRecording) {
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

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    //NSLog(@"orientation: %d",fromInterfaceOrientation);
}

@end
