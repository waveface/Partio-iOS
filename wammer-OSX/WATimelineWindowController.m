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

- (NSView *) tableView:(NSTableView *)aTV viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {

	return [aTV makeViewWithIdentifier:@"articleCell" owner:nil];

}

- (CGFloat) tableView:(NSTableView *)aTableView heightOfRow:(NSInteger)row {
	
	static NSString * const kPrototypeCell = @"Prototype";
	NSView *prototypeView = objc_getAssociatedObject(self, &kPrototypeCell);
	if (!prototypeView) {
		prototypeView = [self.tableView makeViewWithIdentifier:@"articleCell" owner:nil];
		objc_setAssociatedObject(self, &kPrototypeCell, prototypeView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	
	
	WAArticle *article = (WAArticle *)[self.arrayController.arrangedObjects objectAtIndex:row];
	
	NSTextField *mainTextField = [prototypeView viewWithTag:24];
	NSParameterAssert(mainTextField);
	
	CGRect oldFrame = mainTextField.frame;
	mainTextField.frame = (NSRect){ NSZeroPoint, (NSSize){ mainTextField.frame.size.width, 0 }};
	[mainTextField setStringValue:article.text];
	[mainTextField sizeToFit];
	CGRect newFrame = mainTextField.frame;
	mainTextField.frame = oldFrame;
	
	//	float_t heightDelta = newFrame.size.height - oldFrame.size.height;
	float_t heightDelta = [mainTextField.cell cellSizeForBounds:(NSRect){ NSZeroPoint, (NSSize){ (aTableView.frame.size.width - prototypeView.frame.size.width) + mainTextField.frame.size.width, 768 } }].height - oldFrame.size.height;
	
	return prototypeView.frame.size.height + heightDelta;
	

	return MAX(
		108,
		([article.text sizeWithFont:[UIFont fontWithName:[[NSFont systemFontOfSize:[NSFont systemFontSize]] familyName] size:[NSFont systemFontSize]]
		 constrainedToSize:(CGSize){ CGRectGetWidth(NSRectToCGRect(aTableView.frame)) - 20, 2048 }].height + 47 + 4)
	);

}

- (void) windowDidLoad {
	
	[super windowDidLoad];
	
	[self.window.contentView setPostsFrameChangedNotifications:YES];
	
	__block __typeof__(self.tableView) nrTV = self.tableView;
	__block id opaqueBlock = [[[NSNotificationCenter defaultCenter] addObserverForName:NSViewFrameDidChangeNotification object:self.window.contentView queue:nil usingBlock: ^ (NSNotification *note) {
		
		[nrTV noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:(NSRange){ 0, [nrTV numberOfRows] }]];
		
	}] retain];
	
	[self irPerformOnDeallocation: ^ {
	
		[[NSNotificationCenter defaultCenter] removeObserver:opaqueBlock];
		[opaqueBlock release];
		
	}];
    
}

- (void) windowDidBecomeKey:(NSNotification *)notification {

	[[WARemoteInterface sharedInterface] performAutomaticRemoteUpdatesNow];

}

- (NSIndexSet *) tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes {

	return [NSIndexSet indexSet];

}

@end
