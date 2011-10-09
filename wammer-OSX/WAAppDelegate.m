//
//  WAAppDelegate.m
//  wammer-OSX
//
//  Created by Evadne Wu on 10/9/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import "WAAppDelegate.h"
#import "WATimelineWindowController.h"

@implementation WAAppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {

	[[[WATimelineWindowController sharedController] window] makeKeyAndOrderFront:self];
	
	NSNib *compositionNib = [[NSNib alloc] initWithNibNamed:@"WAArticleCompositionWindow" bundle:nil];
	NSArray *compositionObjects = nil;
	if ([compositionNib instantiateNibWithOwner:nil topLevelObjects:&compositionObjects]) {
	
	[compositionObjects retain];
	
		[[compositionObjects filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
			return [evaluatedObject isKindOfClass:[NSWindow class]];
		}]] enumerateObjectsUsingBlock:^(NSWindow *aWindow, NSUInteger idx, BOOL *stop) {
			[aWindow orderFront:nil];
		}];
	
	};

}

@end
