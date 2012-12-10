//
//  WAGoogleConnectSwitch.m
//  wammer
//
//  Created by kchiu on 12/11/30.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WASnsConnectSwitch.h"
#import "UIKit+IRAdditions.h"
#import "WARemoteInterface.h"
#import "WADefines.h"
#import "WAGoogleConnectSwitch.h"
#import "WATwitterConnectSwitch.h"
#import "GAI.h"

@implementation WASnsConnectSwitch

- (id)initForStyle:(WASnsConnectStyle)style {
	self = nil;
	switch (style) {
		case WASnsConnectGoogleStyle: {
			self = [[WAGoogleConnectSwitch alloc] initForStyle:style];
			return self;
		}
			
		case WASnsConnectTwitterStyle: {
			self = [[WATwitterConnectSwitch alloc] initForStyle:style];
			return self;
		}
			
		default:
			[NSException raise:NSInternalInconsistencyException format:@"Unrecognized sns style"];
			break;
	}
	return self;
}

- (id)init {

	self = [super init];
	
	if (self) {
		
		[self waConfiguration];
		[self addTarget:self action:@selector(handleValueChanged:) forControlEvents:UIControlEventValueChanged];
		self.on = [[NSUserDefaults standardUserDefaults] boolForKey:self.keyForDefaultStore];

	}
	return self;

}

- (void) waConfiguration {
	
	[NSException raise:NSInternalInconsistencyException format:@"Subclass shall implement %s", __PRETTY_FUNCTION__];
		
}

- (IRAlertView *)newSnsConnectAlertView {
	
	__weak WASnsConnectSwitch *wSelf = self;
	
	NSString *cancelTitle = NSLocalizedString(@"ACTION_CANCEL", nil);
	IRAction *cancelAction = [IRAction actionWithTitle:cancelTitle block:^{

		[wSelf setOn:NO animated:YES];
		
	}];
	
	IRAction *connectAction = [IRAction actionWithTitle:self.actionConnectShortTitle block:^{
		
		[wSelf handleSnsConnect];
		
	}];
	
	IRAlertView *alertView = [IRAlertView alertViewWithTitle:self.actionConnectRequestTitle message:self.actionConnectRequestMsg cancelAction:cancelAction otherActions:[NSArray arrayWithObjects:connectAction, nil]];
	
	return alertView;
	
}

- (IRAlertView *)newSnsDisconnectAlertView {
	
	__weak WASnsConnectSwitch * const wSelf = self;
	
	NSString *cancelTitle = NSLocalizedString(@"ACTION_CANCEL", nil);
	IRAction *cancelAction = [IRAction actionWithTitle:cancelTitle block:^{
		
		[wSelf setOn:YES animated:YES];

	}];
	
	IRAction *disconnectAction = [IRAction actionWithTitle:self.actionDisconnectShortTitle block:^{
		
		[wSelf handleSnsDisconnect];
		
	}];
		
	IRAlertView *alertView = [IRAlertView alertViewWithTitle:self.actionDisconnectRequestTitle message:self.actionDisconnectRequestMsg cancelAction:cancelAction otherActions:[NSArray arrayWithObjects:disconnectAction, nil]];
	
	return alertView;
	
}

- (void)handleSnsConnect {
	
	NSString *webURL = [[NSUserDefaults standardUserDefaults] stringForKey:kWARemoteEndpointWebURL];
	NSURL *url = [NSURL URLWithString:[webURL stringByAppendingString:self.requestUriForConnect]];
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
	@"xurl": self.xurlForConnect
	};
	[request setHTTPBody:IRWebAPIEngineFormURLEncodedDataWithDictionary(parameters)];
	
	__weak WASnsConnectSwitch *wSelf = self;
	[self.delegate openOAuthWebViewWithRequest:request completeBlock:^(NSURL *resultURL) {
		NSParameterAssert([NSThread isMainThread]);
		if ([wSelf isSuccessURL:resultURL]) {
			[wSelf setOn:YES animated:YES];
			
			[[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Events"
																											 withAction:@"Start Import"
																												withLabel:wSelf.styleName
																												withValue:nil];

		} else {
			IRAlertView *alert =
			[[IRAlertView alloc] initWithTitle:self.titleForConnectionFailure
																 message:nil
																delegate:nil
											 cancelButtonTitle:@"OK"
											 otherButtonTitles:nil];
			[alert show];
			[wSelf setOn:NO animated:YES];
		}
	}];
	
}

- (void)handleSnsDisconnect {
	
	NSString *webURL = [[NSUserDefaults standardUserDefaults] stringForKey:kWARemoteEndpointWebURL];
	NSURL *url = [NSURL URLWithString:[webURL stringByAppendingString:self.requestUriForDisconnect]];
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
	@"xurl": self.xurlForDisconnect
	};
	[request setHTTPBody:IRWebAPIEngineFormURLEncodedDataWithDictionary(parameters)];
	
	__weak WASnsConnectSwitch *wSelf = self;
	[self.delegate openOAuthWebViewWithRequest:request completeBlock:^(NSURL *resultURL) {
		NSParameterAssert([NSThread isMainThread]);
		if ([wSelf isSuccessURL:resultURL]) {
			[wSelf setOn:NO animated:YES];
			[[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Events"
																											 withAction:@"Stop Import"
																												withLabel:wSelf.styleName
																												withValue:nil];

		} else {
			IRAlertView *alert =
			[[IRAlertView alloc] initWithTitle:self.titleForDisconnectionFailure
																 message:nil
																delegate:nil
											 cancelButtonTitle:@"OK"
											 otherButtonTitles:nil];
			[alert show];
			[wSelf setOn:YES animated:YES];
		}
	}];
	
}

- (void)setOn:(BOOL)on animated:(BOOL)animated {
	
	[super setOn:on animated:animated];
	
	[[NSUserDefaults standardUserDefaults] setBool:on forKey:self.keyForDefaultStore];
	
}

#pragma mark - Target actions

- (void)handleValueChanged:(id)sender {

	if ([[NSUserDefaults standardUserDefaults] boolForKey:self.keyForDefaultStore] == self.on) {
		return;
	}
	
	if (self.on) {
		[[self newSnsConnectAlertView] show];

	} else {
		[[self newSnsDisconnectAlertView] show];

	}
	
}

@end
