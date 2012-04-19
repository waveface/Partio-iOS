//
//  WAPickerPaneViewController.h
//  wammer
//
//  Created by Evadne Wu on 4/20/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAPickerPaneViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *backdropView;
@property (weak, nonatomic) IBOutlet UIView *containerView;

- (IBAction) handleCancel:(UIBarButtonItem *)sender;
- (IBAction) handleDone:(UIBarButtonItem *)sender;

- (void) runPresentingAnimationWithCompletion:(void(^)(void))callback;
- (void) runDismissingAnimationWithCompletion:(void(^)(void))callback;

@end
