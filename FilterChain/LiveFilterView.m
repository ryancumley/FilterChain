//
//  LiveFilterView.m
//  FilterChain
//
//  Created by Ryan Cumley on 9/23/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import "LiveFilterView.h"

#define k_parentFrameSize (40.0,150.0)
#define k_sliderFramePreRotation CGRectMake(-30.0,33.0,100.0,34.0)
#define k_killButtonFrame CGRectMake (0,110,40,40)
@implementation LiveFilterView

@synthesize slider = _slider, killButton = _killButton, name = _name, filter= _filter;

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //Configure Slider
        _slider = [[UISlider alloc] initWithFrame:k_sliderFramePreRotation];
        CGAffineTransform trans = CGAffineTransformMakeRotation(M_PI * -0.5);
        _slider.transform = trans;
        _slider.minimumTrackTintColor = [UIColor blackColor];
        _slider.maximumTrackTintColor = [UIColor whiteColor];
        [_slider addTarget:self action:@selector(pushUpdatedSliderValueToFilter) forControlEvents:UIControlEventValueChanged];
        
        //Configure Kill Button
        _killButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _killButton.frame = k_killButtonFrame;
        _killButton.layer.masksToBounds = YES;
        _killButton.layer.cornerRadius = 10.0;
        _killButton.layer.borderColor = [UIColor whiteColor].CGColor;
        _killButton.layer.borderWidth = 2.0;
        //Can I setup the touchUpInside listner here?
        
        //Configure view
        self.backgroundColor = [UIColor clearColor]; //switch to clear when done testing
        [self addSubview:_slider];
        [self addSubview:_killButton];
    }
    
    return self;
}

- (void)loadWithName:(NSString*)name {
    
}

- (void)clearAndHide {
    
}

- (void)displayKillButton {
    
}

- (void)pushUpdatedSliderValueToFilter {
    [self.sliderDelegate liveFilterWithTag:self.tag isSendingValue:_slider.value];
}

@end
