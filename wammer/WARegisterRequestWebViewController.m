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
    @"waveface://x-callback-url/didFinishUserRegistration?username=%(email)s&password=%(password)s", @"xurl",
  nil];
  
  NSURL *registrationURL = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:kWAUserRegistrationEndpointURL]];
  NSURL *usedRegistrationURL = IRWebAPIRequestURLWithQueryParameters(registrationURL, registrationQueryParams);
  
  NSURLRequest *registrationRequest = [[NSURLRequest alloc] initWithURL:usedRegistrationURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:15];
  
  [[self view] loadRequest:registrationRequest];

}

- (void) viewDidLoad {
  
  [super viewDidLoad];
  
  __block __typeof__(self) nrSelf = self;
  
  id incomingRegistrationCompletionListener = [[NSNotificationCenter defaultCenter] addObserverForName:kWAApplicationDidReceiveRemoteURLNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
  
    if (![nrSelf isViewLoaded])
      return;
  
    NSURL *incomingURL = [note object];
    NSDictionary *incomingQuery = IRQueryParametersFromString([incomingURL query]);
    nrSelf.username = [incomingQuery objectForKey:@"username"];
    nrSelf.password = [incomingQuery objectForKey:@"password"];
    
    if (nrSelf.completionBlock)
      nrSelf.completionBlock(nrSelf, nil);
    
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
