//
//  WAWebPreviewViewController.m
//  wammer
//
//  Created by Shen Steven on 12/20/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAWebPreviewViewController.h"
#import "WAAppearance.h"

@interface WAWebPreviewViewController () <UIWebViewDelegate>

@property (nonatomic, strong) UIBarButtonItem *forwardButton;
@property (nonatomic, strong) UIBarButtonItem *backwardButton;

@end

@implementation WAWebPreviewViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.navigationItem.rightBarButtonItem = (UIBarButtonItem*)WABarButtonItem([UIImage imageNamed:@"action"], @"", ^{
		[[UIApplication sharedApplication] openURL:[[NSURL alloc] initWithString:_urlString]];
	});
	
	UIImage *leftImage = [UIImage imageNamed:@"Left"];
	UIImage *rightImage = [UIImage imageNamed:@"Right"];
	UIButton *leftButton = [[UIButton alloc] initWithFrame:(CGRect){CGPointZero, leftImage.size}];
	[leftButton setBackgroundImage:leftImage forState:UIControlStateNormal];
	[leftButton addTarget:self action:@selector(leftButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	UIButton *rightButton = [[UIButton alloc] initWithFrame:(CGRect){CGPointZero, rightImage.size}];
	[rightButton setBackgroundImage:rightImage forState:UIControlStateNormal];
	[rightButton addTarget:self action:@selector(rightButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	
	self.backwardButton = [[UIBarButtonItem alloc] initWithCustomView:leftButton];
	[self.backwardButton setEnabled:NO];
	self.forwardButton = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
	[self.forwardButton setEnabled:NO];
	UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	self.toolbarItems = @[self.backwardButton, space, self.forwardButton];
	[self.navigationController setToolbarHidden:NO];

}

- (void) viewDidAppear:(BOOL)animated {
	
	[super viewDidAppear:animated];
	
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:self.urlString]];
	[self.webView loadRequest:request];
	self.webView.scalesPageToFit = YES;
	
}

- (void) viewDidDisappear:(BOOL)animated {
	
	[super viewDidDisappear:animated];
	
	[self.webView stopLoading];
	self.webView = nil;
	
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Handle events
- (void) leftButtonTapped:(id)sender {
	
	if ([self.webView canGoBack]) {
		[self.webView goBack];
	}
			 
}

- (void) rightButtonTapped:(id)sender {

	if ([self.webView canGoForward]) {
		[self.webView goForward];
	}
	
}

#pragma mark - UIWebViewDelegate

- (void) webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	
	self.title = NSLocalizedString(@"NAVI_TITLE_WEB_FAILED", @"Navigation bar title while loading web page failed");

}

- (void) webViewDidStartLoad:(UIWebView *)webView {
	
	self.title = NSLocalizedString(@"NAVI_TITLE_WEB_LOADING", @"Navigation bar title for web preview while loading");

}

- (void) webViewDidFinishLoad:(UIWebView *)webView {
	
	self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];

	
	if (webView.canGoForward) {
		[self.forwardButton setEnabled:YES];
	} else {
		[self.forwardButton setEnabled:NO];
	}

	if (webView.canGoBack) {
		[self.backwardButton setEnabled:YES];
	} else {
		[self.backwardButton setEnabled:NO];
	}

}

@end
