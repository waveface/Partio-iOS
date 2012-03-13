//
//  WACompositionViewControllerPad.h
//  wammer
//
//  Created by Evadne Wu on 2/20/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WACompositionViewController.h"

#import "AQGridView.h"
#import "IRTransparentToolbar.h"


@interface WACompositionViewControllerPad : WACompositionViewController

@property (nonatomic, readwrite, retain) IBOutlet AQGridView *photosView;
@property (nonatomic, readwrite, retain) IBOutlet IRTransparentToolbar *toolbar;
@property (nonatomic, readwrite, retain) IBOutlet UIView *noPhotoReminderView;

@property (nonatomic, readwrite, retain) IBOutletCollection(id) NSArray *noPhotoReminderViewElements;

- (IBAction) handleCameraItemTap:(UIButton *)sender;
- (IBAction) handlePreviewBadgeTap:(id)sender;

@end
