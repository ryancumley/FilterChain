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

@implementation RecordingManager

@synthesize movieWriter = _movieWriter, pipeline = _pipeline, blinkyRedLight = _blinkyRedLight;

- (void)configureCamera {
    _blinkyRedLight.alpha = 0.0f;
    recording = NO;
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionBack];
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
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
    [self beginFlashingRecordButton];

    
}

- (void)stopRecording {
    [_blinkyRedLight stopAnimating];
    videoCamera.audioEncodingTarget = nil;
    [videoCamera pauseCameraCapture];
    [switchingFilter removeTarget:_movieWriter];
    [_movieWriter finishRecording];
    recording = NO;
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
    [UIView animateWithDuration:1.0
                          delay:0.0
                        options:UIViewAnimationOptionAutoreverse
                     animations:^(void) {
                         [_blinkyRedLight setAlpha:1.0];
                     }
     
     
                     completion:^(BOOL finished) {
                         NSLog(@"cycle");
                     }
     ];
}


@end
