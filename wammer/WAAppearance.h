//
//  WAAppearance.h
//  wammer
//
//  Created by Evadne Wu on 4/5/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WAAppearance : NSObject

@end


@class IRBarButtonItem, IRBorder, IRShadow;

extern void WADefaultBarButtonInitialize (void);

extern IRBorder *kWADefaultBarButtonBorder;
extern IRShadow *kWADefaultBarButtonInnerShadow;
extern IRShadow *kWADefaultBarButtonShadow;

extern UIFont *kWADefaultBarButtonTitleFont;
extern UIColor *kWADefaultBarButtonTitleColor;
extern IRShadow *kWADefaultBarButtonTitleShadow;

extern UIColor *kWADefaultBarButtonGradientFromColor;
extern UIColor *kWADefaultBarButtonGradientToColor;
extern NSArray *kWADefaultBarButtonGradientColors;
extern UIColor *kWADefaultBarButtonBackgroundColor;

extern UIColor *kWADefaultBarButtonHighlightedGradientFromColor;
extern UIColor *kWADefaultBarButtonHighlightedGradientToColor;
extern NSArray *kWADefaultBarButtonHighlightedGradientColors;
extern UIColor *kWADefaultBarButtonHighlightedBackgroundColor;

extern IRBarButtonItem * WABarButtonItem (UIImage *image, NSString *title, void(^block)(void));
extern IRBarButtonItem * WABackBarButtonItem (UIImage *image, NSString *title, void(^block)(void));
extern IRBarButtonItem * WATransparentBlackBackBarButtonItem (UIImage *image, NSString *title, void(^block)(void));

extern UIButton * WAButtonForImage (UIImage *anImage);
extern UIButton * WAToolbarButtonForImage (UIImage *anImage, NSString *aAccessbilityLabel);
extern UIImage * WABarButtonImageFromImageNamed (NSString *anImageName);
extern UIImage * WABarButtonImageWithOptions (NSString *anImageName, UIColor *aColor, IRShadow *aShadow);

extern UIView * WAStandardTitleView (void);
extern UILabel * WAStandardTitleLabel (void);

extern UIView * WAStandardPostCellBackgroundView (void);
extern UIView * WAStandardPostCellSelectedBackgroundView (void);

extern UIView * WAStandardArticleStackCellBackgroundView (void);
extern UIView * WAStandardArticleStackCellTopBackgroundView (void);
extern UIView * WAStandardArticleStackCellCenterBackgroundView (void);
extern UIView * WAStandardArticleStackCellBottomBackgroundView (void);
