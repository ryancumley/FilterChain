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

@synthesize movieWriter = _movieWriter, pipeline = _pipeline;

- (void)configureCamera {
    recording = NO;
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
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
    _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:fileURL size:CGSizeMake(480, 640) fileType:AVFileTypeQuickTimeMovie outputSettings:nil];
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

@end
