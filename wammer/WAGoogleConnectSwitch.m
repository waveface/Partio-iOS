//
//  WAGoogleConnectSwitch.m
//  wammer
//
//  Created by kchiu on 12/11/30.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAGoogleConnectSwitch.h"
#import "UIKit+IRAdditions.h"
#import "WARemoteInterface.h"
#import "WADefines.h"

@implementation WAGoogleConnectSwitch

- (id)init {

	self = [super init];
	if (self) {
		[self addTarget:self action:@selector(handleValueChanged:) forControlEvents:UIControlEventValueChanged];
		self.on = [[NSUserDefaults standardUserDefaults] boolForKey:kWASNSGoogleConnectEnabled];
	}
	return self;

}

- (IRAlertView *)newGoogleConnectAlertView {
	
	__weak WAGoogleConnectSwitch *wSelf = self;
	
	NSString *cancelTitle = NSLocalizedString(@"ACTION_CANCEL", nil);
	IRAction *cancelAction = [IRAction actionWithTitle:cancelTitle block:^{

		[wSelf setOn:!wSelf.on animated:YES];
		
	}];
	
	NSString *connectTitle = NSLocalizedString(@"ACTION_CONNECT_GOOGLE_SHORT", @"Short action title for connecting Google");
	IRAction *connectAction = [IRAction actionWithTitle:connectTitle block:^{
		
		[wSelf handleGoogleConnect];
		
	}];
	
	NSString *alertTitle = NSLocalizedString(@"GOOGLE_CONNECT_REQUEST_TITLE", @"Title for alert view asking if user wants to connect her Google account");
	NSString *alertMessage = NSLocalizedString(@"GOOGLE_CONNECT_REQUEST_MESSAGE", @"Message for alert view asking if user wants to connect her Google account");
	
	IRAlertView *alertView = [IRAlertView alertViewWithTitle:alertTitle message:alertMessage cancelAction:cancelAction otherActions:[NSArray arrayWithObjects:connectAction, nil]];
	
	return alertView;
	
}

- (IRAlertView *)newGoogleDisconnectAlertView {
	
	__weak WAGoogleConnectSwitch * const wSelf = self;
	
	NSString *cancelTitle = NSLocalizedString(@"ACTION_CANCEL", nil);
	IRAction *cancelAction = [IRAction actionWithTitle:cancelTitle block:^{
		
		[wSelf setOn:!wSelf.on animated:YES];

	}];
	
	NSString *disconnectTitle = NSLocalizedString(@"ACTION_DISCONNECT_GOOGLE", @"Short action title for disconnecting Google");
	IRAction *disconnectAction = [IRAction actionWithTitle:disconnectTitle block:^{
		
		[wSelf handleGoogleDisconnect];
		
	}];
	
	NSString *alertTitle = NSLocalizedString(@"GOOGLE_DISCONNECT_REQUEST_TITLE", @"Title for alert view asking if user wants to disconnect her Google account");
	NSString *alertMessage = NSLocalizedString(@"GOOGLE_DISCONNECT_REQUEST_MESSAGE", @"Message for alert view asking if user wants to disconnect her Google account");
	
	IRAlertView *alertView = [IRAlertView alertViewWithTitle:alertTitle message:alertMessage cancelAction:cancelAction otherActions:[NSArray arrayWithObjects:disconnectAction, nil]];
	
	return alertView;
	
}

- (void)handleGoogleConnect {
	
	NSString *webURL = [[NSUserDefaults standardUserDefaults] stringForKey:kWARemoteEndpointWebURL];
	NSURL *url = [NSURL URLWithString:[webURL stringByAppendingString:@"sns/google/connect"]];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	NSString *preferedLanguage = @"en_US";
	NSArray *preferedLanguages = [NSLocale preferredLanguages];
	if ([preferedLanguages count] > 0 && [preferedLanguages[0] isEqualToString:@"zh-Hant"]) {
		preferedLanguage = @"zh_TW";
	}
	WARemoteInterface *ri = [WARemoteInterface sharedInterface];
	NSDictionary *parameters = @{
	@"device": @"ios",
	@"api_key": ri.apiKey,
	@"session_token": ri.userToken,
	@"locale": preferedLanguage,
	@"xurl": @"waveface://x-callback-url/didConnectGoogle?api_ret_code=%(api_ret_code)d&api_ret_message=%(api_ret_message)s"
	};
	[request setHTTPBody:IRWebAPIEngineFormURLEncodedDataWithDictionary(parameters)];
	
	__weak WAGoogleConnectSwitch *wSelf = self;
	[self.delegate openOAuthWebViewWithRequest:request completeBlock:^(NSURL *resultURL) {
		NSParameterAssert([NSThread isMainThread]);
		if ([wSelf isSuccessURL:resultURL]) {
			[wSelf setOn:YES animated:YES];
		} else {
			[[[IRAlertView alloc] initWithTitle:NSLocalizedString(@"GOOGLE_CONNECT_FAIL_TITLE", @"Title for an alert view to show Google connection failure") message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
			[wSelf setOn:NO animated:YES];
		}
	}];
	
}

- (void)handleGoogleDisconnect {
	
	NSString *webURL = [[NSUserDefaults standardUserDefaults] stringForKey:kWARemoteEndpointWebURL];
	NSURL *url = [NSURL URLWithString:[webURL stringByAppendingString:@"sns/google/disconnect"]];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	NSString *preferedLanguage = @"en_US";
	NSArray *preferedLanguages = [NSLocale preferredLanguages];
	if ([preferedLanguages count] > 0 && [preferedLanguages[0] isEqualToString:@"zh-Hant"]) {
		preferedLanguage = @"zh_TW";
	}
	WARemoteInterface *ri = [WARemoteInterface sharedInterface];
	NSDictionary *parameters = @{
	@"device": @"ios",
	@"api_key": ri.apiKey,
	@"session_token": ri.userToken,
	@"locale": preferedLanguage,
	@"xurl": @"waveface://x-callback-url/didDisconnectGoogle?api_ret_code=%(api_ret_code)d&api_ret_message=%(api_ret_message)s"
	};
	[request setHTTPBody:IRWebAPIEngineFormURLEncodedDataWithDictionary(parameters)];
	
	__weak WAGoogleConnectSwitch *wSelf = self;
	[self.delegate openOAuthWebViewWithRequest:request completeBlock:^(NSURL *resultURL) {
		NSParameterAssert([NSThread isMainThread]);
		if ([wSelf isSuccessURL:resultURL]) {
			[wSelf setOn:NO animated:YES];
		} else {
			[[[IRAlertView alloc] initWithTitle:NSLocalizedString(@"GOOGLE_DISCONNECT_FAIL_TITLE", @"Title for an alert view to show Google disconnection failure") message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
			[wSelf setOn:YES animated:YES];
		}
	}];
	
}

- (void)setOn:(BOOL)on animated:(BOOL)animated {
	
	[super setOn:on animated:animated];
	
	[[NSUserDefaults standardUserDefaults] setBool:on forKey:kWASNSGoogleConnectEnabled];
	
}

#pragma mark - Target actions

- (void)handleValueChanged:(id)sender {

	if ([[NSUserDefaults standardUserDefaults] boolForKey:kWASNSGoogleConnectEnabled] == self.on) {
		return;
	}

	if (self.on) {
		[[self newGoogleConnectAlertView] show];
	} else {
		[[self newGoogleDisconnectAlertView] show];
	}
	
}

@end
