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

@end

@implementation FilterBank

@synthesize filtersAvailable = _filtersAvailable;

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
    }
    return self;
}

- (void)loadFiltersFromStore {
    _filtersAvailable = nil;
    AppDelegate* delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext* moc = [delegate managedObjectContext];
    NSEntityDescription* description = [NSEntityDescription entityForName:@"Filter" inManagedObjectContext:moc];
    NSSortDescriptor* descriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    [request setEntity:description];
    [request setSortDescriptors:[NSArray arrayWithObject:descriptor]];
    NSError *error;
    _filtersAvailable = [NSMutableArray arrayWithArray:[moc executeFetchRequest:request error:&error]];
    if (error) {
        NSLog(@"%@",error.localizedDescription);
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _filtersAvailable.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BankCell* cell = [cv dequeueReusableCellWithReuseIdentifier:kCellID forIndexPath:indexPath];
    cell.label.text = [[_filtersAvailable objectAtIndex:indexPath.row] name];
    cell.label.backgroundColor = [UIColor clearColor];
    NSString*targetName = [[_filtersAvailable objectAtIndex:indexPath.row] imageName];
    UIImage *image = [UIImage imageNamed:targetName];
    cell.image.image = image;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    MainViewController* mvc = (MainViewController*)delegate.window.rootViewController;
    
    BankCell* cell = (BankCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    NSString* name = cell.label.text;
    UIImage* newImage = [cell.image.image copy];
    //UIImage* newImage = [UIImage imageNamed:@"OrangeSquareMin.jpg"];    //TODO, wire this up to the live images
    UIImageView*newActiveFilter = [[UIImageView alloc] init];
    newActiveFilter.layer.cornerRadius = 8.0;
    newActiveFilter.layer.masksToBounds = YES;
    newActiveFilter.layer.borderColor = [UIColor orangeColor].CGColor;
    newActiveFilter.layer.borderWidth = 2.0;
    float xOffset = cell.frame.origin.x - self.collectionView.contentOffset.x;
    float yOffset = [[UIScreen mainScreen] bounds].size.height - 100.0;
    newActiveFilter.frame = CGRectMake(xOffset, yOffset, 44.0, 44.0); //yOffset will be too deep in Landscape. address this sometime, maybe.
    newActiveFilter.image = newImage;
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
