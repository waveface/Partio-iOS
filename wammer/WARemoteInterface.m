//
//  WARemoteInterface.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/21/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#include <AvailabilityMacros.h>
#import "WADataStore.h"
#import "WADefines.h"

#import "IRWebAPIEngine.h"
#import "IRWebAPIEngine+FormMultipart.h"
#import "IRWebAPIEngine+LocalCaching.h"
#import "IRWebAPIEngine+FormURLEncoding.h"

#import "WAAppDelegate.h"

#import "WADataStore+WARemoteInterfaceAdditions.h"
#import "WARemoteInterfaceContext.h"
#import "WARemoteInterface.h"


@interface WARemoteInterface ()

+ (IRWebAPIResponseParser) defaultParser;

+ (IRWebAPIRequestContextTransformer) defaultBeginNetworkActivityTransformer;
+ (IRWebAPIResponseContextTransformer) defaultEndNetworkActivityTransformer;

+ (IRWebAPIRequestContextTransformer) defaultDeviceInformationProvidingTransformer;

@end


@implementation WARemoteInterface

@synthesize userIdentifier, userToken, primaryGroupIdentifier, defaultBatchSize;
@synthesize apiKey;

+ (WARemoteInterface *) sharedInterface {

	static WARemoteInterface *returnedInterface = nil;
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^{
	
		returnedInterface = [[self alloc] init];
    
	});

	return returnedInterface;

}

+ (JSONDecoder *) sharedDecoder {

	static JSONDecoder *returnedDecoder = nil;
	static dispatch_once_t onceToken = 0;
	
	dispatch_once(&onceToken, ^{
		JKParseOptionFlags sloppy = JKParseOptionComments|JKParseOptionUnicodeNewlines|JKParseOptionLooseUnicode|JKParseOptionPermitTextAfterValidJSON;
		returnedDecoder = [JSONDecoder decoderWithParseOptions:sloppy];
	});

	return returnedDecoder;

}

+ (id) decodedJSONObjectFromData:(NSData *)data {
	
	return [[self sharedDecoder] objectWithData:data];

}

+ (IRWebAPIResponseParser) defaultParser {

	__block __typeof__(self) nrSelf = self;

	return [ ^ (NSData *incomingData) {
	
		NSError *parsingError = nil;
		id anObject = [[nrSelf sharedDecoder] objectWithData:incomingData error:&parsingError];
		
		if (!anObject) {
			NSLog(@"Error parsing: %@", parsingError);
			NSLog(@"Original content is %@", incomingData);
			return (NSDictionary *)nil;
		}
		
		return (NSDictionary *)([anObject isKindOfClass:[NSDictionary class]] ? anObject : @{@"response": anObject});
	
	} copy];

}

+ (IRWebAPIRequestContextTransformer) defaultBeginNetworkActivityTransformer {

	return ^ (IRWebAPIRequestContext *inOriginalContext) {
		dispatch_async(dispatch_get_main_queue(), ^ { [((WAAppDelegate *)AppDelegate()) beginNetworkActivity]; });
		return inOriginalContext;
	};

}

+ (IRWebAPIResponseContextTransformer) defaultEndNetworkActivityTransformer {

	return ^ (NSDictionary *inParsedResponse, IRWebAPIRequestContext *inResponseContext) {
		dispatch_async(dispatch_get_main_queue(), ^ { [((WAAppDelegate *)AppDelegate()) endNetworkActivity]; });
		return inParsedResponse;
	};

}

+ (IRWebAPIRequestContextTransformer) defaultDeviceInformationProvidingTransformer {

  return ^ (IRWebAPIRequestContext *context) {
	
		static NSString *deviceInfo;
		static dispatch_once_t onceToken;
	  
		static NSString *verString;
	  
		dispatch_once(&onceToken, ^{

			UIDevice *device = [UIDevice currentDevice];
			NSBundle *bundle = [NSBundle mainBundle];

			deviceInfo = [@{@"deviceType": @"iOS",
				@"deviceName": device.name,
				@"deviceModel": device.model,
				@"deviceSystemName": device.systemName,
				@"deviceSystemVersion": device.systemVersion,

				@"bundleVersion": [bundle infoDictionary][(id)kCFBundleVersionKey],
				@"bundleName": [bundle infoDictionary][(id)kCFBundleNameKey],
				@"bundleCommit": [bundle infoDictionary][@"IRCommitSHA"]} JSONString];
				
			verString = [NSString stringWithFormat:@"%@.%@", [bundle infoDictionary][@"CFBundleShortVersionString"], [bundle infoDictionary][(id)kCFBundleVersionKey]];

		});
	
		[context setValue:deviceInfo forHeaderField:@"x-wf-origin"];
		[context setValue:verString forHeaderField:@"Waveface-Stream"];
  
		return context;
  
  };

}

- (id) init {

	self = [self initWithEngine:[[IRWebAPIEngine alloc] initWithContext:[WARemoteInterfaceContext context]] authenticator:nil];
	if (!self)
		return nil;
	
	self.defaultBatchSize = 10;
	self.dataRetrievalInterval = 15;
	
	[self addRepeatingDataRetrievalBlocks:[self defaultDataRetrievalBlocks]];
	[self rescheduleAutomaticRemoteUpdates];
	
	return self;

}

- (id) initWithEngine:(IRWebAPIEngine *)engine authenticator:(IRWebAPIAuthenticator *)inAuthenticator {

	self = [super initWithEngine:engine authenticator:inAuthenticator];
	if (!self)
		return nil;

	[engine.globalRequestPreTransformers addObject:[[self class] defaultBeginNetworkActivityTransformer]];
	[engine.globalResponsePostTransformers addObject:[[self class] defaultEndNetworkActivityTransformer]];
  
	[engine.globalRequestPreTransformers addObject:[self defaultV2AuthenticationSignatureBlock]];
	[engine.globalResponsePreTransformers addObject:[self defaultV2AuthenticationListeningBlock]];

	[engine.globalRequestPreTransformers addObject:[[engine class] defaultFormMultipartTransformer]];
	[engine.globalRequestPreTransformers addObject:[[engine class] defaultFormURLEncodingTransformer]];
	[engine.globalResponsePostTransformers addObject:[[engine class] defaultCleanUpTemporaryFilesResponseTransformer]];
  
  [engine.globalRequestPreTransformers addObject:[self defaultHostSwizzlingTransformer]];
  [engine.globalRequestPreTransformers addObject:[[self class] defaultDeviceInformationProvidingTransformer]];
	
	return self;

}

@end
