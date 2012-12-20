//
//  WAWebPreviewViewController.h
//  wammer
//
//  Created by Shen Steven on 12/20/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAWebPreviewViewController : UIViewController

@property (nonatomic, strong) NSString *urlString;
@property (nonatomic, weak) IBOutlet UIWebView *webView;

@end
