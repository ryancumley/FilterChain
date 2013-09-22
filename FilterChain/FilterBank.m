//
//  FilterBank.m
//  FilterChain
//
//  Created by Ryan Cumley on 9/9/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import "FilterBank.h"
#import "AppDelegate.h"
#import "ActiveFilterManager.h"
#import <QuartzCore/QuartzCore.h>

#define kCellID @"bankCellID"
#define k_filterBankFrame CGRectMake(0.0, 0.0, 320.0, 99.0)

@interface FilterBank ()

- (NSMutableArray*)excludedFilters;

@end

@implementation FilterBank

@synthesize enabledFilters = _enabledFilters, excludedFilters = _excludedFilters, displayFilters = _displayFilters;

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
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        flowLayout.itemSize = CGSizeMake(95.0, 95.0);
        UICollectionView *view = [[UICollectionView alloc] initWithFrame:k_filterBankFrame collectionViewLayout:flowLayout];
        self.collectionView = view;
        [self.collectionView registerClass:[BankCell class] forCellWithReuseIdentifier:@"bankCellID"];
        [self.collectionView setBackgroundColor:[UIColor clearColor]];
        [self loadFiltersFromStore];
        _excludedFilters = nil;
        [self refreshDisplayFilters];
    }
    return self;
}

- (void)refreshDisplayFilters {
    //Check the _enabledFilters against the _excludedFilters to populate our _displayFilters
    _displayFilters = nil;
    _displayFilters = [NSMutableArray arrayWithArray:_enabledFilters]; //by copying _enabledFilters, we can retain the alphabetical order created by the original fetch, without having to re-sort _display filters every time.
    for (Filter* filter in _excludedFilters) {
        [_displayFilters removeObjectIdenticalTo:filter];
    }
}

- (NSMutableArray*)excludedFilters {
    if (_excludedFilters == nil) {
        _excludedFilters = [[NSMutableArray alloc] init];
    }
    return _excludedFilters;
}

- (void)retireFilterFromActive:(id)filter {
    [_excludedFilters removeObjectIdenticalTo:filter];
    [self refreshDisplayFilters];
    
    //find the index of our desired filter
    int index = 0;
    BOOL found = NO;
    do {
        if ([_displayFilters objectAtIndex:index] == filter) {
            found = YES;
            index -= 1; //otherwise ending state will be incremented too far
        }
        index += 1;
    } while (!found);
    
    NSIndexPath* insertionPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.collectionView insertItemsAtIndexPaths:[NSArray arrayWithObjects:insertionPath, nil]];
    [self.collectionView reloadData];
}

- (void)loadFiltersFromStore {
    _enabledFilters = nil;
    AppDelegate* delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext* moc = [delegate managedObjectContext];
    NSEntityDescription* description = [NSEntityDescription entityForName:@"Filter" inManagedObjectContext:moc];
    NSSortDescriptor* descriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    [request setEntity:description];
    [request setSortDescriptors:[NSArray arrayWithObject:descriptor]];
    NSError *error;
    _enabledFilters = [NSMutableArray arrayWithArray:[moc executeFetchRequest:request error:&error]];
    if (error) {
        NSLog(@"%@",error.localizedDescription);
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _displayFilters.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BankCell* cell = [cv dequeueReusableCellWithReuseIdentifier:kCellID forIndexPath:indexPath];
    cell.label.text = [[_displayFilters objectAtIndex:indexPath.row] name];
    cell.label.backgroundColor = [UIColor clearColor];
    NSString*targetName = [[_displayFilters objectAtIndex:indexPath.row] imageName];
    UIImage *image = [UIImage imageNamed:targetName];
    cell.image.image = image;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    //Instantiate the active filter and tell mVC to move it into position
    BankCell* cell = (BankCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    NSString* name = cell.label.text;
    UIImage* newImage = [cell.image.image copy];
    [self activateFilterWithName:name andWithImage:newImage forCell:cell];
    
    //remove this filter from the filterBank's data source
    [[self excludedFilters] addObject:[_displayFilters objectAtIndex:indexPath.row]];
    [self refreshDisplayFilters];
    [self.collectionView deleteItemsAtIndexPaths:[NSArray arrayWithObjects:(NSIndexPath*)indexPath, nil]];
}

- (void)activateFilterWithName:(NSString*)name andWithImage:(UIImage*)image forCell:(BankCell *)cell {
    AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    MainViewController* mvc = (MainViewController*)delegate.window.rootViewController;
    UIImageView*newActiveFilter = [[UIImageView alloc] init];
    newActiveFilter.layer.cornerRadius = 8.0;
    newActiveFilter.layer.masksToBounds = YES;
    newActiveFilter.layer.borderColor = [UIColor orangeColor].CGColor;
    newActiveFilter.layer.borderWidth = 2.0;
    float xOffset = cell.frame.origin.x - self.collectionView.contentOffset.x;
    float yOffset = [[UIScreen mainScreen] bounds].size.height - 100.0;
    newActiveFilter.frame = CGRectMake(xOffset, yOffset, 44.0, 44.0); //yOffset will be too deep in Landscape. address this sometime, maybe.
    newActiveFilter.image = image;
    newActiveFilter.userInteractionEnabled = YES;
    //Add targeting behavior
    UITapGestureRecognizer* recognizer = [[UITapGestureRecognizer alloc] initWithTarget:mvc.activeFilterManager action:@selector(removeFilter:)];
    recognizer.numberOfTapsRequired = 1;
    recognizer.enabled = YES;
    [newActiveFilter addGestureRecognizer:recognizer];

    [mvc.previewLayer addSubview:newActiveFilter];
    [mvc.activeFilterManager addFilterNamed:name withOriginatingView:newActiveFilter];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
