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

@interface ActiveFilterManager : NSObject <LiveFilterActionDelegate>
{
    NSMutableArray* activeFilterNames;
    NSDictionary* namesAndDesignations;
    NSArray* namesOfStationaryFilters;
}

@property (nonatomic, assign) id recordingManagerDelegate;
@property (nonatomic, assign) id filterBankDelegate;
@property (nonatomic, assign) id mvcDelegate;
@property (strong, nonatomic) NSMutableArray* activeFilters;

- (NSString*)designatorForName:(NSString*)name;
- (NSDictionary*)namesAndDesignations;
- (NSMutableArray*)activeFilterNames;
- (BOOL)addFilterNamed:(NSString*)name withOriginatingView:(UIView*)view;
- (CGRect)frameForPosition:(int)position;
- (void)updatePipeline;


@end

@protocol ActiveFilterToRecordingManager <NSObject>

- (void)updatePipelineWithFilters:(NSArray*)filters;

@end

@protocol ActiveFilterToFilterBank <NSObject>

- (void)retireFilter:(Filter*)filter;

@end

@protocol ActiveFilterToMVC <NSObject>

- (void)removeLiveFilterWithTag:(int)tag;

@end
