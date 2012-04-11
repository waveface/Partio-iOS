//
//  WAArticleViewController+Inspection.h
//  wammer
//
//  Created by Evadne Wu on 3/29/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAArticleViewController.h"


//	The Inspection additions is included as a category providing additional inspection actions that can be invoked by long pressing the view, if the provided long press gesture recognizer has been installed on the view correctly.

//	Actions in the -newInspectionActions array and passing in or out of the delegate method -actionsForArticleViewController:basedOn: are all IRAction objects.  They need to be dynamically generated because they can be context sensitive.  If your code requires good performance and there is a potential bottleneck in generating them, consider caching them.


@class WAArticleViewController;
@protocol WAArticleViewControllerInspection <NSObject>

- (NSArray *) actionsForArticleViewController:(WAArticleViewController *)controller basedOn:(NSArray *)defaultActions;

@end


@class IRAction;
@interface WAArticleViewController (Inspection)

@property (nonatomic, readwrite, weak) id<WAArticleViewControllerInspection> inspectionDelegate;
@property (nonatomic, readwrite, strong) IRActionSheetController *inspectionActionSheetController;
@property (nonatomic, readwrite, strong) UIPopoverController *coverPhotoSwitchPopoverController;

- (UILongPressGestureRecognizer *) newInspectionGestureRecognizer;
- (NSArray *) newInspectionActions;

- (IRAction *) newInspectionAction;
- (IRAction *) newFavoriteStatusToggleAction;
- (IRAction *) newCoverPhotoSwitchAction;	//	May return nil if the action can’t be done, for example if the acticle does not have more than 1 photo the action would ultimately do nothing sensible

@end
