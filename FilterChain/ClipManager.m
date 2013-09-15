//
//  ClipManager.m
//  FilterChain
//
//  Created by Ryan Cumley on 9/6/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import "ClipManager.h"
#import "Cell.h"
#import "AppDelegate.h"
#import <MediaPlayer/MediaPlayer.h>

#define kCellID @"cellID"

@interface ClipManager ()

@end

@implementation ClipManager

@synthesize storedClips = _storedClips, storedThumbnails = _storedThumbnails;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = CGSizeMake(150.0, 180.0);
        UICollectionView *view = [[UICollectionView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320, 493) collectionViewLayout:flowLayout];
        self.collectionView = view;
        [self.collectionView registerClass:[Cell class] forCellWithReuseIdentifier:@"cellID"];
    }
    return self;
}

- (void)refreshStoredClips {
    _storedClips = nil;
    _storedClips = [NSMutableArray arrayWithArray:[self contentsOfDocuments]];
    [self generateThumbnails];
    [self.collectionView reloadData];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    NSInteger count = _storedClips.count;
    return count;
}

-(NSArray*)contentsOfDocuments {
    fileManager = [[NSFileManager alloc] init];
    NSString *documentsFolder = [NSHomeDirectory() stringByAppendingString:@"/Documents"];
    NSURL *documentsPath = [NSURL fileURLWithPath:documentsFolder isDirectory:YES];
    NSError *error;
    NSArray *fetchedArray = [fileManager contentsOfDirectoryAtURL:documentsPath includingPropertiesForKeys:[NSArray arrayWithObject:NSURLCreationDateKey] options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
    NSMutableArray *moviesOnly = [[NSMutableArray alloc] init];
    for (NSURL *link in fetchedArray) {
        NSString* type = [link pathExtension];
        if ([type isEqualToString:@"m4v"]) {
            [moviesOnly addObject:link];
        }
    }
    
    return moviesOnly;
    
}

- (void)generateThumbnails {
    //We're going to loop through the NSUrl's conatined in _storedClips and use the MPMoviePlayerController thumbnailImageAtTime method to create and store thumbs
    _storedThumbnails = nil;
    _storedThumbnails = [NSMutableArray arrayWithCapacity:_storedClips.count];
    for (NSURL *clip in _storedClips) {
        
        MPMoviePlayerController *mpc = [[MPMoviePlayerController alloc] initWithContentURL:clip];
        mpc.shouldAutoplay = NO;
        UIImage *thumb = [mpc thumbnailImageAtTime:1.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
        [_storedThumbnails addObject:thumb];
    }
    
}

- (void)clipActionInvoked {
    NSInteger selected = activeClipSelection.selectedSegmentIndex;
    NSIndexPath *selectedPath = [[self.collectionView indexPathsForSelectedItems] objectAtIndex:0]; //should be the first object always, since we're forbidding multiple selections
    NSInteger selectedRow = selectedPath.row;
    Cell *cell = (Cell*)[self.collectionView cellForItemAtIndexPath:selectedPath];
    UISegmentedControl *aux = cell.auxControl;
    NSURL *targetUrl = [_storedClips objectAtIndex:selectedRow];
    
    double delayToBegin= 0.2;
    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, delayToBegin* NSEC_PER_SEC);
    dispatch_after(startTime, dispatch_get_main_queue(), ^(void){
        if (selected == 0) {
            //Export the file!
            [aux setSelectedSegmentIndex:-1];
            NSString *path = [targetUrl path];
            BOOL compatible = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path);
            if (compatible) {
                UISaveVideoAtPathToSavedPhotosAlbum(path, self, @selector(videoSaved:didFinishSavingWithError:contextInfo:), nil);
            }
            
        }
        
        else if (selected == 1) { //preview the file
            AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
            MainViewController *mvc = (MainViewController*)appDelegate.mVC;
            [mvc previewClipForUrl:targetUrl];
            [aux setSelectedSegmentIndex:-1];
        }
        
        else if (selected == 2) { //Trash the file!
            for(NSIndexPath *indexPath in self.collectionView.indexPathsForSelectedItems) {
                [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
            }
            NSString *path = [targetUrl path];
            unlink([path UTF8String]); //??? This should delete it from Documents???
            [aux setSelectedSegmentIndex:-1];
            [self refreshStoredClips];
        }
    });
    
}

- (void)videoSaved:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    //Handle success with a sound later
    NSLog(@"saved a Video to the CameraRoll! : %@",videoPath);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    Cell *cell = [cv dequeueReusableCellWithReuseIdentifier:kCellID forIndexPath:indexPath];
    [cell.auxControl addTarget:self action:@selector(clipActionInvoked) forControlEvents:UIControlEventValueChanged];
    [cell.auxControl setHidden:YES];
    
    // load the image for this cell
    cell.image.image = [_storedThumbnails objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Cell *selectedCell = (Cell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    activeClipSelection = selectedCell.auxControl;
    [selectedCell.auxControl setSelectedSegmentIndex:-1];
    [selectedCell.auxControl setHidden:NO];
    selectedCell.backingView.backgroundColor = [UIColor colorWithRed:37.0f/255.0f green:44.0f/255.0f blue:58.0f/255.0f alpha:1.0f];
    
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    Cell *selectedCell = (Cell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    selectedCell.backingView.backgroundColor = [UIColor clearColor];
    [selectedCell.auxControl setHidden:YES];
    
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.collectionView setAllowsMultipleSelection:NO];
    [self refreshStoredClips];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
