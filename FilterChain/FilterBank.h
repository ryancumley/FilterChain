//
//  FilterBank.h
//  FilterChain
//
//  Created by Ryan Cumley on 9/9/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FreeCell.h"
#import "NavCell.h"
#import "Filter.h"
#import "ActiveFilterManager.h"

@interface FilterBank : UICollectionViewController <ActiveFilterToFilterBank>

@property (nonatomic, assign) id mvcDelegate;

- (BOOL)successfullyActivatedFilterWithName:(NSString*)name andWithImage:(UIImage*)image forCell:(FreeCell*)cell;

@end

@protocol FilterBankToMVC <NSObject>

- (void)userSelectedAPremiumFilter;

@end
