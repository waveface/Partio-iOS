//
//  WAPreviewInspectionViewController.h
//  wammer
//
//  Created by jamie on 2/15/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WAPreviewBadge.h"

@class WAPreviewInspectionViewController;
@protocol WAPreviewInspectionViewControllerDelegate <NSObject>

- (void) previewInspectionViewControllerDidRemove:(WAPreviewInspectionViewController *)inspector;
- (void) previewInspectionViewControllerDidFinish:(WAPreviewInspectionViewController *)inspector;

@end


@class WAPreview;
@interface WAPreviewInspectionViewController : UIViewController

+ (id) controllerWithPreview:(NSURL *)anURL;
- (UINavigationController *) wrappingNavController;

@property (nonatomic, readwrite, assign) id <WAPreviewInspectionViewControllerDelegate> delegate;
@property (retain, nonatomic) IBOutlet UIButton *deleteButton;
- (IBAction) handleDeleteTap:(id)sender;

@property (nonatomic, readonly, retain) WAPreview *preview;
@property (nonatomic, readwrite, retain) IBOutlet WAPreviewBadge *previewBadge;

@end
