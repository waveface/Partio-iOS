//
//  WARemoteInterfaceContext.m
//  wammer
//
//  Created by Evadne Wu on 11/4/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WADefines.h"
#import "WARemoteInterfaceContext.h"


NSString * const kWARemoteInterfaceContextDidChangeBaseURLNotification = @"WARemoteInterfaceContextDidChangeBaseURLNotification";
NSString * const kWARemoteInterfaceContextOldBaseURL = @"WARemoteInterfaceContextOldBaseURL";
NSString * const kWARemoteInterfaceContextNewBaseURL = @"WARemoteInterfaceContextNewBaseURL";


@interface WARemoteInterfaceContext ()

+ (NSDictionary *) methodMap;

@end

@implementation WARemoteInterfaceContext

+ (WARemoteInterfaceContext *) context {

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSString *preferredEndpointURLString = [defaults stringForKey:kWARemoteEndpointURL];
	float_t preferredEndpointVersion = [defaults floatForKey:kWARemoteEndpointVersion];
	float_t allowedEndpointVersion = [defaults floatForKey:kWARemoteEndpointCurrentVersion];
	
	if (preferredEndpointVersion < allowedEndpointVersion) {
	
		[defaults removeObjectForKey:kWARemoteEndpointURL];
		preferredEndpointURLString = [defaults stringForKey:kWARemoteEndpointURL];
		
		[defaults removeObjectForKey:kWARemoteEndpointVersion];
		preferredEndpointVersion = allowedEndpointVersion;
		
		[defaults setFloat:preferredEndpointVersion forKey:kWARemoteEndpointVersion];
		
		[defaults synchronize];

	}
	
	//	Talk with defaults
	
	NSURL *baseURL = [NSURL URLWithString:preferredEndpointURLString];
	return [[self alloc] initWithBaseURL:baseURL];
	
}

+ (NSDictionary *) methodMap {

	static NSDictionary *map = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
   
		map = @{@"articles": @"posts/fetch_all/",
			@"users": @"users/fetch_all/",
			@"createArticle": @"post/create_new_post/",
			@"createFile": @"file/upload_file/",
			@"createComment": @"post/create_new_comment/",
			@"lastReadArticleContext": @"users/latest_read_post_id/"};
		
	});

	return map;

}

- (id) initWithBaseURL:(NSURL *)inBaseURL {

	self = [super initWithBaseURL:inBaseURL];
	if (!self)
		return nil;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUserDefaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:nil];
	
	return self;

}

- (void) handleUserDefaultsDidChange:(NSNotification *)aNotification {

	NSURL *oldBaseURL = [self.baseURL copy];
	NSURL *newBaseURL = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:kWARemoteEndpointURL]];
	
	if ([self.baseURL isEqual:newBaseURL])
		return;
	
	self.baseURL = newBaseURL;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kWARemoteInterfaceContextDidChangeBaseURLNotification object:self userInfo:@{kWARemoteInterfaceContextOldBaseURL: oldBaseURL,
		kWARemoteInterfaceContextNewBaseURL: newBaseURL}];

}

- (void) dealloc {

	[[NSNotificationCenter defaultCenter] removeObserver:self];

}

- (NSURL *) baseURLForMethodNamed:(NSString *)inMethodName {

	NSURL *returnedURL = [super baseURLForMethodNamed:inMethodName];
	NSString *mappedPath = nil;
	
	if ((mappedPath = [[self class] methodMap][inMethodName]))
		return [NSURL URLWithString:mappedPath relativeToURL:self.baseURL];
	
	return returnedURL;
	
}

@end
