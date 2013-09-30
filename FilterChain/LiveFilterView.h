//
//  LiveFilterView.h
//  FilterChain
//
//  Created by Ryan Cumley on 9/23/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImage.h"

@interface LiveFilterView : UIView

{
    BOOL sliderIsStationary;
    BOOL displayingKillButton;
}

@property (nonatomic, assign) id sliderDelegate;

@property (strong, nonatomic) UISlider* slider;
@property (strong, nonatomic) UIButton* killButton;
@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) GPUImageFilter* filter;

- (void)killThisFilter;
- (void)displayKillButton;
- (void)hideKillButton;
- (void)pushUpdatedSliderValueToFilter:(UIEvent*)event;
- (void)makeSliderStaionary:(BOOL)stationary;
- (BOOL)isSliderStationary;

@end

@protocol LiveFilterActionDelegate <NSObject>

- (void)liveFilterWithTag:(int)tag isSendingValue:(CGFloat)value;
- (void)killLiveFilterWithTag:(int)tag;

@end
