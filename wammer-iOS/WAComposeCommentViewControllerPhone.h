//
//  WAComposeCommentViewControllerPhone.h
//  wammer-iOS
//
//  Created by jamie on 9/1/11.
//  Copyright (c) 2011 Waveface Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAComposeCommentViewControllerPhone : UIViewController
@property (retain, nonatomic) IBOutlet UITextView *contentTextView;

+ (WAComposeCommentViewControllerPhone *) controllerWithPost:(NSURL *) aPostURLOrNil completion:(void(^)(NSURL *aPostURLOrNil))aBlock;

@end
