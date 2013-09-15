//
//  MainViewController.m
//  FilterChain
//
//  Created by Ryan Cumley on 9/6/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import "MainViewController.h"

#define k_SlideLeftFrame CGRectMake(0.0, 0.0, 640.0, 568.0)
#define k_SlideRightFrame CGRectMake(-320.0, 0.0, 640.0, 568.0)
#define k_ClipManagerFrame CGRectMake(0.0, 0.0, 320.0, 515.0)
#define k_filterBankFrame CGRectMake(0.0, 51.0, 320.0, 99.0)

@interface MainViewController ()

@end

@implementation MainViewController

@synthesize clipManager = _clipManager, recordingManager = _recordingManager, controlBoxManager = _controlBoxManager, filterBank = _filterBank, activeFilterManager = _activeFilterManager, previewLayer = _previewLayer, slidingShell = _slidingShell, controlBox = _controlBox, toggleSwitch = _toggleSwitch;
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
    self.view.frame = CGRectMake(0.0, 0.0, 320.0, 568.0);
     _slidingShell.frame = CGRectMake(-320.0, 0.0, 640.0, 568.0);
    [self.view addSubview:_slidingShell];
    
    //Camera config
    _switchingFilter = [[GPUImageFilter alloc] init];
    _recordingManager = [[RecordingManager alloc] init];
    [_recordingManager configureCamera];
    [_switchingFilter addTarget:_previewLayer];
    
    //ClipManager Config
    _clipManager = [[ClipManager alloc]init];
    _clipManager.collectionView.frame = k_ClipManagerFrame;
    _clipManager.collectionView.backgroundColor = [UIColor clearColor];
    [_slidingShell addSubview:_clipManager.collectionView];
    [_clipManager refreshStoredClips];
    
    //FilterBank Config
    _filterBank = [[FilterBank alloc] init];
    _filterBank.collectionView.frame = k_filterBankFrame;
    [_controlBox addSubview:_filterBank.collectionView];
    
    //ActiveFilterManager Config
    _activeFilterManager = [[ActiveFilterManager alloc] init];
    
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)navigateToClips:(id)sender {
    [UIView animateWithDuration:0.1
                     animations:^(void) {
                         _slidingShell.frame = k_SlideLeftFrame;
                     }
     ];
}

- (IBAction)navigateToCamera:(id)sender {
    [UIView animateWithDuration:0.1
                     animations:^(void) {
                         _slidingShell.frame = k_SlideRightFrame;
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

@end
