//
//  WAArticleAttachmentActivityView.h
//  wammer
//
//  Created by Evadne Wu on 2/21/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>


enum WAArticleAttachmentActivityViewStyle {
  
	WAArticleAttachmentActivityViewSpinnerStyle = 1,
	WAArticleAttachmentActivityViewAttachmentsStyle = 2,
	WAArticleAttachmentActivityViewLinkStyle = 3,
	
	WAArticleAttachmentActivityViewDefaultStyle = WAArticleAttachmentActivityViewAttachmentsStyle
	
}; typedef NSUInteger WAArticleAttachmentActivityViewStyle;


@interface WAArticleAttachmentActivityView : UIView

@property (nonatomic, readwrite, assign) WAArticleAttachmentActivityViewStyle style;

@property (nonatomic, readwrite, copy) void (^onTap)(void);

- (void) setTitle:(NSString *)title forStyle:(WAArticleAttachmentActivityViewStyle)aStyle;
- (NSString *) titleForStyle:(WAArticleAttachmentActivityViewStyle)aStyle;

@end
