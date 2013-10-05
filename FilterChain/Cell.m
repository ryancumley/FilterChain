//
//  Cell.m
//  UrbanSky
//
//  Created by Ryan Cumley on 8/28/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import "Cell.h"
#import <QuartzCore/QuartzCore.h>

#define k_backingViewFrame CGRectMake(0.0, 0.0, 160.0, 150.0)
//TODO decide if I care about the magic numbers in this short class to define them properly

@implementation Cell

@synthesize image = _image;
@synthesize auxControl = _auxControl;
@synthesize backingView = _backingView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //prepare backing views
        _backingView = [[UIView alloc] initWithFrame:k_backingViewFrame];
        _backingView.backgroundColor = [UIColor clearColor];
        _backingView.layer.cornerRadius = 8.0;
        _backingView.layer.masksToBounds = YES;
        
        
        //prepare foreground elements
        _image = [[UIImageView alloc] initWithFrame:CGRectMake(8.0, 6.0, 144.0, 144.0)];
        _image.layer.cornerRadius = 8.0;
        _image.layer.masksToBounds = YES;
        _image.layer.borderColor = [UIColor colorWithRed:64.0f/255.0f green:71.0f/255.0f blue:90.0f/255.0f alpha:1.0].CGColor;
        _image.layer.borderWidth = 2.0;
        _image.contentMode = UIViewContentModeScaleAspectFill;
        _auxControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"export", @"play", @"delete", nil]];
        _auxControl.frame = CGRectMake(0.0, 150.0, 160.0, 30.0);
        _auxControl.segmentedControlStyle = UISegmentedControlStyleBar;
        
        //add it all in
        [self.contentView addSubview:_backingView];
        [self.contentView addSubview:_image];
        [self.contentView addSubview:_auxControl];
    }
    return self;
}

- (void)prepareForReuse {
    self.selected = NO;
    _backingView.backgroundColor = [UIColor clearColor];
}

@end
