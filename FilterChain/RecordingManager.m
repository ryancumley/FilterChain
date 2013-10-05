//
//  RecordingManager.m
//  FilterChain
//
//  Created by Ryan Cumley on 9/6/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import "RecordingManager.h"
#import "AppDelegate.h"

#define k_filterBankBackgroundColor [UIColor colorWithRed:64.0f/255.0f green:71.0f/255.0f blue:90.0f/255.0f alpha:1.0]
#define k_filterBankBackgroundRecordingColor [UIColor colorWithRed:64.0f/255.0f green:71.0f/255.0f blue:90.0f/255.0f alpha:0.5]

@implementation RecordingManager

@synthesize movieWriter = _movieWriter, pipeline = _pipeline, blendFilter = _blendFilter, mvcPreviewLayer = _mvcPreviewLayer, passThrough = _passThrough, pipelineDestination = _pipelineDestination;
@synthesize mvcDelegate = _mvcDelegate;

#pragma mark Setup and Configuration Management

- (void)updatePipelineWithFilters:(NSArray*)filters {
    //save mix value and prepare to swap out the pipeline
    CGFloat mix = _blendFilter.mix;
    if (recording) {
        [_blendFilter removeTarget:_movieWriter];
    }
    [videoCamera removeTarget:_blendFilter];
    [_pipelineDestination removeTarget:_blendFilter];
    _blendFilter = nil;
    
    //handle an empty Pipeline
    if (filters.count == 0) {
        _passThrough = [[GPUImageFilter alloc] init];
        NSArray* emptyFilters= [NSArray arrayWithObjects:_passThrough, nil];
        [_pipeline replaceAllFilters:emptyFilters];
    }
    else {
        [_pipeline replaceAllFilters:filters];
    }
    
    //Re-configure the blendFilter
    _blendFilter = [[GPUImageDissolveBlendFilter alloc] init];
    [videoCamera addTarget:_blendFilter];
    [_pipelineDestination addTarget:_blendFilter];
    [_blendFilter addTarget:_mvcPreviewLayer];
    [_blendFilter setMix:mix];
    if (recording) {
        [_blendFilter addTarget:_movieWriter];
    }
}

- (void)configureCamera {
    recording = NO;
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionBack];
    videoCamera.outputImageOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    videoCamera.horizontallyMirrorRearFacingCamera = NO;
    
    _mvcPreviewLayer = [(MainViewController*)[[[[UIApplication sharedApplication] delegate] window] rootViewController] previewLayer];
    _blendFilter = [[GPUImageDissolveBlendFilter alloc] init];
    _passThrough = [[GPUImageFilter alloc] init];//used as a placeholder for empty pipelines.
    NSArray* filters = [NSArray arrayWithObjects:_passThrough, nil];
    _pipelineDestination = [[GPUImageFilter alloc] init];
    _pipeline = [[GPUImageFilterPipeline alloc] initWithOrderedFilters:filters input:videoCamera output:_pipelineDestination];
    [videoCamera addTarget:_blendFilter];
    [_pipelineDestination addTarget:_blendFilter];
    [_blendFilter addTarget:_mvcPreviewLayer];
    [videoCamera startCameraCapture];
}

- (void)startCameraCapture {
    [videoCamera startCameraCapture];
}

- (void)resumeCameraCapture {
    [videoCamera resumeCameraCapture];
}

- (void)pauseCameraCapture {
    [videoCamera pauseCameraCapture];
}

- (void)stopCameraCapture {
    [videoCamera stopCameraCapture];
}



#pragma mark Recording Functionality

- (BOOL)isRecording {
    return recording;
}

- (void)startNewRecording {

    [self.mvcDelegate startVisualRecordingFeedback];
    
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
    [_blendFilter addTarget:_movieWriter];
    if (videoCamera == nil) {
        [self configureCamera];
    }
    videoCamera.audioEncodingTarget = _movieWriter;
    [_movieWriter startRecording];
    recording = YES;
}

- (void)stopRecording {
    [self.mvcDelegate stopVisualRecordingFeedback];
    videoCamera.audioEncodingTarget = nil;
    [videoCamera pauseCameraCapture];
    [_blendFilter removeTarget:_movieWriter];
    [_movieWriter finishRecording];
    recording = NO;
    [videoCamera resumeCameraCapture];
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






#pragma mark Convenience Method

- (void)updateBlendMix:(CGFloat)mix {
    [_blendFilter setMix:mix];
}

@end
