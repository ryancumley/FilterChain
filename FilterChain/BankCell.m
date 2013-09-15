//
//  BankCell.m
//  FilterChain
//
//  Created by Ryan Cumley on 9/9/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import "BankCell.h"
#import <QuartzCore/QuartzCore.h>

#define k_imageFrame CGRectMake(15.0, 0.0, 65.0, 65.0)
#define k_labelFrame CGRectMake(0.0, 65.0, 95.0, 30.0)

@implementation BankCell

@synthesize image = _image, label = _label, imageName = _imageName;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //setup the label and image
        _image = [[UIImageView alloc] initWithFrame:k_imageFrame];
        _image.layer.cornerRadius = 8.0;
        _image.layer.masksToBounds = YES;
        _image.layer.borderColor = [UIColor colorWithRed:37.0f/255.0f green:44.0f/255.0f blue:58.0f/255.0f alpha:1.0f].CGColor;
        _image.layer.borderWidth = 2.0;
        _label = [[UILabel alloc] initWithFrame:k_labelFrame];
        [_label setTextAlignment:NSTextAlignmentCenter];
        _label.numberOfLines = 0;
        _label.lineBreakMode = NSLineBreakByWordWrapping;
        _label.textColor = [UIColor whiteColor];
        [self addSubview:_image];
        [self addSubview:_label];
    }
    return self;
}

- (void)prepareForReuse {
    self.selected = NO;
}

@end
