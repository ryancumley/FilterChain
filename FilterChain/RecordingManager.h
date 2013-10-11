//
//  RecordingManager.h
//  FilterChain
//
//  Created by Ryan Cumley on 9/6/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImage.h"
#import "ActiveFilterManager.h"

@interface RecordingManager :  NSObject <ActiveFilterToRecordingManager>
{
    GPUImageVideoCamera* videoCamera;
    BOOL recording;
    NSURL *fileURL;
}
@property (strong, nonatomic) GPUImageFilter* passThrough;
@property (strong, nonatomic) GPUImageFilter* pipelineDestination;
@property (strong, nonatomic) GPUImageView* mvcPreviewLayer;
@property (strong, nonatomic) GPUImageDissolveBlendFilter* blendFilter;
@property (strong, nonatomic) GPUImageMovieWriter *movieWriter;
@property (strong, nonatomic) GPUImageFilterPipeline* pipeline;
@property (strong, nonatomic) GPUImagePicture* staticPicture;
@property (strong, nonatomic) GPUImageFilter* prePassThrough;
@property (strong, nonatomic) IBOutlet UIImageView* blinkyRedLight;
@property (nonatomic, assign) id mvcDelegate;

- (void)configureCamera;
- (void)startCameraCapture;
- (void)pauseCameraCapture;
- (void)resumeCameraCapture;
- (void)stopCameraCapture;
- (BOOL)isRecording;
- (void)startNewRecording;
- (void)stopRecording;
- (void)orientVideoCameraOutputTo:(UIInterfaceOrientation)orientation;
- (void)updateBlendMix:(CGFloat)mix;

@end

@protocol RecordingManagerToMVC <NSObject>

- (void)startVisualRecordingFeedback;
- (void)stopVisualRecordingFeedback;
- (void)beginFlashingRecordButton;
- (void)hideRecordingNotifier;

@end
