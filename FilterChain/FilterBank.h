//
//  FilterBank.h
//  FilterChain
//
//  Created by Ryan Cumley on 9/9/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BankCell.h"

@interface FilterBank : UICollectionViewController

@property (strong, nonatomic) NSMutableArray* filtersAvailable;

- (void)loadFiltersFromStore;

@end
