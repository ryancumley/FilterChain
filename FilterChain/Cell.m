//
//  Cell.m
//  UrbanSky
//
//  Created by Ryan Cumley on 8/28/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import "Cell.h"
#import <QuartzCore/QuartzCore.h>

#define k_backingViewFrame CGRectMake(0.0, 0.0, 150.0, 150.0)

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
        
        
        //prepare foreground elements
        _image = [[UIImageView alloc] initWithFrame:CGRectMake(5.0, 5.0, 140.0, 140.0)];
        _image.layer.cornerRadius = 8.0;
        _image.layer.masksToBounds = YES;
        _image.layer.borderColor = [UIColor colorWithRed:37.0f/255.0f green:44.0f/255.0f blue:58.0f/255.0f alpha:1.0f].CGColor;
        _image.layer.borderWidth = 2.0;
        _auxControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"export", @"play", @"trash", nil]];
        _auxControl.frame = CGRectMake(5.0, 145.0, 140.0, 30.0);
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

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
