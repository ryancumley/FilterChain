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
    BOOL displayingKillButton;
}

@property (nonatomic, assign) id sliderDelegate;

@property (strong, nonatomic) UISlider* slider;
@property (strong, nonatomic) UIButton* killButton;
@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) GPUImageFilter* filter;

- (void)loadWithName:(NSString*)name;
- (void)clearAndHide;
- (void)displayKillButton;
- (void)pushUpdatedSliderValueToFilter;

@end

@protocol LiveFilterSliderDelegate <NSObject>

- (void)liveFilterWithTag:(int)tag isSendingValue:(CGFloat)value;

@end
