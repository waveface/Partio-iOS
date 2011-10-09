//
//  WATimelineWindowController.m
//  wammer
//
//  Created by Evadne Wu on 10/9/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WATimelineWindowController.h"
#import "WADataStore.h"

@implementation WATimelineWindowController
@synthesize tableView, managedObjectContext;

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
	[managedObjectContext release];
	
	[super dealloc];

}

- (id) init {

	self = [self initWithWindowNibName:@"WATimelineWindow"];
	if (!self)
		return nil;
	
	self.managedObjectContext = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
	
	//	for (int i = 0; i < 1000; i++) {
	//	
	//		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	//	
	//		WAArticle *newArticle = [[[WAArticle alloc] initWithEntity:[WAArticle entityDescriptionForContext:self.managedObjectContext] insertIntoManagedObjectContext:self.managedObjectContext] autorelease];
	//		newArticle.creationDeviceName = @"Mac";
	//		newArticle.text = @"Hi.";
	//		newArticle.timestamp = [NSDate date];
	//		
	//		[pool drain];
	//	
	//	}
	//	
	//	[self.managedObjectContext save:nil];
	
	return self;

}

- (NSView *) tableView:(NSTableView *)aTableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {

	NSView *cell = [aTableView makeViewWithIdentifier:[tableColumn identifier] owner:self];
	if (!cell) {
	
		static NSNib *cellNib = nil;
		if (!cellNib)
			cellNib = [[NSNib alloc] initWithNibNamed:@"WATimelineCellView" bundle:nil];
		
		NSArray *toplevelObjects = nil;
		if (![cellNib instantiateNibWithOwner:nil topLevelObjects:&toplevelObjects])
			return nil;
			
		cell = [[toplevelObjects filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
			return [evaluatedObject isKindOfClass:[NSView class]];
		}]] lastObject];
		
		cell.wantsLayer = YES;
		cell.layer.borderColor = CGColorCreateGenericRGB(1, 0, 0, 1);
		cell.layer.borderWidth = 2.0f;
		cell.identifier = [tableColumn identifier];
	
	}
	
	return cell;

}

- (void) windowDidLoad {
	
	[super windowDidLoad];
	
	((NSView *)self.window.contentView).wantsLayer = YES;
	self.tableView.superview.wantsLayer = YES;
	//self.tableView.intercellSpacing = NSZeroSize;
    
}

@end
