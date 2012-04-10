//
//  WARepresentedFilePickerViewController+CustomUI.h
//  wammer
//
//  Created by Evadne Wu on 4/9/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WARepresentedFilePickerViewController.h"

@interface WARepresentedFilePickerViewController (CustomUI)

- (UINavigationController *) wrappingNavigationController; //	Returns a custom-styled nav controller suitable for presenting the view controller on an iPad.  Throws an exception if the view controller is already within another nav controller.

+ (WARepresentedFilePickerViewController *) defaultAutoSubmittingControllerForArticle:(NSURL *)anArticleURI completion:(void(^)(NSURL *))aBlock;

+ (BOOL) canPresentRepresentedFilePickerControllerForArticle:(NSURL *)anArticleURI;	//	Returns NO if the article has less than 2 files; also note that this method ultimately gets its reference to the article thru the global managed object context

@end
	