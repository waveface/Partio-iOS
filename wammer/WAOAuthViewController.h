//
//  WAWebServiceOAuthViewController.h
//  wammer
//
//  Created by kchiu on 12/11/29.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^WAOAuthDidComplete)(NSURL *resultURL);

@interface WAOAuthViewController : UIViewController <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webview;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) WAOAuthDidComplete didCompleteBlock;

@end
