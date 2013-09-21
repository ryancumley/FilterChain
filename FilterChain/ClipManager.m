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
    //TODO skip thumbnail creation for clips we have already processed
    if (!cachedThumbnails) {
        cachedThumbnails = [[CachedThumbnails alloc] init];
    }
    
    
    //We're going to loop through the NSUrl's conatined in _storedClips and use the MPMoviePlayerController thumbnailImageAtTime method to create and store thumbs. Our cached Thumbnails class stores the thumbnails in ~/documents/Thumbnails to avoid expensive use of MPMoviePlayerController in creating the thumbs every time.
    _storedThumbnails = nil;
    _storedThumbnails = [NSMutableArray arrayWithCapacity:_storedClips.count];
    for (NSURL *clip in _storedClips) {
        UIImage* thumb = [cachedThumbnails thumbnailForURL:clip];
        [_storedThumbnails addObject:thumb];
    }
}

- (void)clipActionInvoked {
    NSInteger selected = activeClipSelection.selectedSegmentIndex;
    NSIndexPath *selectedPath = [[self.collectionView indexPathsForSelectedItems] objectAtIndex:0]; //should be the first object always, since we're forbidding multiple selections
    NSInteger selectedRow = selectedPath.row;
    Cell *cell = (Cell*)[self.collectionView cellForItemAtIndexPath:selectedPath];
    UISegmentedControl *aux = cell.auxControl;
    targetUrl = [_storedClips objectAtIndex:selectedRow];
    
    double delayToBegin= 0.2;
    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, delayToBegin* NSEC_PER_SEC);
    dispatch_after(startTime, dispatch_get_main_queue(), ^(void){
        if (selected == 0) {
            //Export the file!
            NSString *path = [targetUrl path];
            BOOL compatible = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path);
            if (compatible) {
                UISaveVideoAtPathToSavedPhotosAlbum(path, self, @selector(videoSaved:didFinishSavingWithError:contextInfo:), nil);
            }
            [aux setSelectedSegmentIndex:-1];
            
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
            
            //push an alertView to confirm the delete
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Delete This Clip?" message:nil delegate:self cancelButtonTitle:@"Nevermind" otherButtonTitles:@"Delete!", nil];
            [av show];
 
            [aux setSelectedSegmentIndex:-1];
        }
    });
    
}

-(void)dismissAlert:(UIAlertView *) alertView
{
    [alertView dismissWithClickedButtonIndex:0 animated:YES];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { //User selected "Delete"
        NSString *path = [targetUrl path];
        unlink([path UTF8String]); //This should delete it from Documents
        [self refreshStoredClips];
    }
}

/*- (void)alertViewCancel:(UIAlertView *)alertView {
    
    NSLog(@"cancel");
}*/

- (void)videoSaved:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    
    UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Clip Sent to Camera Roll!"
                                                 message:@"(It's also available when you sync to iTunes)"
                                                delegate:nil
                                       cancelButtonTitle:nil
                                       otherButtonTitles:nil];
    [av show];
    [self performSelector:@selector(dismissAlert:) withObject:av afterDelay:1.8];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.collectionView registerClass:[Cell class] forCellWithReuseIdentifier:@"cellID"];

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
    [self.collectionView registerClass:[Cell class] forCellWithReuseIdentifier:@"cellID"];
    [self.collectionView setAllowsMultipleSelection:NO];
    [self refreshStoredClips];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
