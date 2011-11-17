//
//  WAArticleDraftsViewController.h
//  wammer
//
//  Created by Evadne Wu on 11/18/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WAArticleDraftsViewController;
@protocol WAArticleDraftsViewControllerDelegate <NSObject>
- (void) articleDraftsViewController:(WAArticleDraftsViewController *)aController didSelectArticle:(NSURL *)anObjectURIOrNil;
@end

@interface WAArticleDraftsViewController : UITableViewController
@property (nonatomic, readwrite, assign) id<WAArticleDraftsViewControllerDelegate> delegate;
@end
