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
#import "LiveFilterView.h"

@interface ActiveFilterManager : NSObject <LiveFilterSliderDelegate>
{
    NSMutableArray* activeFilterNames;
    NSDictionary* namesAndDesignations;
}

@property (nonatomic, assign) id filterPipelineDelegate;
@property (strong, nonatomic) NSMutableArray* activeFilters;

- (void)setIntensitiesForFilter:(GPUImageFilter*)filter;
- (NSString*)designatorForName:(NSString*)name;
- (NSDictionary*)namesAndDesignations;
- (NSMutableArray*)activeFilterNames;
- (BOOL)addFilterNamed:(NSString*)name withOriginatingView:(UIView*)view;
- (void)removeFilter:(UITapGestureRecognizer*)tap;
- (CGRect)frameForPosition:(int)position;
- (void)updatePipeline;


@end

@protocol FilterPipelineDelegate <NSObject>

- (void)updatePipelineWithFilters:(NSArray*)filters;

@end
