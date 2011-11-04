//
//  WARemoteInterfaceContext.m
//  wammer
//
//  Created by Evadne Wu on 11/4/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WADefines.h"
#import "WARemoteInterfaceContext.h"

@implementation WARemoteInterfaceContext

+ (WARemoteInterfaceContext *) context {

	NSString *preferredEndpointURLString = [[NSUserDefaults standardUserDefaults] stringForKey:kWARemoteEndpointURL];
	NSURL *baseURL = [NSURL URLWithString:preferredEndpointURLString];
	return [[[self alloc] initWithBaseURL:baseURL] autorelease];
	
}

- (NSURL *) baseURLForMethodNamed:(NSString *)inMethodName {

	NSURL *returnedURL = [super baseURLForMethodNamed:inMethodName];
	
	if ([inMethodName isEqualToString:@"authenticate"])
		returnedURL = [NSURL URLWithString:@"auth/login/" relativeToURL:self.baseURL];
	
	if ([inMethodName isEqualToString:@"articles"])
		returnedURL = [NSURL URLWithString:@"posts/fetch_all/" relativeToURL:self.baseURL];
	
	if ([inMethodName isEqualToString:@"users"])
		returnedURL = [NSURL URLWithString:@"users/fetch_all/" relativeToURL:self.baseURL];
		
	if ([inMethodName isEqualToString:@"createArticle"])
		returnedURL = [NSURL URLWithString:@"post/create_new_post/" relativeToURL:self.baseURL];
		
	if ([inMethodName isEqualToString:@"createFile"])
		returnedURL = [NSURL URLWithString:@"file/upload_file/" relativeToURL:self.baseURL];
		
	if ([inMethodName isEqualToString:@"createComment"])
		returnedURL = [NSURL URLWithString:@"post/create_new_comment/" relativeToURL:self.baseURL];
	
	if ([inMethodName isEqualToString:@"lastReadArticleContext"])
		returnedURL = [NSURL URLWithString:@"users/latest_read_post_id/" relativeToURL:self.baseURL];
		
	return returnedURL;

}

@end
