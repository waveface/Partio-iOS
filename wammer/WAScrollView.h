//
//  WAScrollView.h
//  wammer
//
//  Created by Evadne Wu on 1/30/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAScrollView : UIScrollView

@property (nonatomic, readwrite, copy) BOOL (^onTouchesShouldBeginWithEventInContentView)(NSSet *touches, UIEvent *event, UIView *view);

@property (nonatomic, readwrite, copy) BOOL (^onTouchesShouldCancelInContentView)(UIView *view);

@end
