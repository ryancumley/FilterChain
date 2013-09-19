//
//  ClipManager.h
//  FilterChain
//
//  Created by Ryan Cumley on 9/6/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ClipManager  :  UICollectionViewController <UIAlertViewDelegate>
{
    NSFileManager *fileManager;
    UISegmentedControl *activeClipSelection;
}

@property (strong, nonatomic) NSMutableArray *storedClips; //an arry of NSURl objects fetched from the user's Documents folder
@property (strong, nonatomic) NSMutableArray *storedThumbnails;

- (void)refreshStoredClips;
- (NSArray*)contentsOfDocuments;
- (void)generateThumbnails;
- (void)clipActionInvoked;
- (void)videoSaved:(NSString*)videoPath didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo;
- (void)dismissAlert:(UIAlertView *)alertView;


@end
