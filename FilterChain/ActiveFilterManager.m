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
#define k_h 150.0
#define k_leftMargin 10.0
#define k_topMargin 10.0

#define k_maxActive 6

@interface ActiveFilterManager ()

- (void)retireFilterNamed:(NSString*)name;
- (UIImage*)scaledDownVersionOf:(UIImage*)source;

@end


@implementation ActiveFilterManager

@synthesize filterPipelineDelegate = _filterPipelineDelegate, activeFilters = _activeFilters;

- (id)init {
    self = [super init];
    if (self) {
        //assign our delegate
        _filterPipelineDelegate = [(MainViewController*)[[[[UIApplication sharedApplication]delegate]window]rootViewController] recordingManager];
        
        UIViewController* mvc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
        //Configure the 6 LiveFilterView instances
        for (int i = 1; i <= k_maxActive; i++) {
            LiveFilterView* newLiveFilter = [[LiveFilterView alloc] init];
            newLiveFilter.tag = i; //reasonably sure this is the only place in the whole app I'm using view tags.
            [newLiveFilter setSliderDelegate:self];
            [newLiveFilter setFrame:[self frameForPosition:i]];
            [mvc.view addSubview:newLiveFilter];
            [newLiveFilter setHidden:YES];
        }
    }
    
    return self;
}

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

- (NSMutableArray*)activeFilterNames {
    if (!activeFilterNames) {
        activeFilterNames = [[NSMutableArray alloc] init];
    }
    return activeFilterNames;
}

- (NSString*)designatorForName:(NSString *)name {
    namesAndDesignations = [self namesAndDesignations];
    NSString* designator = [namesAndDesignations valueForKey:name];
    return designator;
}

- (void)updatePipeline {
    if (activeFilterNames.count == 0) {
        _activeFilters = nil;
    }
    else {
        _activeFilters = [[NSMutableArray alloc] init];
        for (NSString* name in activeFilterNames) {
            NSString* designator = [self designatorForName:name];
            GPUImageFilter *newConversion = [[NSClassFromString(designator) alloc] init];
            [_activeFilters addObject:newConversion];
        }
    }
    
    //set intensity parameters as needed for the filters
    for (GPUImageFilter* filter in _activeFilters) {
        [self setIntensitiesForFilter:(GPUImageFilter*)filter];
     }
    
     //now send these filters to the pipeline, via our delegate protocol
    [self.filterPipelineDelegate updatePipelineWithFilters:_activeFilters];
}

- (BOOL)addFilterNamed:(NSString *)name withOriginatingView:(UIView *)view {
    
    //append this filter to the end of the activeFilters array
    int currentCount = [[self activeFilters] count] + 1;
    if (currentCount > k_maxActive) { //fail if we already have enough active
        [view removeFromSuperview];
        view = nil;
        return FALSE; //tells the caller to clean up and restore state like it was before the call
    }
    
    [[self activeFilterNames] addObject:name];

    //animate the view into position
    CGRect target = [self frameForPosition:currentCount];
    [UIView animateWithDuration:0.2
                     animations:^(void) {
                         view.frame = target;
                     }
     ];
    
    UIViewController* mvc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    LiveFilterView* destination = (LiveFilterView*)[mvc.view viewWithTag:currentCount];
    UIImage* bigThumb = [(UIImageView*)view image];
    UIImage* smallThumb = [self scaledDownVersionOf:bigThumb];
    [destination.slider setThumbImage:smallThumb forState:UIControlStateNormal];
    [destination.slider setThumbImage:smallThumb forState:UIControlStateHighlighted];
    [destination setHidden:NO];
    [destination.slider setValue:0.7 animated:YES];
    [view removeFromSuperview];
    view = nil;
    
    //update the filter pipeline
    [self updatePipeline];
    return YES;
}

- (void)removeFilter:(UITapGestureRecognizer*)tap {
    //remove the target filter
    UIView* target = tap.view;
    int position = target.tag;
    NSString* name = [activeFilterNames objectAtIndex:position - 1];
    [self retireFilterNamed:name];
    [activeFilterNames removeObjectAtIndex:position - 1];
    
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
    float origin_X = k_leftMargin + ((position - 1) * (k_w + k_leftMargin));
    CGRect returnRect = CGRectMake(origin_X, k_topMargin, k_w, k_h);
    return returnRect;
}

- (UIImage*)scaledDownVersionOf:(UIImage *)source {
    CGImageRef sourceCG = source.CGImage;
    UIImage* smaller = [UIImage imageWithCGImage:sourceCG scale:(65.0 / 40.0) orientation:UIImageOrientationUp];
    return smaller;
}

#pragma mark -
#pragma mark LiveFilterSliderDelegate Methods

- (void)liveFilterWithTag:(int)tag isSendingValue:(CGFloat)value {
    //point to the correct filter
    GPUImageFilter* target = [_activeFilters objectAtIndex:(tag - 1)];
    //NSLog(@"target.class: %@",target.class); //our pointer has the class that we desire. Next adjust the appropriate constant for the filter

}

@end
