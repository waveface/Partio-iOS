//
//  WAPreviewBadge.h
//  wammer-iOS
//
//  Created by Evadne Wu on 9/13/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WAPreview;
@interface WAPreviewBadge : UIView

@property (nonatomic, readwrite, retain) UIImage *image;
@property (nonatomic, readwrite, retain) NSString *title;
@property (nonatomic, readwrite, retain) NSString *text;
@property (nonatomic, readwrite, retain) NSURL *link;

@property (nonatomic, readwrite, retain) UIFont *titleFont;
@property (nonatomic, readwrite, retain) UIColor *titleColor;
@property (nonatomic, readwrite, retain) UIFont *textFont;
@property (nonatomic, readwrite, retain) UIColor *textColor;

- (void) configureWithPreview:(WAPreview *)aPreview; 

@end
