//
//  WARemoteInterfaceContext.m
//  wammer
//
//  Created by Evadne Wu on 11/4/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WADefines.h"
#import "WARemoteInterfaceContext.h"

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
	return [[[self alloc] initWithBaseURL:baseURL] autorelease];
	
}

+ (NSDictionary *) methodMap {

	static NSDictionary *map = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
   
		map = [[NSDictionary dictionaryWithObjectsAndKeys:
		
			@"posts/fetch_all/", @"articles",
			@"users/fetch_all/", @"users",
			@"post/create_new_post/", @"createArticle",
			@"file/upload_file/", @"createFile",
			@"post/create_new_comment/", @"createComment",
			@"users/latest_read_post_id/", @"lastReadArticleContext",
			
		nil] retain];
		
	});

	return map;

}

- (NSURL *) baseURLForMethodNamed:(NSString *)inMethodName {

	NSURL *returnedURL = [super baseURLForMethodNamed:inMethodName];
	NSString *mappedPath = nil;
	
	if ((mappedPath = [[[self class] methodMap] objectForKey:inMethodName]))
		return [NSURL URLWithString:mappedPath relativeToURL:self.baseURL];
	
	return returnedURL;
	
}

@end
