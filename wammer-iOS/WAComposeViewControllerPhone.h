//
//  WAComposeViewControllerPhone.h
//  wammer-iOS
//
//  Created by jamie on 8/11/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAComposeViewControllerPhone : UIViewController
{
    
    UITextView *contentTextView;
}

@property (nonatomic, retain) IBOutlet UITextView *contentTextView;
+ (WAComposeViewControllerPhone *) controllerWithPost:(NSURL *) aPostURLOrNil completion:(void(^)(NSURL *aPostURLOrNil))aBlock;
@end
