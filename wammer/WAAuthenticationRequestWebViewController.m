//
//  WAAuthenticationRequestWebViewController.m
//  wammer
//
//  Created by Evadne Wu on 5/8/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAAuthenticationRequestWebViewController.h"
#import "WARemoteInterface.h"
#import "WADefines.h"
#import "IRWebAPIEngine+FormURLEncoding.h"
#import "UIKit+IRAdditions.h"


@interface WAAuthenticationRequestWebViewController () <UIWebViewDelegate>
@property (nonatomic, readwrite, retain) UIWebView *view;
@property (nonatomic, readwrite, retain) UIActivityIndicatorView *spinner;
@end


@implementation WAAuthenticationRequestWebViewController
@dynamic view;
@synthesize spinner;

- (id) initWithStyle:(UITableViewStyle)style {

  self = [super initWithStyle:style];
  if (!self)
    return nil;

	self.title = NSLocalizedString(@"AUTH_WITH_FACEBOOK_REQUEST_TITLE", @"Title for the Facebook linking controller");
    
  self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  self.spinner.hidesWhenStopped = NO;
  [self.spinner startAnimating];
  
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
  
  return self;

}

- (void) loadView {

	[self setView:[[UIWebView alloc] initWithFrame:CGRectZero]];
  [[self view] setDelegate:self];

  NSDictionary *authenticationQueryParams = [NSDictionary dictionaryWithObjectsAndKeys:
    [[NSLocale currentLocale] localeIdentifier], @"locale",
    @"ios", @"device",
		@"waveface://x-callback-url/didFinishUserFacebookLogin?api_ret_code=%(api_ret_code)d&api_ret_message=%(api_ret_message)s&device_id=%(device_id)s&session_token=%(session_token)s&user_id=%(user_id)s", @"xurl",
		
		[WARemoteInterface sharedInterface].apiKey, @"api_key",
				
  nil];
  
  NSURL *authenticationURL = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:kWAUserFacebookAuthenticationEndpointURL]];
 
	NSMutableURLRequest *authenticationRequest = [[NSMutableURLRequest alloc] initWithURL:authenticationURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:15];
	
	authenticationRequest.HTTPMethod = @"POST";
	authenticationRequest.HTTPBody = IRWebAPIEngineFormURLEncodedDataWithDictionary(authenticationQueryParams);
	authenticationRequest.allHTTPHeaderFields = ((^ {
	
		NSMutableDictionary *fields = [authenticationRequest.allHTTPHeaderFields mutableCopy];
		if (fields)
			fields = [NSMutableDictionary dictionary];
	
		[fields setObject:@"8bit" forKey:@"Content-Transfer-Encoding"];
		[fields setObject:@"application/x-www-form-urlencoded" forKey:@"Content-Type"];
		
		return fields;
	
	})());

  
  [[self view] loadRequest:authenticationRequest];

}

- (void) viewDidLoad {
  
  [super viewDidLoad];
  
  __weak WAAuthenticationRequestWebViewController *wSelf = self;
  
  id listener = [[NSNotificationCenter defaultCenter] addObserverForName:kWAApplicationDidReceiveRemoteURLNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
  
    if (![wSelf isViewLoaded])
      return;
  
    NSURL *incomingURL = [note object];
    NSDictionary *incomingQuery = IRQueryParametersFromString([incomingURL query]);
    wSelf.username = [incomingQuery objectForKey:@"email"];
    wSelf.userID = [incomingQuery objectForKey:@"user_id"];
    wSelf.password = [incomingQuery objectForKey:@"password"];
    wSelf.token = [incomingQuery objectForKey:@"session_token"];
		
    if (wSelf.completionBlock)
      wSelf.completionBlock(wSelf, nil);
    
  }];
  
  objc_setAssociatedObject(self, &kWAApplicationDidReceiveRemoteURLNotification, listener, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

}

- (void) viewDidUnload {

  [super viewDidUnload];
  
  id listener = objc_getAssociatedObject(self, &kWAApplicationDidReceiveRemoteURLNotification);
  [[NSNotificationCenter defaultCenter] removeObserver:listener];
  objc_setAssociatedObject(self, &kWAApplicationDidReceiveRemoteURLNotification, nil, OBJC_ASSOCIATION_ASSIGN);

}

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {

  NSURL *openedURL = [request URL];
  
  if ([[openedURL scheme] isEqualToString:@"waveface"]) {
  
    dispatch_async(dispatch_get_main_queue(), ^ {
      [[UIApplication sharedApplication] openURL:openedURL];
    });
  
    return NO;
  
	}
	
  return YES;

}

- (void) webViewDidStartLoad:(UIWebView *)webView {

  [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
    self.spinner.alpha = webView.loading ? 1.0f : 0.0f;
  } completion:nil];

}

- (void) webViewDidFinishLoad:(UIWebView *)webView {

  [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
    self.spinner.alpha = webView.loading ? 1.0f : 0.0f;
  } completion:nil];
  
}

- (void) webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {

	if ([error code] == NSURLErrorCancelled)
		return;

  if (![[[[error userInfo] objectForKey:NSURLErrorFailingURLErrorKey] scheme] isEqualToString:@"waveface"]) {
		
		NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, webView, error);
		
		if (self.completionBlock)
			self.completionBlock(self, error);
	
	}
	
  [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
    self.spinner.alpha = webView.loading ? 1.0f : 0.0f;
  } completion:nil];
  
}

- (void) dealloc {

  id listener = objc_getAssociatedObject(self, &kWAApplicationDidReceiveRemoteURLNotification);
  [[NSNotificationCenter defaultCenter] removeObserver:listener];
  objc_setAssociatedObject(self, &kWAApplicationDidReceiveRemoteURLNotification, nil, OBJC_ASSOCIATION_ASSIGN);

}

- (void) presentError:(NSError *)error completion:(void(^)(void))block {

	NSString *alertTitle = NSLocalizedString(@"ERROR_AUTHENTICATION_FAILED_TITLE", @"Title for authentication failure");
	
	NSString *alertText = [[NSArray arrayWithObjects:
		NSLocalizedString(@"ERROR_AUTHENTICATION_FAILED_DESCRIPTION", @"Description for authentication failure"),
		[NSString stringWithFormat:@"“%@”.", [error localizedDescription]], @"\n\n",
		NSLocalizedString(@"ERROR_AUTHENTICATION_FAILED_RECOVERY_NOTION", @"Recovery notion for authentication failure recovery"),
	nil] componentsJoinedByString:@""];

	[[IRAlertView alertViewWithTitle:alertTitle message:alertText cancelAction:nil otherActions:[NSArray arrayWithObjects:
	
		[IRAction actionWithTitle:@"OK" block:block],
	
	nil]] show];

}

@end
