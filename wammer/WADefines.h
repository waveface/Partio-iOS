//
//  WADefines.h
//  wammer
//
//  Created by Evadne Wu on 10/2/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IRBarButtonItem, IRBorder;

extern NSString * const kWARemoteEndpointURL;
extern NSString * const kWALastAuthenticatedUserTokenKeychainItem;
extern NSString * const kWALastAuthenticatedUserIdentifier;

extern void WARegisterUserDefaults (void);

extern IRBarButtonItem * WAStandardBarButtonItem (NSString *labelText, void(^block)(void));
extern IRBarButtonItem * WABackBarButtonItem (NSString *labelText, void(^block)(void));

extern UIButton * WAButtonForImage (UIImage *anImage);
extern UIImage * WABarButtonImageFromImageNamed (NSString *anImageName);
