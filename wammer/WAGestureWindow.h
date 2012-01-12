//
//  WAGestureWindow.h
//  wammer
//
//  Created by Evadne Wu on 1/11/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAGestureWindow : UIWindow

@property (nonatomic, readwrite, copy) void (^onTap)(void);

@property (nonatomic, readonly, retain) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, readwrite, copy) BOOL (^onGestureRecognizeShouldReceiveTouch)(UIGestureRecognizer *recognizer, UITouch *touch);	//	Default is NO
@property (nonatomic, readwrite, copy) BOOL (^onGestureRecognizeShouldRecognizeSimultaneouslyWithGestureRecognizer)(UIGestureRecognizer *recognizer, UIGestureRecognizer *otherRecognizer);	//	Default is YES

@end
