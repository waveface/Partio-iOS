//
//  WAView.h
//  wammer-iOS
//
//  Created by Evadne Wu on 8/1/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAView : UIView

@property (nonatomic, readwrite, copy) UIView * (^onHitTestWithEvent)(CGPoint aPoint, UIEvent *anEvent, UIView *superAnswer);
@property (nonatomic, readwrite, copy) BOOL (^onPointInsideWithEvent)(CGPoint aPoint, UIEvent *anEvent, BOOL superAnswer);
@property (nonatomic, readwrite, copy) void (^onLayoutSubviews)();

@property (nonatomic, readwrite, copy) CGSize (^onSizeThatFits)(CGSize proposedSize, CGSize superAnswer);

@end
