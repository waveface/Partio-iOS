//
//  WAGalleryViewController.h
//  wammer-iOS
//
//  Created by Evadne Wu on 8/3/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "WAView.h"

@interface WAGalleryViewController : UIViewController

+ (WAGalleryViewController *) controllerRepresentingArticleAtURI:(NSURL *)anArticleURI;

@property (nonatomic, readwrite, retain) WAView *view;

@property (nonatomic, readonly, assign) BOOL contextControlsShown;
- (void) setContextControlsHidden:(BOOL)willHide animated:(BOOL)animate completion:(void(^)(void))callback;
- (void) setContextControlsHidden:(BOOL)willHide animated:(BOOL)animate barringInteraction:(BOOL)barringInteraction completion:(void(^)(void))callback;

@end
                                                                                                                                                                                                                                                                                     