//
//  Cell.h
//  UrbanSky
//
//  Created by Ryan Cumley on 8/28/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Cell : UICollectionViewCell

@property (strong, nonatomic) UIImageView *image;
@property (strong, nonatomic) UISegmentedControl *auxControl;
@property (strong, nonatomic) UIView *backingView;

@end
