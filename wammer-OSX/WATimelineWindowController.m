//
//  WATimelineWindowController.m
//  wammer
//
//  Created by Evadne Wu on 10/9/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WATimelineWindowController.h"

@implementation WATimelineWindowController
@synthesize tableView;

+ (id) sharedController {
	
	static id instance = nil;
	static dispatch_once_t onceToken = 0;
	
	dispatch_once(&onceToken, ^ {
    instance = [[self alloc] init];
	});

	return instance;

}

- (void) dealloc {

	[tableView release];
	[super dealloc];

}

- (id) init {

	return [self initWithWindowNibName:@"WATimelineWindow"];

}

- (void) windowDidLoad {
	
	[super windowDidLoad];
    
}

@end
