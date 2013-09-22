//
//  RecordingManager.m
//  FilterChain
//
//  Created by Ryan Cumley on 9/6/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import "RecordingManager.h"
#import "AppDelegate.h"
#import "MainViewController.h"

#define k_FilterBankAlphaNotRecording 0.85f
#define k_FilterBankAlphaIsRecording 0.7f
#define k_filterBankBackgroundColor [UIColor colorWithRed:64.0f/255.0f green:71.0f/255.0f blue:90.0f/255.0f alpha:1.0]

@implementation RecordingManager

@synthesize movieWriter = _movieWriter, pipeline = _pipeline;

- (void)configureCamera {
    recording = NO;
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionBack];
    videoCamera.outputImageOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    videoCamera.horizontallyMirrorRearFacingCamera = NO;
    
    switchingFilter = [self switchingFilter];
    _pipeline = [[GPUImageFilterPipeline alloc] initWithOrderedFilters:nil input:videoCamera output:switchingFilter];
    [videoCamera startCameraCapture];
    
}

- (void)stopCameraCapture {
    [videoCamera stopCameraCapture];
}

- (void)startNewRecording {
    AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    MainViewController *mvc = (MainViewController*)delegate.window.rootViewController;
    [mvc.controlBoxManager.view setAlpha:k_FilterBankAlphaIsRecording];
    [mvc.filterBank.collectionView setBackgroundColor:[UIColor clearColor]];
    [self beginFlashingRecordButton];
    
    //Generate a unique URL to write this movie to within the app's Documents folder. Should be accessible to iTunes as well.
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString] ;
    NSString *pathString = [@"Documents/" stringByAppendingString:guid];
    NSString *fullPath = [pathString stringByAppendingString:@".m4v"];
    NSString *pathForURL= [NSHomeDirectory() stringByAppendingPathComponent:fullPath];
    unlink([pathForURL UTF8String]); //cleans the link on the *impossible* chance that a file exists at this path already
    fileURL = [NSURL fileURLWithPath:pathForURL];
    
    //prepare the movieWriter and start recording
    if (_movieWriter) {
        _movieWriter = nil; //start fresh
    }
    
    //Setup the CGSize based on the device and orientation. Since we nil the movieWriter when recording stops; and we force recording to stop at
    //rotation or interruption, this should be a **safe** place to establish screen size.
    CGSize naturalScreen = [[UIScreen mainScreen] applicationFrame].size;
    BOOL inLandscape = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
    CGSize rotatedScreen;
    if (inLandscape) {
        rotatedScreen = CGSizeMake(naturalScreen.height, naturalScreen.width);
    }
    else {
        rotatedScreen = naturalScreen;
    }
    _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:fileURL size:rotatedScreen fileType:AVFileTypeQuickTimeMovie outputSettings:nil];
    switchingFilter = [self switchingFilter];
    [switchingFilter addTarget:_movieWriter];
    if (videoCamera == nil) {
        [self configureCamera];
    }
    videoCamera.audioEncodingTarget = _movieWriter;
    [_movieWriter startRecording];
    recording = YES;

    
}

- (void)stopRecording {
    AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    MainViewController *mvc = (MainViewController*)delegate.window.rootViewController;
    [mvc.controlBoxManager.view setAlpha:k_FilterBankAlphaNotRecording];
    [mvc.filterBank.collectionView setBackgroundColor:k_filterBankBackgroundColor];
    videoCamera.audioEncodingTarget = nil;
    [videoCamera pauseCameraCapture];
    [switchingFilter removeTarget:_movieWriter];
    [_movieWriter finishRecording];
    recording = NO;
    mvc.blinkyRedLight.userInteractionEnabled = NO; //allow the user to press the button behind this UIImageView again.
    mvc.blinkyRedLight.alpha = 0.0f;
    [videoCamera resumeCameraCapture];
}

- (GPUImageFilter*)switchingFilter {
    AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    MainViewController *mvc = (MainViewController*)delegate.window.rootViewController;
    switchingFilter = mvc.switchingFilter;
    return switchingFilter;
}

- (BOOL)isRecording {
    return recording;
}

- (void)awakeVideoCamera {
    [videoCamera startCameraCapture];
}

- (void)orientVideoCameraOutputTo:(UIInterfaceOrientation)orientation {
    UIInterfaceOrientation outputOrientation;
    switch (orientation) {
        case UIInterfaceOrientationLandscapeLeft:
            outputOrientation = UIInterfaceOrientationLandscapeRight;
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            outputOrientation = UIInterfaceOrientationLandscapeLeft;
            break;
            
        case UIInterfaceOrientationPortrait:
            outputOrientation = UIInterfaceOrientationPortrait;
            break;
        
        case UIInterfaceOrientationPortraitUpsideDown:
            outputOrientation = UIInterfaceOrientationPortraitUpsideDown;
            break;

        default:
            outputOrientation = UIInterfaceOrientationPortrait;
            break;
    }
    
    [videoCamera setOutputImageOrientation:outputOrientation];
}

- (void)beginFlashingRecordButton {
    AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    MainViewController *mvc = (MainViewController*)delegate.window.rootViewController;
    mvc.blinkyRedLight.alpha = 0.0;
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionAutoreverse |
                                UIViewAnimationOptionAllowUserInteraction |
                                UIViewAnimationOptionRepeat
                     animations:^(void) {
                         mvc.blinkyRedLight.alpha = 1.0;
                     }
     
     
                     completion:^(BOOL finished) {
                     }
     ];
}


@end
