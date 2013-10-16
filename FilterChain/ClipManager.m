//
//  ClipManager.m
//  FilterChain
//
//  Created by Ryan Cumley on 9/6/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import "ClipManager.h"
#import "Cell.h"
#import <MediaPlayer/MediaPlayer.h>

#define k_CellID @"cellID"
#define k_layoutItemSize CGSizeMake(160.0, 180.0)

@interface ClipManager ()

@property (strong, nonatomic) NSMutableArray *storedClips; //an arry of NSURl objects fetched from the user's Documents folder
@property (strong, nonatomic) NSMutableArray *storedThumbnails;

- (NSArray*)contentsOfDocuments;

@end



@implementation ClipManager

@synthesize storedClips = _storedClips, storedThumbnails = _storedThumbnails;
@synthesize moviePlayerDelegate = _moviePlayerDelegate;



#pragma mark Initialization and View Lifecycle
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
        flowLayout.itemSize = k_layoutItemSize;
        flowLayout.minimumInteritemSpacing = 0;
        UICollectionView *view = [[UICollectionView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320, 493) collectionViewLayout:flowLayout];
        self.collectionView = view;
        self.collectionView.allowsMultipleSelection = NO;
        [self.collectionView registerClass:[Cell class] forCellWithReuseIdentifier:k_CellID];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.collectionView registerClass:[Cell class] forCellWithReuseIdentifier:k_CellID];
    [self.collectionView setAllowsMultipleSelection:NO];
    [self refreshStoredClips];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSArray*)contentsOfDocuments {
    //fetch the stored clips
    fileManager = [[NSFileManager alloc] init];
    NSString *documentsFolder = [NSHomeDirectory() stringByAppendingString:@"/Documents"];
    NSURL *documentsPath = [NSURL fileURLWithPath:documentsFolder isDirectory:YES];
    NSError *error;
    NSArray *fetchedArray = [fileManager contentsOfDirectoryAtURL:documentsPath includingPropertiesForKeys:[NSArray arrayWithObject:NSURLCreationDateKey] options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
    
    //gather m4V files only
    NSMutableArray *moviesOnly = [[NSMutableArray alloc] init];
    for (NSURL *link in fetchedArray) {
        NSString* type = [link pathExtension];
        if ([type isEqualToString:@"m4v"]) {
            [moviesOnly addObject:link];
        }
    }
    
    //Order by NSURLCreationDateKey
    [moviesOnly sortUsingComparator:^NSComparisonResult(NSURL* a, NSURL* b){
        NSDate* a1 = [[a resourceValuesForKeys:[NSArray arrayWithObject:NSURLCreationDateKey] error:nil] objectForKey:NSURLCreationDateKey];
        NSDate* b1 = [[b resourceValuesForKeys:[NSArray arrayWithObject:NSURLCreationDateKey] error:nil] objectForKey:NSURLCreationDateKey];
        return [a1 compare:b1];
        }
     ];
    
    return moviesOnly;
    
}



#pragma mark Video Specific Actions

- (void)refreshStoredClips {
    _storedClips = nil;
    _storedClips = [NSMutableArray arrayWithArray:[self contentsOfDocuments]];
    [self generateThumbnails];
    [self.collectionView reloadData];
}

- (void)videoSaved:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    
    UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Clip Sent to Camera Roll!"
                                                 message:@"(It's also available when you sync to iTunes)"
                                                delegate:nil
                                       cancelButtonTitle:nil
                                       otherButtonTitles:nil];
    [av show];
    [self performSelector:@selector(dismissAlert:) withObject:av afterDelay:2.5];
}

- (void)generateThumbnails {
    if (!cachedThumbnails) {
        cachedThumbnails = [[CachedThumbnails alloc] init];
    }
    //We're going to loop through the NSUrl's conatined in _storedClips and use the MPMoviePlayerController thumbnailImageAtTime method to create and store thumbs. Our cached Thumbnails class stores the thumbnails in ~/documents/Thumbnails to avoid expensive use of MPMoviePlayerController in creating the thumbs every time. ***update*** deprecated in iOS 7, so using AVAssetImageGenerator instead.
    _storedThumbnails = nil;
    _storedThumbnails = [NSMutableArray arrayWithCapacity:_storedClips.count];
    for (NSURL *clip in _storedClips) {
        UIImage* thumb = [cachedThumbnails thumbnailForURL:clip];
        [_storedThumbnails addObject:thumb];
    }
}

- (void)attemptRotation {
    [UIViewController attemptRotationToDeviceOrientation];
}



#pragma mark Cell Selection and Actions
- (void)selectCellAtIndexPath:(NSIndexPath*)path {
    Cell *selectedCell = (Cell*)[self.collectionView cellForItemAtIndexPath:path];
    activeClipSelection = selectedCell.auxControl;
    [selectedCell.auxControl setSelectedSegmentIndex:-1];
    [selectedCell.auxControl setHidden:NO];
    selectedCell.backingView.backgroundColor = [UIColor colorWithRed:30.0f/255.0f green:36.0f/255.0f blue:51.0f/255.0f alpha:1.0f];
    
}

- (void)deSelectCellAtIndexPath:(NSIndexPath*)path {
    Cell *selectedCell = (Cell*)[self.collectionView cellForItemAtIndexPath:path];
    selectedCell.backingView.backgroundColor = [UIColor clearColor];
    [selectedCell.auxControl setHidden:YES];
    
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
        if (selected == 0) { //Export the file!
            NSString *path = [targetUrl path];
            BOOL compatible = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path);
            if (compatible) {
                UISaveVideoAtPathToSavedPhotosAlbum(path, self, @selector(videoSaved:didFinishSavingWithError:contextInfo:), nil);
            }
            [aux setSelectedSegmentIndex:-1];
            [self deSelectCellAtIndexPath:selectedPath];
            
        }
        
        else if (selected == 1) { //preview the file
            [_moviePlayerDelegate previewClipForUrl:targetUrl];
            [aux setSelectedSegmentIndex:-1];
            [self selectCellAtIndexPath:selectedPath];
        }
        
        else if (selected == 2) { //Trash the file!
            //push an alertView to confirm the delete
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Delete This Clip?" message:nil delegate:self cancelButtonTitle:@"Nevermind" otherButtonTitles:@"Delete", nil];
            [av show];
            [self selectCellAtIndexPath:selectedPath];
            [aux setSelectedSegmentIndex:-1];
        }
    });
    
}


#pragma mark UIAlertView Delegate Protocol Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { //User selected "Delete"
        if (!cachedThumbnails) {
            cachedThumbnails = [[CachedThumbnails alloc] init];
            }
        [cachedThumbnails deleteThumbnailForURL:targetUrl];
        NSString *path = [targetUrl path];
        unlink([path UTF8String]); //This should delete it from Documents
        [self refreshStoredClips];
    }
}

- (void)dismissAlert:(UIAlertView *) alertView
{
    [alertView dismissWithClickedButtonIndex:0 animated:YES];
}




#pragma mark UICollectionView DataSource and Delegate Protocol Methods

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.collectionView registerClass:[Cell class] forCellWithReuseIdentifier:k_CellID];

    Cell *cell = [cv dequeueReusableCellWithReuseIdentifier:k_CellID forIndexPath:indexPath];
    [cell.auxControl addTarget:self action:@selector(clipActionInvoked) forControlEvents:UIControlEventValueChanged];
    [cell.auxControl setHidden:YES];
    
    // load the image for this cell
    cell.image.image = [_storedThumbnails objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self selectCellAtIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self deSelectCellAtIndexPath:indexPath];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    NSInteger count = _storedClips.count;
    return count;
}


@end
