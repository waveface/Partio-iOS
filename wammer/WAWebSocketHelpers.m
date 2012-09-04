//
//  WAWebSocketHelpers.m
//  wammer
//
//  Created by Shen Steven on 9/4/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAWebSocketHelpers.h"

NSString * composeWSJSONCommand (NSString *command, NSDictionary *arguments) {
	NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:arguments, command, nil];
	if ([NSJSONSerialization isValidJSONObject:data]) {
		NSError *error = nil;
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&error];
		if (jsonData)
			return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
	}
	return nil;
	
}