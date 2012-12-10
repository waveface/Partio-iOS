//
//  WAGoogleConnectSwitch.m
//  wammer
//
//  Created by Shen Steven on 12/9/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAGoogleConnectSwitch.h"
#import "WADefines.h"

@implementation WAGoogleConnectSwitch

- (id) initForStyle:(WASnsConnectStyle)style {
	
	NSAssert((style == WASnsConnectGoogleStyle), @"Invalid WASnsConnectStyle specified");
	
	self = [super init];
	return self;
}

- (void) waConfiguration {
	
	self.styleName = @"Google";
	
	self.keyForDefaultStore = kWASNSGoogleConnectEnabled;
	self.actionConnectShortTitle = NSLocalizedString(@"ACTION_CONNECT_GOOGLE_SHORT", @"Short action title for connecting Google");
	self.actionConnectRequestTitle = NSLocalizedString(@"GOOGLE_CONNECT_REQUEST_TITLE", @"Title for alert view asking if user wants to connect her Google account");
	self.actionConnectRequestMsg = NSLocalizedString(@"GOOGLE_CONNECT_REQUEST_MESSAGE", @"Message for alert view asking if user wants to connect her Google account");
	self.actionDisconnectShortTitle = NSLocalizedString(@"ACTION_DISCONNECT_GOOGLE", @"Short action title for disconnecting Google");
	self.actionDisconnectRequestTitle = NSLocalizedString(@"GOOGLE_DISCONNECT_REQUEST_TITLE", @"Title for alert view asking if user wants to disconnect her Google account");
	self.actionConnectRequestMsg = NSLocalizedString(@"GOOGLE_DISCONNECT_REQUEST_MESSAGE", @"Message for alert view asking if user wants to disconnect her Google account");
	
	self.titleForConnectionFailure = NSLocalizedString(@"GOOGLE_CONNECT_FAIL_TITLE", @"Title for an alert view to show Google connection failure");
	self.titleForDisconnectionFailure = NSLocalizedString(@"GOOGLE_DISCONNECT_FAIL_TITLE", @"Title for an alert view to show Google disconnection failure");
	
	self.requestUriForConnect = @"sns/google/connect";
	self.requestUriForDisconnect = @"sns/google/disconnect";
	self.xurlForConnect = @"waveface://x-callback-url/didConnectGoogle?api_ret_code=%(api_ret_code)d&api_ret_message=%(api_ret_message)s";
	self.xurlForDisconnect = @"waveface://x-callback-url/didDisconnectGoogle?api_ret_code=%(api_ret_code)d&api_ret_message=%(api_ret_message)s";
	
}

@end
