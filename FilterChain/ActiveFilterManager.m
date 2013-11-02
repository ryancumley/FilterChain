//
//  ActiveFilterManager.m
//  FilterChain
//
//  Created by Ryan Cumley on 9/11/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import "ActiveFilterManager.h"
#import "AppDelegate.h"

#define k_w 40.0
#define k_h 150.0
#define k_leftMargin 10.0
#define k_topMargin 10.0

#define k_maxActive 6

@interface ActiveFilterManager ()

- (void)retireFilterNamed:(NSString*)name;
- (UIImage*)scaledDownVersionOf:(UIImage*)source;
- (BOOL)stationarySliderNeededForName:(NSString*)name;
- (NSString*)designatorForName:(NSString*)name;
- (NSDictionary*)namesAndDesignations;
- (NSMutableArray*)activeFilterNames;
- (CGRect)frameForPosition:(int)position;

@end


@implementation ActiveFilterManager

@synthesize recordingManagerDelegate = _recordingManagerDelegate, activeFilters = _activeFilters, mvcDelegate = _mvcDelegate;



#pragma mark -
#pragma mark Initialization and Convenience Methods

- (id)init {
    self = [super init];
    if (self) {
        UIViewController* mvc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
        //Configure the 6 LiveFilterView instances
        for (int i = 1; i <= k_maxActive; i++) {
            LiveFilterView* newLiveFilter = [[LiveFilterView alloc] init];
            newLiveFilter.tag = i; //reasonably sure this is the only place in the whole app I'm using view tags.
            [newLiveFilter setActionDelegate:self];
            [newLiveFilter setFrame:[self frameForPosition:i]];
            [mvc.view addSubview:newLiveFilter];
            [newLiveFilter setHidden:YES];
        }
    }
    
    return self;
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

- (BOOL)stationarySliderNeededForName:(NSString *)name {
    if (namesOfStationaryFilters == nil) {
        namesOfStationaryFilters = [NSArray arrayWithObjects:
                                    @"Amatorka",
                                    @"Edges",
                                    @"Grayscale",
                                    @"Inversion",
                                    @"Neon Edge",
                                    @"Sepia",
                                    @"Sketch",
                                    @"Soft",
                                    @"Vignette", nil];
    }
    return [namesOfStationaryFilters containsObject:name];
}

- (NSMutableArray*)activeFilterNames {
    if (!activeFilterNames) {
        activeFilterNames = [[NSMutableArray alloc] init];
    }
    return activeFilterNames;
}

- (NSMutableArray*)activeFilters {
    if (!_activeFilters) {
        _activeFilters = [[NSMutableArray alloc] init];
    }
    return _activeFilters;
}

- (NSString*)designatorForName:(NSString *)name {
    namesAndDesignations = [self namesAndDesignations];
    NSString* designator = [namesAndDesignations valueForKey:name];
    return designator;
}

- (CGRect)frameForPosition:(int)position {
    float origin_X = k_leftMargin + ((position - 1) * (k_w + k_leftMargin));
    CGRect returnRect = CGRectMake(origin_X, k_topMargin, k_w, k_h);
    return returnRect;
}

- (UIImage*)scaledDownVersionOf:(UIImage *)source {
    CGImageRef sourceCG = source.CGImage;
    UIImage* smaller = [UIImage imageWithCGImage:sourceCG scale:(320.0 / 40.0) orientation:UIImageOrientationRight];
    return smaller;
}





#pragma mark -
#pragma mark Management of Active Filters
- (BOOL)addFilterNamed:(NSString *)name withOriginatingView:(UIView *)view {
    
    //Fail early if we're already at capacity
    int currentCount = [[self activeFilters] count] + 1;
    if (currentCount > k_maxActive) { //fail if we already have enough active
        [view removeFromSuperview];
        view = nil;
        return FALSE; //tells the caller to clean up and restore state like it was before the call
    }
    
    //update the Arrays with the new name/filter respectively
    [[self activeFilterNames] addObject:name];
    NSString* designator = [self designatorForName:name];
    GPUImageFilter *newConversion = [[NSClassFromString(designator) alloc] init];
    [[self activeFilters] addObject:newConversion];

    //animate the view into position
    CGRect target = [self frameForPosition:currentCount];
    [UIView animateWithDuration:0.2
                     animations:^(void) {
                         view.frame = target;
                     }
     ];
    
    //scale down and push the thumbnail image to the correct LiveFilterView instance
    UIViewController* mvc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    LiveFilterView* destination = (LiveFilterView*)[mvc.view viewWithTag:currentCount];
    UIImage* bigThumb = [(UIImageView*)view image];
    UIImage* smallThumb = [self scaledDownVersionOf:bigThumb];
    [destination.slider setThumbImage:smallThumb forState:UIControlStateNormal];
    [destination.slider setThumbImage:smallThumb forState:UIControlStateHighlighted];
    [destination setHidden:NO];
    [destination.slider setValue:0.7 animated:YES];
    [destination makeSliderStaionary:[self stationarySliderNeededForName:name]];
    
    [view removeFromSuperview];
    view = nil;
    
    //update the filter pipeline
    [self updatePipeline];
    [self liveFilterWithTag:currentCount isSendingValue:0.7]; //get the filter started at some value
    return YES;
}

- (void)retireFilterNamed:(NSString *)name {
    //retrieve a filter instance of Filter and pass it to filterBank to place it back in service
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
    [self.filterBankDelegate retireFilter:filter]; //Sends a generic instance of the NSManagedObject Filter* to be placed back in service
}

- (void)updatePipeline {
    if (activeFilterNames.count == 0) {
        _activeFilters = nil;
    }
    
     //now send these filters to the pipeline, via our delegate protocol
    [self.recordingManagerDelegate updatePipelineWithFilters:_activeFilters];
}











#pragma mark -
#pragma mark LiveFilterSliderDelegate Methods

- (void)liveFilterWithTag:(int)tag isSendingValue:(CGFloat)value {
    //point to the correct filter
    GPUImageFilter* target = [_activeFilters objectAtIndex:(tag - 1)];
    Class targetClass = [target class];
    
    //adjust the right value, corresponding to filter Type, as needed
    if (targetClass == [GPUImageHighlightShadowFilter class]) {
        [(GPUImageHighlightShadowFilter*)target setShadows:value]; //setting just shadows for now. Use a (1-value) sort of thing for highlights if desired later
        return;
    }
    
    if ([target class] == [GPUImageSaturationFilter class]) {
        [(GPUImageSaturationFilter*)target setSaturation:(2 * value)]; //ranges from 0-2 with 1 as neutral
        return;
    }
    
    if ([target class] == [GPUImageContrastFilter class]) {
           [(GPUImageContrastFilter*)target setContrast:(4 * value)]; //ranges from 0-4 with 1.0 as normal
        return;
    }
    
    if ([target class] == [GPUImageExposureFilter class]) {
           [(GPUImageExposureFilter*)target setExposure:(20 * (value - 0.5))]; //ranges from -10-10, 0 is neutral
        return;
    }
    
    if ([target class] == [GPUImageSharpenFilter class]) {
           [(GPUImageSharpenFilter*)target setSharpness:(8 *(value - 0.5))]; //ranges from -4-4, 0 is neutral
        return;
    }
    
    if ([target class] == [GPUImageGammaFilter class]) {
           [(GPUImageGammaFilter*)target setGamma:(3 * value)]; //ranges from 0-3 with 1 as normal
        return;
    }
    
    if ([target class] == [GPUImageAdaptiveThresholdFilter class]) {
            [(GPUImageAdaptiveThresholdFilter*)target setBlurRadiusInPixels:(5 * value)];
        return;
    }
    
    if ([target class] == [GPUImagePixellateFilter class]) {
            [(GPUImagePixellateFilter*)target setFractionalWidthOfAPixel:(value / 10)];
        return;
    }
    
    if ([target class] == [GPUImageToonFilter class]) {
            [(GPUImageToonFilter*)target setThreshold:0.2];
            if (value > 0.0) {//prevents total darkness at 0.0
                [(GPUImageToonFilter*)target setQuantizationLevels:(20 * value)];
            }
        return;
    }
    
    if ([target class] == [GPUImageGaussianBlurFilter class]) {
               [(GPUImageGaussianBlurFilter*)target setBlurRadiusInPixels:(3 * value)];
        return;
    }
    
    if ([target class] == [GPUImageTiltShiftFilter class]) {
        float flip = 1 - value;
        if (value > 0.1 && value < 0.9) {
            [(GPUImageTiltShiftFilter*)target setTopFocusLevel:(flip - 0.1)];
            [(GPUImageTiltShiftFilter*)target setBottomFocusLevel:(flip + 0.1)];
            [(GPUImageTiltShiftFilter*)target setFocusFallOffRate:0.15];
        }
        return;
    }
}

- (void)killLiveFilterWithTag:(int)tag {
    //tell FilterBank to put this filter back into the available pool
    GPUImageFilter* targetFilter = [_activeFilters objectAtIndex:(tag - 1)];
    [self retireFilterNamed:[activeFilterNames objectAtIndex:(tag - 1)]];
    
    //update the name and filter arrays in this class
    [_activeFilters removeObject:targetFilter];
    [activeFilterNames removeObjectAtIndex:(tag - 1)];
    
    //update the appearance of the LiveFilterView's displayed in the main view
    [self.mvcDelegate removeLiveFilterWithTag:tag];
    
    [self updatePipeline];
}



@end
