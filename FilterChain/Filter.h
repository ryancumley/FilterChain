//
//  Filter.h
//  FilterChain
//
//  Created by Ryan Cumley on 9/30/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Filter : NSManagedObject

@property (nonatomic, retain) NSString * filterDesignator;
@property (nonatomic, retain) NSString * imageName;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * paidOrFree;

@end
