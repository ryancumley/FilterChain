//
//  RecordingManager.h
//  FilterChain
//
//  Created by Ryan Cumley on 9/6/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImage.h"

@interface RecordingManager : NSObject
{
    GPUImageVideoCamera* videoCamera;
    BOOL recording;
    NSURL *fileURL;
    GPUImageFilter* switchingFilter;
    
    
}

@property (strong, nonatomic) GPUImageMovieWriter *movieWriter;
@property (strong, nonatomic) GPUImageFilterPipeline* pipeline;
@property (strong, nonatomic) IBOutlet UIImageView* blinkyRedLight;

- (void)configureCamera;
- (void)stopCameraCapture;
- (void)startNewRecording;
- (void)stopRecording;
- (GPUImageFilter*)switchingFilter;
- (BOOL)isRecording;
- (void)awakeVideoCamera;
- (void)orientVideoCameraOutputTo:(UIInterfaceOrientation)orientation;
- (void)beginFlashingRecordButton;
- (void)hideRecordingNotifier;



@end
