//
//  WATwitterConnectSwitch.m
//  wammer
//
//  Created by Shen Steven on 12/9/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import "WATwitterConnectSwitch.h"
#import "WADefines.h"
#import "UIKit+IRAdditions.h"
#import "WAOverlayBezel.h"
#import "WARemoteInterface.h"
#import "TWAPIManager.h"

@interface WATwitterConnectSwitch ()

@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) ACAccount *twitterAccount;
@property (nonatomic, strong) NSString *consumerKey;
@property (nonatomic, strong) NSString *consumerSecret;

@end

@implementation WATwitterConnectSwitch

- (id) initWithFrame:(CGRect)frame {
  
  self = [super initWithFrame:frame];
  if (!self)
    return nil;
  
  [self commonInit];
  
  return self;
  
}

- (void) awakeFromNib {
  
  [super awakeFromNib];
  
  [self commonInit];
  
}

- (void) commonInit {
 
  self.consumerKey = [[NSUserDefaults standardUserDefaults] stringForKey:kWATwitterConsumerKey];
  self.consumerSecret = [[NSUserDefaults standardUserDefaults] stringForKey:kWATwitterConsumerSecret];
  
  [self addTarget:self action:@selector(handleValueChanged:) forControlEvents:UIControlEventValueChanged];
  self.on = [[NSUserDefaults standardUserDefaults] boolForKey:kWASNSTwitterConnectEnabled];
}


- (void) handleValueChanged:(id)sender {
  
  NSCParameterAssert(sender == self);
  
  if (self.on) {
    
    [[self newTwitterConnectAlertView] show];
    
  } else {
    
    [[self newTwitterDisconnectAlertView] show];
    
  }
  
}

- (NSString *) errorString:(NSUInteger) code
{
  if (code == 0x1002) {
    return NSLocalizedString(@"TWITTER_CONNECT_ACCOUNT_OCCUPIED_MESSAGE", @"Message for an alert view to show user his Twitter account has been connected to another Stream user");
  } else if (code == 0x2004) {
    return NSLocalizedString(@"TWITTER_CONNECT_FAIL_MESSAGE", @"Message for an alert view to show user he already connects to another Twitter account.");
  }
  return nil;
}

- (IRAlertView *) newTwitterConnectAlertView {
  
  __weak WATwitterConnectSwitch * const wSelf = self;
  
  NSString *cancelTitle = NSLocalizedString(@"ACTION_CANCEL", nil);
  IRAction *cancelAction = [IRAction actionWithTitle:cancelTitle block:^{
    
    [wSelf setOn:NO animated:YES];
    
  }];
  
  NSString *connectTitle = NSLocalizedString(@"ACTION_CONNECT_TWITTER_SHORT", @"Short action title for connecting Twitter creds");
  IRAction *connectAction = [IRAction actionWithTitle:connectTitle block:^{
    
    [wSelf handleTwitterConnect:nil];
    
  }];
  
  NSString *alertTitle = NSLocalizedString(@"TWITTER_CONNECT_REQUEST_TITLE", @"Title for alert view asking if user wants to connect her Twitter account");
  NSString *alertMessage = NSLocalizedString(@"TWITTER_CONNECT_REQUEST_MESSAGE", @"Message for alert view asking if user wants to connect her Twitter account");
  
  IRAlertView *alertView = [IRAlertView alertViewWithTitle:alertTitle message:alertMessage cancelAction:cancelAction otherActions:[NSArray arrayWithObjects:connectAction, nil]];
  
  return alertView;
  
}

