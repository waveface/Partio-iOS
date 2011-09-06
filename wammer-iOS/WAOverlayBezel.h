//
//  WAOverlayBezel.h
//  wammer-iOS
//
//  Created by Evadne Wu on 9/2/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifndef __WAOverlayBezel__
#define __WAOverlayBezel__

typedef enum {

	WAOverlayBezelSpinnerStyle = 0,
	
	WAOverlayBezelDefaultStyle = WAOverlayBezelSpinnerStyle

} WAOverlayBezelStyle;

#endif

@interface WAOverlayBezel : UIView

+ (WAOverlayBezel *) bezelWithStyle:(WAOverlayBezelStyle)aStyle;
- (WAOverlayBezel *) initWithStyle:(WAOverlayBezelStyle)aStyle;

@property (nonatomic, readwrite, copy) NSString *caption;

- (void) show;
- (void) dismiss;

@end
