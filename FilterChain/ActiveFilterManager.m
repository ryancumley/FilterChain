//
//  ActiveFilterManager.m
//  FilterChain
//
//  Created by Ryan Cumley on 9/11/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import "ActiveFilterManager.h"
#import "AppDelegate.h"
#import "MainViewController.h"
#import "FilterBank.h"

#define k_w 40.0
#define k_h 40.0
#define k_leftMargin 10.0
#define k_topMargin 10.0

#define k_maxActive 6

@interface ActiveFilterManager ()

- (void)retireFilterNamed:(NSString*)name;

@end


@implementation ActiveFilterManager

- (void)setIntensitiesForFilter:(GPUImageFilter*)filter {
    if ([filter class] == [GPUImageHighlightShadowFilter class]) {
        GPUImageHighlightShadowFilter* calibrated = (GPUImageHighlightShadowFilter*)filter;
        [calibrated setShadows:0.7];
        [calibrated setHighlights:0.8];
        filter = calibrated;
    }
}

- (NSDictionary*)namesAndDesignations {
    if (namesAndDesignations != nil) {
        return namesAndDesignations;
    }
    
    //Fetch the filters from the persistent data store
    AppDelegate* delegate = (AppDelegate*)[[UIApplication sharedApplication]delegate];
    NSManagedObjectContext* moc = [delegate managedObjectContext];
    NSEntityDescription* description = [NSEntityDescription entityForName:@"Filter" inManagedObjectContext:moc];
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    [request setEntity:description];
    NSError* error;
    NSArray* fetchedResults = [moc executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"%@",error.localizedDescription);
    }
    
    
    //Loop through and store the name/designators as key/value pairs
    NSMutableArray* keys = [[NSMutableArray alloc] initWithCapacity:fetchedResults.count];
    NSMutableArray* values = [[NSMutableArray alloc] initWithCapacity:fetchedResults.count];
    for (Filter* filter in fetchedResults) {
        [keys addObject:filter.name];
        [values addObject:filter.filterDesignator];
    }
    
    NSDictionary* returnValue = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    return returnValue;
}

- (NSMutableArray*)activeFilters {
    if (!activeFilters) {
        activeFilters = [[NSMutableArray alloc] init];
    }
    return activeFilters;
}

- (NSString*)designatorForName:(NSString *)name {
    namesAndDesignations = [self namesAndDesignations];
    NSString* designator = [namesAndDesignations valueForKey:name];
    return designator;
}

- (void)updatePipeline {
    NSMutableArray* filters;
    if (activeFilters.count == 0) {
        filters = nil;
    }
    else {
        filters = [[NSMutableArray alloc] init];
        for (NSString* name in activeFilters) {
            NSString* designator = [self designatorForName:name];
            GPUImageFilter *newConversion = [[NSClassFromString(designator) alloc] init];
            [filters addObject:newConversion];
        }
    }
    
    //set intensity parameters as needed for the filters
    for (GPUImageFilter* filter in filters) {
        [self setIntensitiesForFilter:(GPUImageFilter*)filter];
     }
    
     
    //Now send the pipeline to the mainView
    AppDelegate* delegate = (AppDelegate*)[[UIApplication sharedApplication]delegate];
    MainViewController* mvc = (MainViewController*)delegate.window.rootViewController;
    [mvc refreshPipelineWithFilters:filters];
    
}

- (void)addFilterNamed:(NSString *)name withOriginatingView:(UIView *)view {
    //append this filter to the end of the activeFilters array
    int currentCount = [[self activeFilters] count] + 1;
    if (currentCount > k_maxActive) {
        [view removeFromSuperview];
        view = nil;
        return;
    }
    
    view.tag = currentCount;
    [[self activeFilters] addObject:name];

    
    //animate the view into position
    CGRect target = [self frameForPosition:currentCount];
    [UIView animateWithDuration:0.2
                     animations:^(void) {
                         view.frame = target;
                     }
     ];
    
    //update the filter pipeline
    [self updatePipeline];
}

- (void)removeFilter:(UITapGestureRecognizer*)tap {
    //remove the target filter
    UIView* target = tap.view;
    int position = target.tag;
    NSString* name = [activeFilters objectAtIndex:position -1];
    [self retireFilterNamed:name];
    [activeFilters removeObjectAtIndex:position - 1];
    
    //animate the surviving filters into position
    AppDelegate* delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    MainViewController* mvc = (MainViewController*)delegate.window.rootViewController;
    if (position < k_maxActive) {
        for (int i = (position + 1); i <= k_maxActive; i++) {
            UIView* decrement = [mvc.previewLayer viewWithTag:i];
            decrement.tag -= 1;
            CGRect ending = [self frameForPosition:(i-1)];
            [UIView animateWithDuration:0.2
                             animations:^(void) {
                                 decrement.frame = ending;
                             }
             ];
        }
    }
    
    [target removeFromSuperview];
    target = nil;
    
    //update the filter pipeline
    [self updatePipeline];
}

- (void)retireFilterNamed:(NSString *)name {
    //retrieve a filter instance of Filter and pass it to mVC.filterBank to place it back in service
    AppDelegate* delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext* moc = [delegate managedObjectContext];
    NSEntityDescription* description = [NSEntityDescription entityForName:@"Filter" inManagedObjectContext:moc];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"name == %@",name];
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    [request setEntity:description];
    [request setPredicate:predicate];
    NSError *error;
    NSArray *fetch = [moc executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"%@",error.localizedDescription);
    }
    Filter* filter = (Filter*)[fetch objectAtIndex:0]; //Assuming Filter contains no duplicates, fetch.count will always = 1
    MainViewController* mvc = (MainViewController*)delegate.window.rootViewController;
    [mvc.filterBank retireFilterFromActive:filter];
    
}

- (CGRect)frameForPosition:(int)position {
    float origin_X = k_leftMargin + ((position - 1) * (k_h + k_leftMargin));
    CGRect returnRect = CGRectMake(origin_X, k_topMargin, k_w, k_h);
    return returnRect;
}

@end
