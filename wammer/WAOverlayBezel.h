//
//  WAOverlayBezel.h
//  wammer-iOS
//
//  Created by Evadne Wu on 9/2/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIWindow+IRAdditions.h"

#ifndef __WAOverlayBezel__
#define __WAOverlayBezel__

typedef enum {
	WAActivityIndicatorBezelStyle = 0,
	WACheckmarkBezelStyle,
	WACloudBezelStyle,
	WAConnectionBezelStyle,
	WAErrorBezelStyle,
	WARestrictedBezelStyle,
	WADefaultBezelStyle = WAActivityIndicatorBezelStyle
} WAOverlayBezelStyle;

typedef enum {
	WAOverlayBezelAnimationNone = 0,
	WAOverlayBezelAnimationFade = 1 << 1,
	WAOverlayBezelAnimationZoom = 1 << 2,
	WAOverlayBezelAnimationSlide = 1 << 3,
	WAOverlayBezelAnimationDefault = WAOverlayBezelAnimationNone
} WAOverlayBezelAnimation;

#endif

@interface WAOverlayBezel : UIView

+ (WAOverlayBezel *) bezelWithStyle:(WAOverlayBezelStyle)aStyle;
- (WAOverlayBezel *) initWithStyle:(WAOverlayBezelStyle)aStyle;

@property (nonatomic, readwrite, copy) NSString *caption;

- (void) show;
- (void) dismiss;

- (void) showWithAnimation:(WAOverlayBezelAnimation)anAnimation;
- (void) dismissWithAnimation:(WAOverlayBezelAnimation)anAnimation;

@end
