//
//  NavCell.m
//  FilterChain
//
//  Created by Ryan Cumley on 9/23/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import "NavCell.h"
#import "MainViewController.h"

#define k_buttonFrame CGRectMake(15.0, 0.0, 65.0, 65.0)
@implementation NavCell

@synthesize navButton = _navButton;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _navButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _navButton.frame = k_buttonFrame;
        _navButton.backgroundColor = [UIColor colorWithRed:64.0f/255.0f green:71.0f/255.0f blue:90.0f/255.0f alpha:1.0];
        [_navButton addTarget:self action:@selector(pushedNavButton) forControlEvents:UIControlEventTouchUpInside];
        [_navButton setImage:[UIImage imageNamed:@"VideoIcon.png"] forState:UIControlStateNormal];
        _navButton.layer.masksToBounds = YES;
        _navButton.layer.cornerRadius = 10.0f;
        _navButton.layer.borderColor = [UIColor colorWithRed:64.0f/255.0f green:71.0f/255.0f blue:90.0f/255.0f alpha:1.0].CGColor;
        _navButton.layer.borderWidth = 2.0f;
        [self addSubview:_navButton];
    }
    return self;
}

- (void)pushedNavButton {
    MainViewController* mvc = (MainViewController*)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [mvc navigateToClips:nil];
}

@end
