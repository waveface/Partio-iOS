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
@property (nonatomic, readwrite, assign) CGFloat progress;

@end
