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
#define k_sliderFrameStaionary CGRectMake(49,17,1,1)
#define k_killButtonFrame CGRectMake (0,110,40,40)
#define k_killButtonLabelFrame CGRectMake (0,0,40,40)
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
        [_slider addTarget:self action:@selector(pushUpdatedSliderValueToFilter:) forControlEvents:UIControlEventValueChanged];
        [_slider addTarget:self action:@selector(displayKillButton) forControlEvents:UIControlEventTouchDown];
        sliderIsStationary = NO;
        
        //Configure Kill Button
        _killButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _killButton.frame = k_killButtonFrame;
        _killButton.layer.masksToBounds = YES;
        _killButton.layer.cornerRadius = 10.0;
        _killButton.layer.borderColor = [UIColor orangeColor].CGColor;
        _killButton.layer.borderWidth = 2.0;
        [_killButton addTarget:self action:@selector(killThisFilter) forControlEvents:UIControlEventTouchUpInside];
        UILabel* buttonX = [[UILabel alloc] initWithFrame:k_killButtonLabelFrame];
        buttonX.textColor = [UIColor redColor];
        buttonX.text = @"X";
        buttonX.textAlignment = NSTextAlignmentCenter;
        [_killButton addSubview:buttonX];
        
        //Configure view
        self.backgroundColor = [UIColor clearColor]; //switch to clear when done testing
        [self addSubview:_slider];
        [self addSubview:_killButton];
        [_killButton setHidden:YES];
        displayingKillButton = NO;
    }
    
    return self;
}

- (void)killThisFilter {
    [self.sliderDelegate killLiveFilterWithTag:self.tag];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self hideKillButton];
}

- (void)displayKillButton {
    if (!displayingKillButton) {
        [_killButton setHidden:NO];
        displayingKillButton = YES;
        [self performSelector:@selector(hideKillButton) withObject:nil afterDelay:2.5];
    }
    
}

- (void)hideKillButton {
    [_killButton setHidden:YES];
    displayingKillButton = NO;
}

- (void)makeSliderStaionary:(BOOL)stationary {
    if (stationary) {
        sliderIsStationary = YES;
        [_slider setMinimumTrackTintColor:[UIColor clearColor]];
        [_slider setMaximumTrackTintColor:[UIColor clearColor]];
    }
    if (!stationary) {
        sliderIsStationary = NO;
        [_slider setMinimumTrackTintColor:[UIColor blackColor]];
        [_slider setMaximumTrackTintColor:[UIColor whiteColor]];
        
    }
    
}

- (BOOL)isSliderStationary {
    return sliderIsStationary;
}

- (void)pushUpdatedSliderValueToFilter:(UIEvent*)event {
    if (sliderIsStationary) {
        [_slider cancelTrackingWithEvent:event];
        [_slider setValue:0.7];
        return;
    }
    [self.sliderDelegate liveFilterWithTag:self.tag isSendingValue:_slider.value];
}

@end
