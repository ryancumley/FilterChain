//
//  ClipManager.h
//  FilterChain
//
//  Created by Ryan Cumley on 9/6/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CachedThumbnails.h"

@interface ClipManager  :  UICollectionViewController <UIAlertViewDelegate>
{
    NSFileManager *fileManager;
    UISegmentedControl *activeClipSelection;
    NSURL* targetUrl;
    CachedThumbnails* cachedThumbnails;
}

@property (nonatomic, assign) id moviePlayerDelegate;

//Initialization and View Lifecycle

//Video Specific Actions
- (void)refreshStoredClips;
- (void)videoSaved:(NSString*)videoPath didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo;
- (void)generateThumbnails;
- (void)attemptRotation;

//Cell Selection and Actions
- (void)selectCellAtIndexPath:(NSIndexPath*)path;
- (void)deSelectCellAtIndexPath:(NSIndexPath*)path;
- (void)clipActionInvoked;

//UIAlertView Delegate Protocol Methods

//UICollectionView DataSource and Delegate Protocol Methods

@end

@protocol clipManagerMPMoviePlayer <NSObject>

- (void)previewClipForUrl:(NSURL *)targetUrl;

@end
