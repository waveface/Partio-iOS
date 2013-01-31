//
//  WAGoogleConnectSwitch.h
//  wammer
//
//  Created by kchiu on 12/11/30.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAOAuthSwitch.h"

typedef NS_ENUM(NSUInteger, WASnsConnectStyle) {
	WASnsConnectGoogleStyle,
	WASnsConnectFoursquareStyle,
};

@interface WASnsConnectSwitch : WAOAuthSwitch

- (id)initForStyle:(WASnsConnectStyle)style;

@property (nonatomic, strong) NSString *styleName;

@property (nonatomic, strong) NSString *keyForDefaultStore;

@property (nonatomic, strong) NSString *actionConnectShortTitle;
@property (nonatomic, strong) NSString *actionConnectRequestTitle;
@property (nonatomic, strong) NSString *actionConnectRequestMsg;
@property (nonatomic, strong) NSString *actionDisconnectShortTitle;
@property (nonatomic, strong) NSString *actionDisconnectRequestTitle;
@property (nonatomic, strong) NSString *actionDisconnectRequestMsg;
@property (nonatomic, strong) NSString *titleForConnectionFailure;
@property (nonatomic, strong) NSString *titleForDisconnectionFailure;

@property (nonatomic, strong) NSString *requestUriForConnect;
@property (nonatomic, strong) NSString *xurlForConnect;
@property (nonatomic, strong) NSString *requestUriForDisconnect;
@property (nonatomic, strong) NSString *xurlForDisconnect;

@end
