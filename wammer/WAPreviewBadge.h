//
//  WAPreviewBadge.h
//  wammer-iOS
//
//  Created by Evadne Wu on 9/13/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>


enum {

	WAPreviewBadgeAutomaticStyle = 0,

	WAPreviewBadgeImageAndTextStyle,
	WAPreviewBadgeTextOnlyStyle,
	WAPreviewBadgeImageOnlyStyle,
	
	WAPreviewBadgeTextOverImageStyle,
	
	WAPreviewBadgeDefaultStyle = WAPreviewBadgeAutomaticStyle
	
}; typedef NSUInteger WAPreviewBadgeStyle;


@class WAPreview;
@interface WAPreviewBadge : UIView

@property (nonatomic, readwrite, retain) WAPreview *preview;
@property (nonatomic, readwrite, assign) WAPreviewBadgeStyle style;

@property (nonatomic, readwrite, retain) UIFont *titleFont;
@property (nonatomic, readwrite, retain) UIColor *titleColor;
@property (nonatomic, readwrite, retain) UIFont *textFont;
@property (nonatomic, readwrite, retain) UIColor *textColor;
@property (nonatomic, readwrite, retain) UIView *backgroundView;

@property (nonatomic, readwrite, assign) CGFloat minimumAcceptibleFullFrameAspectRatio;

@property (nonatomic, readonly, retain) UIImage *image;
@property (nonatomic, readonly, retain) NSString *title;
@property (nonatomic, readonly, retain) NSString *text;
@property (nonatomic, readonly, retain) NSURL *link;

@end
