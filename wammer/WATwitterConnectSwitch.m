//
//  WATwitterConnectSwitch.m
//  wammer
//
//  Created by Shen Steven on 12/9/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WATwitterConnectSwitch.h"
#import "WADefines.h"

@implementation WATwitterConnectSwitch

- (id) initForStyle:(WASnsConnectStyle)style {
	
	NSAssert((style == WASnsConnectTwitterStyle), @"Invalid WASnsConnectStyle specified");
	
	self = [super init];
	return self;
}

- (void) waConfiguration {
	
	self.styleName = @"Twitter";
	
	self.keyForDefaultStore = kWASNSTwitterConnectEnabled;
	self.actionConnectShortTitle = NSLocalizedString(@"ACTION_CONNECT_TWITTER_SHORT", @"Short action title for connecting Twitter");
	self.actionConnectRequestTitle = NSLocalizedString(@"TWITTER_CONNECT_REQUEST_TITLE", @"Title for alert view asking if user wants to connect her Twitter account");
	self.actionConnectRequestMsg = NSLocalizedString(@"TWITTER_CONNECT_REQUEST_MESSAGE", @"Message for alert view asking if user wants to connect her Twitter account");
	self.actionDisconnectShortTitle = NSLocalizedString(@"ACTION_DISCONNECT_TWITTER", @"Short action title for disconnecting Twitter");
	self.actionDisconnectRequestTitle = NSLocalizedString(@"TWITTER_DISCONNECT_REQUEST_TITLE", @"Title for alert view asking if user wants to disconnect her Twitter account");
	self.actionConnectRequestMsg = NSLocalizedString(@"TWITTER_DISCONNECT_REQUEST_MESSAGE", @"Message for alert view asking if user wants to disconnect her Twitter account");
	
	self.titleForConnectionFailure = NSLocalizedString(@"TWITTER_CONNECT_FAIL_TITLE", @"Title for an alert view to show Twitter connection failure");
	self.titleForDisconnectionFailure = NSLocalizedString(@"TWITTER_DISCONNECT_FAIL_TITLE", @"Title for an alert view to show Twitter disconnection failure");
	
	self.requestUriForConnect = @"sns/twitter/connect";
	self.requestUriForDisconnect = @"sns/twitter/disconnect";
	self.xurlForConnect = @"waveface://x-callback-url/didConnectTwitter?api_ret_code=%(api_ret_code)d&api_ret_message=%(api_ret_message)s";
	self.xurlForDisconnect = @"waveface://x-callback-url/didDisconnectTwitter?api_ret_code=%(api_ret_code)d&api_ret_message=%(api_ret_message)s";

}

@end
