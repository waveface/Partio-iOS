//
//  WATimelineWindowController.m
//  wammer
//
//  Created by Evadne Wu on 10/9/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WATimelineWindowController.h"
#import "WADataStore.h"
#import "IRLifetimeHelper.h"

#import "WARemoteInterface.h"

#import <UIKit/UIFont.h>


@implementation WATimelineWindowController
@synthesize tableView, arrayController, managedObjectContext;

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
	[arrayController release];
	[managedObjectContext release];
	
	[super dealloc];

}

- (id) init {

	self = [self initWithWindowNibName:@"WATimelineWindow"];
	if (!self)
		return nil;
	
	self.managedObjectContext = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
	
	return self;

}

- (CGFloat) tableView:(NSTableView *)aTableView heightOfRow:(NSInteger)row {
	
	WAArticle *article = (WAArticle *)[self.arrayController.arrangedObjects objectAtIndex:row];
	return MAX(
		108,
		([article.text sizeWithFont:[UIFont fontWithName:[[NSFont systemFontOfSize:[NSFont systemFontSize]] familyName] size:[NSFont systemFontSize]]
		 constrainedToSize:(CGSize){ CGRectGetWidth(NSRectToCGRect(aTableView.frame)) - 72, 2048 }].height + 47)
	);

}

- (void) windowDidLoad {
	
	[super windowDidLoad];
	
	((NSView *)self.window.contentView).wantsLayer = YES;
	self.tableView.superview.wantsLayer = YES;
	
	[self.window.contentView setPostsFrameChangedNotifications:YES];
	
	__block __typeof__(self.tableView) nrTV = self.tableView;
	__block id opaqueBlock = [[[NSNotificationCenter defaultCenter] addObserverForName:NSViewFrameDidChangeNotification object:self.window.contentView queue:nil usingBlock: ^ (NSNotification *note) {
		
		[nrTV noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:(NSRange){ 0, [nrTV numberOfRows] }]];
		
	}] retain];
	
	[self irPerformOnDeallocation: ^ {
	
		[[NSNotificationCenter defaultCenter] removeObserver:opaqueBlock];
		[opaqueBlock release];
		
	}];
	
	//self.tableView.intercellSpacing = NSZeroSize;
    
}

- (void) windowDidBecomeKey:(NSNotification *)notification {

	[[WARemoteInterface sharedInterface] performAutomaticRemoteUpdatesNow];

}

@end
