//
//  WAView.h
//  wammer-iOS
//
//  Created by Evadne Wu on 8/1/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAView : UIView

@property (nonatomic, readwrite, copy) UIView * (^onHitTestWithEvent)(CGPoint aPoint, UIEvent *anEvent);
@property (nonatomic, readwrite, copy) BOOL (^onPointInsideWithEvent)(CGPoint aPoint, UIEvent *anEvent, BOOL superAnswer);

@end
