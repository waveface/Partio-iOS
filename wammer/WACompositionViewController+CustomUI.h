//
//  WACompositionViewController+CustomUI.h
//  wammer
//
//  Created by Evadne Wu on 11/1/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WACompositionViewController.h"

@interface WACompositionViewController (CustomUI)

- (UINavigationController *) wrappingNavigationController NS_RETURNS_NOT_RETAINED; //	Returns a custom-styled nav controller suitable for presenting the view controller on an iPad.  Throws an exception if the view controller is already within another nav controller.

+ (WACompositionViewController *) defaultAutoSubmittingCompositionViewControllerForArticle:(NSURL *)anArticleURI completion:(void(^)(NSURL *))aBlock;

@end
