//
//  ActiveFilterManager.h
//  FilterChain
//
//  Created by Ryan Cumley on 9/11/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImage.h"
#import "Filter.h"

@interface ActiveFilterManager : NSObject
{
    NSMutableArray* activeFilters;
    NSDictionary* namesAndDesignations;
}

@property (nonatomic, assign) id filterPipelineDelegate;

- (void)setIntensitiesForFilter:(GPUImageFilter*)filter;
- (NSString*)designatorForName:(NSString*)name;
- (NSDictionary*)namesAndDesignations;
- (NSMutableArray*)activeFilters;
- (void)addFilterNamed:(NSString*)name withOriginatingView:(UIView*)view;
- (void)removeFilter:(UITapGestureRecognizer*)tap;
- (CGRect)frameForPosition:(int)position;
- (void)updatePipeline;


@end

@protocol FilterPipelineDelegate <NSObject>

- (void)updatePipelineWithFilters:(NSArray*)filters;

@end
