//
//  WAFoursquareConnectSwitch.m
//  wammer
//
//  Created by Shen Steven on 12/10/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAFoursquareConnectSwitch.h"
#import "WADefines.h"

@implementation WAFoursquareConnectSwitch

- (id) initForStyle:(WASnsConnectStyle)style {
	
	NSAssert((style == WASnsConnectFoursquareStyle), @"Invalid WASnsConnectStyle specified");
	
	self = [super init];
	return self;
}

- (void) waConfiguration {
	
	self.styleName = @"Foursquare";
	
	self.keyForDefaultStore = kWASNSFoursquareConnectEnabled;
	self.actionConnectShortTitle = NSLocalizedString(@"ACTION_CONNECT_FOURSQUARE_SHORT", @"Short action title for connecting Foursquare");
	self.actionConnectRequestTitle = NSLocalizedString(@"FOURSQUARE_CONNECT_REQUEST_TITLE", @"Title for alert view asking if user wants to connect her Foursquare account");
	self.actionConnectRequestMsg = NSLocalizedString(@"FOURSQUARE_CONNECT_REQUEST_MESSAGE", @"Message for alert view asking if user wants to connect her Foursquare account");
	self.actionDisconnectShortTitle = NSLocalizedString(@"ACTION_DISCONNECT_FOURSQUARE", @"Short action title for disconnecting Foursquare");
	self.actionDisconnectRequestTitle = NSLocalizedString(@"FOURSQUARE_DISCONNECT_REQUEST_TITLE", @"Title for alert view asking if user wants to disconnect her Foursquare account");
	self.actionDisconnectRequestMsg = NSLocalizedString(@"FOURSQUARE_DISCONNECT_REQUEST_MESSAGE", @"Message for alert view asking if user wants to disconnect her Foursquare account");
	
	self.titleForConnectionFailure = NSLocalizedString(@"FOURSQUARE_CONNECT_FAIL_TITLE", @"Title for an alert view to show foursquare connection failure");
	self.titleForDisconnectionFailure = NSLocalizedString(@"FOURSQUARE_DISCONNECT_FAIL_TITLE", @"Title for an alert view to show foursquare disconnection failure");
	
	self.requestUriForConnect = @"client/v3/sns/foursquare/connect";
	self.requestUriForDisconnect = @"client/v3/sns/foursquare/disconnect";
	self.xurlForConnect = @"waveface://x-callback-url/didConnectFoursquare?api_ret_code=%(api_ret_code)d&api_ret_message=%(api_ret_message)s";
	self.xurlForDisconnect = @"waveface://x-callback-url/didDisconnectFoursquare?api_ret_code=%(api_ret_code)d&api_ret_message=%(api_ret_message)s";
	
}

@end
