//
//  FilterBank.h
//  FilterChain
//
//  Created by Ryan Cumley on 9/9/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BankCell.h"
#import "Filter.h"

@interface FilterBank : UICollectionViewController

@property (strong, nonatomic) NSMutableArray* enabledFilters;
@property (strong, nonatomic) NSMutableArray* excludedFilters;
@property (strong, nonatomic) NSMutableArray* displayFilters;

- (void)loadFiltersFromStore;
- (void)activateFilterWithName:(NSString*)name andWithImage:(UIImage*)image forCell:(BankCell*)cell;
- (void)refreshDisplayFilters;
- (void)retireFilterFromActive:(Filter*)filter;

@end
