//
//  WADefines+iOS.h
//  wammer
//
//  Created by Evadne Wu on 12/17/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

@class WAAppDelegate;
extern WAAppDelegate * AppDelegate (void);

@class IRBarButtonItem;

extern BOOL WAIsXCallbackURL (NSURL *anURL, NSString **outCommand, NSDictionary **outParams);

extern IRBarButtonItem * WAStandardBarButtonItem (NSString *labelText, void(^block)(void));
extern IRBarButtonItem * WABackBarButtonItem (NSString *labelText, void(^block)(void));

extern UIButton * WAButtonForImage (UIImage *anImage);
extern UIButton * WAToolbarButtonForImage (UIImage *anImage);
extern UIImage * WABarButtonImageFromImageNamed (NSString *anImageName);

extern UIView * WAStandardTitleView (void);
extern UIView * WAStandardTitleLabel (void);
