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

- (NSArray *) sortDescriptors {

	return [NSArray arrayWithObjects:
		[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO],
	nil];

}

- (WARemoteInterface *) remoteInterface {

	return [WARemoteInterface sharedInterface];

}

- (NSView *) tableView:(NSTableView *)aTV viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {

	return [aTV makeViewWithIdentifier:@"articleCell" owner:nil];

}

- (CGFloat) tableView:(NSTableView *)aTableView heightOfRow:(NSInteger)row {
	
	WAArticle *article = (WAArticle *)[self.arrayController.arrangedObjects objectAtIndex:row];
	
#if 0
	
	NSString *string = article.text;
	NSFont *font = [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]];
	CGFloat width = (self.tableView.frame.size.width - 20 - 20);
	
	NSTextStorage *textStorage = [[[NSTextStorage alloc] initWithString:string] autorelease];
	NSTextContainer *textContainer = [[[NSTextContainer alloc] initWithContainerSize:NSMakeSize(width, FLT_MAX)] autorelease];
	NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init] autorelease];
	[layoutManager addTextContainer:textContainer];
	[textStorage addLayoutManager:layoutManager];
	[textStorage addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [textStorage length])];
	[textContainer setLineFragmentPadding:0.0];
	(void)[layoutManager glyphRangeForTextContainer:textContainer];
	
	return [layoutManager usedRectForTextContainer:textContainer].size.height + 55;
	
#endif
	
	static NSString * const kPrototypeCell = @"Prototype";
	NSView *prototypeView = objc_getAssociatedObject(self, &kPrototypeCell);
	if (!prototypeView) {
		prototypeView = [self.tableView makeViewWithIdentifier:@"articleCell" owner:nil];
		objc_setAssociatedObject(self, &kPrototypeCell, prototypeView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	
	NSTextField *mainTextField = [prototypeView viewWithTag:24];
	CGRect oldFrame = mainTextField.frame;
	
	[mainTextField setStringValue:article.text];
	float_t heightDelta = [mainTextField.cell cellSizeForBounds:(NSRect){ NSZeroPoint, (NSSize){ (aTableView.frame.size.width - prototypeView.frame.size.width) + mainTextField.frame.size.width, 768 } }].height - oldFrame.size.height;
	
	return prototypeView.frame.size.height + heightDelta;

}

- (void) windowDidLoad {
	
	[super windowDidLoad];
	
	[self.window.contentView setPostsFrameChangedNotifications:YES];
	
	__block __typeof__(self.tableView) nrTV = self.tableView;
	__block id opaqueBlock = [[[NSNotificationCenter defaultCenter] addObserverForName:NSViewFrameDidChangeNotification object:self.window.contentView queue:nil usingBlock: ^ (NSNotification *note) {
	
		static CGRect lastRect = (CGRect){ 0, 0, 0, 0 };
		CGRect currentRect = ((NSView *)[note object]).frame;
	
		//	[[nrTV class] cancelPreviousPerformRequestsWithTarget:nrTV selector:@selector(noteHeightOfRowsWithIndexesChanged:) object:nil];
		//	[nrTV performSelector:@selector(noteHeightOfRowsWithIndexesChanged:) withObject:[NSIndexSet indexSetWithIndexesInRange:(NSRange){ 0, [nrTV numberOfRows] }] afterDelay:1];
		
		if (lastRect.size.width != currentRect.size.width)
			[nrTV noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:(NSRange){ 0, [nrTV numberOfRows] }]];
		
		lastRect = currentRect;
		
	}] retain];
	
	[self irPerformOnDeallocation: ^ {
	
		[[NSNotificationCenter defaultCenter] removeObserver:opaqueBlock];
		[opaqueBlock release];
		
	}];
    
}

- (void) windowDidBecomeKey:(NSNotification *)notification {

	[[WARemoteInterface sharedInterface] rescheduleAutomaticRemoteUpdates];

}

- (NSIndexSet *) tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes {

	return [NSIndexSet indexSet];

}

- (void) handleRefresh:(id)sender {

	[[WARemoteInterface sharedInterface] performAutomaticRemoteUpdatesNow];

}

- (void) handleList:(id)sender {

	//	?

}

@end
