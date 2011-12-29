//
//  WADimmingView.h
//  wammer
//
//  Created by Evadne Wu on 12/28/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WADimmingView : UIView

@property (nonatomic, readwrite, copy) void (^onAction)(void);

@end
