//
//  WAComposeViewControllerPhone.h
//  wammer-iOS
//
//  Created by jamie on 8/11/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface WAComposeViewControllerPhone : UIViewController

@property (nonatomic, retain) IBOutlet UITextView *contentTextView;
@property (nonatomic, retain) IBOutlet UIView *contentContainerView;

+ (WAComposeViewControllerPhone *) controllerWithPost:(NSURL *) aPostURLOrNil completion:(void(^)(NSURL *aPostURLOrNil))aBlock;
@end
