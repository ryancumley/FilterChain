//
//  NavCell.h
//  FilterChain
//
//  Created by Ryan Cumley on 9/23/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NavCell : UICollectionViewCell

@property (strong, nonatomic) UIButton* navButton;

- (void)pushedNavButton;

@end
