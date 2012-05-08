//
//  WARegisterRequestWebViewController.m
//  wammer
//
//  Created by Evadne Wu on 11/29/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <objc/runtime.h>
#import "WARegisterRequestWebViewController.h"
#import "WADefines.h"
#import "IRWebAPIKitDefines.h"
#import "IRWebAPIHelpers.h"

#import "WARegisterRequestViewController+SubclassEyesOnly.h"

#import "WARemoteInterface.h"
#import "IRWebAPIEngine+FormURLEncoding.h"


@interface WARegisterRequestWebViewController () <UIWebViewDelegate>
@property (nonatomic, readwrite, retain) UIWebView *view;
@property (nonatomic, readwrite, retain) UIActivityIndicatorView *spinner;
@end


@implementation WARegisterRequestWebViewController
@dynamic view;
@synthesize spinner;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (!self)
    return nil;
    
  self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  self.spinner.hidesWhenStopped = NO;
  [self.spinner startAnimating];
  
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
  
  return self;

}

- (void) loadView {

  [self setView:[[UIWebView alloc] initWithFrame:CGRectZero]];
  [[self view] setDelegate:self];
  
  NSDictionary *registrationQueryParams = [NSDictionary dictionaryWithObjectsAndKeys:
    [[NSLocale currentLocale] localeIdentifier], @"locale",
    @"ios", @"device",
		@"waveface://x-callback-url/didFinishUserRegistration?account_type=%(account_type)s&api_ret_code=%(api_ret_code)d&api_ret_message=%(api_ret_message)s&device_id=%(device_id)s&session_token=%(session_token)s&email=%(email)s&password=%(password)s&user_id=%(user_id)s", @"xurl",
		
		[WARemoteInterface sharedInterface].apiKey, @"api_key",
				
  nil];
  
  NSURL *registrationURL = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:kWAUserRegistrationEndpointURL]];
 
	NSMutableURLRequest *registrationRequest = [[NSMutableURLRequest alloc] initWithURL:registrationURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:15];
	
	registrationRequest.HTTPMethod = @"POST";
	registrationRequest.HTTPBody = IRWebAPIEngineFormURLEncodedDataWithDictionary(registrationQueryParams);
	registrationRequest.allHTTPHeaderFields = ((^ {
	
		NSMutableDictionary *fields = [registrationRequest.allHTTPHeaderFields mutableCopy];
		if (fields)
			fields = [NSMutableDictionary dictionary];
	
		[fields setObject:@"8bit" forKey:@"Content-Transfer-Encoding"];
		[fields setObject:@"application/x-www-form-urlencoded" forKey:@"Content-Type"];
		
		return fields;
	
	})());

  
  [[self view] loadRequest:registrationRequest];

}

- (void) viewDidLoad {
  
  [super viewDidLoad];
  
  __weak WARegisterRequestWebViewController *wSelf = self;
  
  id incomingRegistrationCompletionListener = [[NSNotificationCenter defaultCenter] addObserverForName:kWAApplicationDidReceiveRemoteURLNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
  
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
  
  objc_setAssociatedObject(self, &kWAApplicationDidReceiveRemoteURLNotification, incomingRegistrationCompletionListener, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

}

- (void) viewDidUnload {

  [super viewDidUnload];
  
  id incomingRegistrationCompletionListener = objc_getAssociatedObject(self, &kWAApplicationDidReceiveRemoteURLNotification);
  [[NSNotificationCenter defaultCenter] removeObserver:incomingRegistrationCompletionListener];
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
	
	if ([[openedURL host] isEqualToString:@"localhost"]) {
	
	
		NSURL *overriddenURL = [NSURL URLWithString:[[openedURL absoluteString] stringByReplacingOccurrencesOfString:@"://localhost" withString:[NSString stringWithFormat:@"://%@",
		
			[[NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:kWAUserRegistrationEndpointURL]] host]
//			[[[[[WARemoteInterface sharedInterface] engine] context] baseURL] host]
		
		
		]]];
	
		[webView loadRequest:[NSURLRequest requestWithURL:overriddenURL]];
	
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

  if (![[[[error userInfo] objectForKey:NSURLErrorFailingURLErrorKey] scheme] isEqualToString:@"waveface"])
    [[[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:NSLocalizedString(@"ACTION_OKAY", @"Fine!") otherButtonTitles:nil] show];
  
  [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
    self.spinner.alpha = webView.loading ? 1.0f : 0.0f;
  } completion:nil];
  
}

- (void) dealloc {

  id incomingRegistrationCompletionListener = objc_getAssociatedObject(self, &kWAApplicationDidReceiveRemoteURLNotification);
  [[NSNotificationCenter defaultCenter] removeObserver:incomingRegistrationCompletionListener];
  objc_setAssociatedObject(self, &kWAApplicationDidReceiveRemoteURLNotification, nil, OBJC_ASSOCIATION_ASSIGN);

}

@end
