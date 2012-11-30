//
//  WAOAuthSwitch.h
//  wammer
//
//  Created by kchiu on 12/11/29.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WAOAuthViewController.h"

@protocol WAOAuthSwitchDelegate <NSObject>

- (void)openOAuthWebViewWithRequest:(NSURLRequest *)request completeBlock:(WAOAuthDidComplete)didCompleteBlock;

@end

@interface WAOAuthSwitch : UISwitch

@property (nonatomic, weak) id<WAOAuthSwitchDelegate> delegate;

- (BOOL)isSuccessURL:(NSURL *)resultURL;

@end