- (void) handleTwitterConnect:(id)sender {
  
  [self setEnabled:NO];
  
  __weak WATwitterConnectSwitch * const wSelf = self;
  
  self.accountStore = [[ACAccountStore alloc] init];
  ACAccountType *accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

  WAOverlayBezel *busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
  [busyBezel showWithAnimation:WAOverlayBezelAnimationFade];
  
  [self.accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
	
	if (granted) {
	  
	  NSArray *accountsArray = [wSelf.accountStore accountsWithAccountType:accountType];
	  
	  if ( [accountsArray count] ) {
		wSelf.twitterAccount = accountsArray[0];
		
		TWAPIManager *apiManager = [[TWAPIManager alloc] init];
		apiManager.consumerKey = self.consumerKey;
		apiManager.consumerSecret = self.consumerSecret;
		[apiManager performReverseAuthForAccount:wSelf.twitterAccount withHandler:^(NSData *responseData, NSError *error) {
		  
		  if (responseData) {
			
			NSString *responseStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
			NSArray *parts = [responseStr  componentsSeparatedByString:@"&"];
			
			NSString *oauth_token = nil;
			NSString *oauth_token_secret = nil;
			
			for (NSString *part in parts) {
			  NSArray *keyValue = [part componentsSeparatedByString:@"="];
			  if ([keyValue[0] isEqual:@"oauth_token"])
				oauth_token = keyValue[1];
			  if ([keyValue[0] isEqual:@"oauth_token_secret"])
				oauth_token_secret = keyValue[1];
			}
						
			[[WARemoteInterface sharedInterface]
			 connectSocialNetwork:@"twitter"
			 withOptions: @{ @"accessToken": oauth_token, @"accessTokenSecret":oauth_token_secret, @"consumerKey": wSelf.consumerKey, @"consumerSecret": wSelf.consumerSecret }
			 onSuccess:^{
			   dispatch_async(dispatch_get_main_queue(), ^{

				 [busyBezel dismissWithAnimation:WAOverlayBezelAnimationNone];
				 
				 [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kWASNSTwitterConnectEnabled];
				 [wSelf setEnabled:YES];

			   });
			 }
			 onFailure:^(NSError *error) {
			   
			   dispatch_async(dispatch_get_main_queue(), ^{

				 [busyBezel dismissWithAnimation:WAOverlayBezelAnimationNone];

				 [[[IRAlertView alloc] initWithTitle:NSLocalizedString(@"TWITTER_CONNECT_FAIL_TITLE", @"Title for an alert view to show Twitter connection failure") message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
				 
				 [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kWASNSTwitterConnectEnabled];
				 [wSelf setEnabled:NO];
 
			   });
			   
			 }];


		  } else {
			
			NSLog(@"Fail to perform reverse auth for twitter account: %@", error);
			
			dispatch_async(dispatch_get_main_queue(), ^{
			  
			  [busyBezel dismissWithAnimation:WAOverlayBezelAnimationNone];
			
			  [[[IRAlertView alloc] initWithTitle:NSLocalizedString(@"TWITTER_CONNECT_FAIL_TITLE", @"Title for an alert view to show Twitter connection failure") message:[wSelf errorString:[error code]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
			  
			  [wSelf setEnabled:YES];
			  [wSelf setOn:NO animated:YES];
			  
			});
		  }
		   
		}];
		
	  } else {
        // no account available
        
        dispatch_async(dispatch_get_main_queue(), ^{
          
          [busyBezel dismissWithAnimation:WAOverlayBezelAnimationNone];
          
          [[[IRAlertView alloc] initWithTitle:NSLocalizedString(@"TWITTER_CONNECT_ACCOUNT_NOT_AVAILABLE", @"User doesn't login his account in iOS setting.") message:[wSelf errorString:[error code]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
          
          [wSelf setEnabled:YES];
          [wSelf setOn:NO animated:YES];
          
        });

      }
	} else {
      // not granted
      
      dispatch_async(dispatch_get_main_queue(), ^{
        
        [busyBezel dismissWithAnimation:WAOverlayBezelAnimationNone];
        
        [[[IRAlertView alloc] initWithTitle:NSLocalizedString(@"TWITTER_CONNECT_PERMISSION_TITLE", @"User doesn't permit the twitter access while connect to his twitter account.") message:[wSelf errorString:[error code]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        
        [wSelf setEnabled:YES];
        [wSelf setOn:NO animated:YES];
        
      });

    }
	
  }];
  
  
}

- (IRAlertView *) newTwitterDisconnectAlertView {
  
  __weak WATwitterConnectSwitch * const wSelf = self;
  
  NSString *cancelTitle = NSLocalizedString(@"ACTION_CANCEL", nil);
  IRAction *cancelAction = [IRAction actionWithTitle:cancelTitle block:^{
    
    [wSelf setOn:YES animated:YES];
    
  }];
  
  NSString *disconnectTitle = NSLocalizedString(@"ACTION_DISCONNECT_TWITTER", @"Short action title for disconnecting Twitter creds");
  IRAction *disconnectAction = [IRAction actionWithTitle:disconnectTitle block:^{
    
    [wSelf handleTwitterDisconnect:nil];
    
  }];
  
  NSString *alertTitle = NSLocalizedString(@"TWITTER_DISCONNECT_REQUEST_TITLE", @"Title for alert view asking if user wants to disconnect her Twitter account");
  NSString *alertMessage = NSLocalizedString(@"TWITTER_DISCONNECT_REQUEST_MESSAGE", @"Message for alert view asking if user wants to disconnect her Twitter account");
  
  IRAlertView *alertView = [IRAlertView alertViewWithTitle:alertTitle message:alertMessage cancelAction:cancelAction otherActions:[NSArray arrayWithObjects:disconnectAction, nil]];
  
  return alertView;
  
}

- (void) handleTwitterDisconnect:(id)sender {
  
  __weak WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
  __weak WATwitterConnectSwitch * const wSelf = self;
  
  [self setEnabled:NO];
  
  WAOverlayBezel *busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
  [busyBezel showWithAnimation:WAOverlayBezelAnimationFade];
  
  [ri disconnectSocialNetwork:@"twitter" purgeData:NO onSuccess:^{
    
    dispatch_async(dispatch_get_main_queue(), ^{
      
      [busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
      
      if (!wSelf)
        return;
      
      [wSelf setEnabled:YES];
      [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kWASNSTwitterConnectEnabled];
      
    });
    
  } onFailure:^(NSError *error) {
    
    dispatch_async(dispatch_get_main_queue(), ^{
      
      [busyBezel dismissWithAnimation:WAOverlayBezelAnimationNone];
      
      WAOverlayBezel *errorBezel = [WAOverlayBezel bezelWithStyle:WAErrorBezelStyle];
      [errorBezel showWithAnimation:WAOverlayBezelAnimationNone];
      
      if (!wSelf)
        return;
      
      [wSelf setEnabled:YES];
      [wSelf setOn:YES animated:YES];
      
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        [errorBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
        
      });
      
    });
    
  }];
  
}


@end
