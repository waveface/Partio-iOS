//
//  WAPulldownRefreshView.h
//  wammer
//
//  Created by Evadne Wu on 9/21/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAPulldownRefreshView : UIView

+ (id) viewFromNib;

@property (nonatomic, readwrite, retain) IBOutlet UIView *arrowView;
@property (nonatomic, readwrite, retain) IBOutlet UIActivityIndicatorView *spinner;

@property (nonatomic, readwrite, assign) CGFloat progress;
- (void) setProgress:(CGFloat)newProgress animated:(BOOL)animate;

@property (nonatomic, readwrite, assign, getter=isBusy, setter=setBusy:) BOOL busy;
- (void) setBusy:(BOOL)flag animated:(BOOL)animate;

@end
