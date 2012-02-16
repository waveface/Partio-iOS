//
//  WADefines+iOS.h
//  wammer
//
//  Created by Evadne Wu on 12/17/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

@class WAAppDelegate;
extern WAAppDelegate * AppDelegate (void);

@class IRBarButtonItem, IRBorder, IRShadow;

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


extern BOOL WAIsXCallbackURL (NSURL *anURL, NSString **outCommand, NSDictionary **outParams);

extern IRBarButtonItem * WAStandardBarButtonItem (NSString *labelText, void(^block)(void));
extern IRBarButtonItem * WABackBarButtonItem (NSString *labelText, void(^block)(void));

extern UIButton * WAButtonForImage (UIImage *anImage);
extern UIButton * WAToolbarButtonForImage (UIImage *anImage, NSString *aAccessbilityLabel);
extern UIImage * WABarButtonImageFromImageNamed (NSString *anImageName);
extern UIImage * WABarButtonImageWithOptions (NSString *anImageName, UIColor *aColor, IRShadow *aShadow);

extern UIView * WAStandardTitleView (void);
extern UIView * WAStandardTitleLabel (void);

extern UIView * WAStandardPostCellBackgroundView (void);
extern UIView * WAStandardPostCellSelectedBackgroundView (void);

extern UIView * WAStandardArticleStackCellBackgroundView (void);

extern UIView * WAStandardArticleStackCellTopBackgroundView (void);
extern UIView * WAStandardArticleStackCellCenterBackgroundView (void);
extern UIView * WAStandardArticleStackCellBottomBackgroundView (void);
