//
//  WARemoteInterface.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/21/11.
//  Copyright 2011 Waveface. All rights reserved.
//
//  https://gist.github.com/46e424e637d6634979d3

#import "IRWebAPIKit.h"
#import "WARemoteInterfaceDefines.h"
#import "JSONKit.h"

@interface WARemoteInterface : IRWebAPIInterface

+ (WARemoteInterface *) sharedInterface;

+ (JSONDecoder *) sharedDecoder;
+ (id) decodedJSONObjectFromData:(NSData *)data;

@property (nonatomic, readwrite, assign) NSUInteger defaultBatchSize;
@property (nonatomic, readwrite, retain) NSString *apiKey;
@property (nonatomic, readwrite, retain) NSString *userIdentifier;
@property (nonatomic, readwrite, retain) NSString *userToken;

@end

#import "WARemoteInterface+Authentication.h"
#import "WARemoteInterface+Users.h"
#import "WARemoteInterface+Posts.h"
#import "WARemoteInterface+Stations.h"
#import "WARemoteInterface+Groups.h"
#import "WARemoteInterface+Attachments.h"
#import "WARemoteInterface+Previews.h"
#import "WARemoteInterface+Footprints.h"
#import "WARemoteInterface+DeprecatedNonfunctional.h"

#import "WARemoteInterface+ScheduledDataRetrieval.h"













