//
//  WATimelineIndexView.h
//  wammer
//
//  Created by Shen Steven on 4/6/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WATimelineIndexView : UIView

@property (nonatomic, assign) CGFloat percentage;
- (void) addIndex:(CGFloat)index label:(NSString*)label;

@end
