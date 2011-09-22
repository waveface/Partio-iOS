//
//  WAEightPartLayoutGrid.m
//  wammer
//
//  Created by Evadne Wu on 9/22/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import "WAEightPartLayoutGrid.h"
#import "Foundation+IRAdditions.h"

@implementation WAEightPartLayoutGrid

- (IRDiscreteLayoutGrid *) instantiatedGridWithAvailableItems:(NSArray *)items {

	NSLog(@"nil is %s", @encode(__typeof__(nil)));
	NSLog(@"0 is %s", @encode(__typeof__(0)));
	
	//	Item introspection helpers
	
	NSMutableArray *availableItems = [[[items objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:(NSRange){ 0, MIN([items count], 8) }]] mutableCopy] autorelease];
	
	id<IRDiscreteLayoutItem> (^nextItem)() = ^ {
	
		if (![availableItems count])
			return (id<IRDiscreteLayoutItem>)nil;
		
		id<IRDiscreteLayoutItem> returnedItem = [[[availableItems objectAtIndex:0] retain] autorelease];
		[availableItems removeObjectAtIndex:0];
		
		return returnedItem;
		
	};
	
	BOOL (^itemHasMediaOfType)(id<IRDiscreteLayoutItem>, CFStringRef) = ^ (id<IRDiscreteLayoutItem> anItem, CFStringRef aMediaType) {
		
		for (id aMediaItem in [anItem representedMediaItems])
			if (UTTypeConformsTo((CFStringRef)[anItem typeForRepresentedMediaItem:aMediaItem], aMediaType))
				return YES;
		
		return NO;

	};
	
	BOOL (^isImageItem)(id<IRDiscreteLayoutItem>) = ^ (id<IRDiscreteLayoutItem> anItem) {
		return itemHasMediaOfType(anItem, kUTTypeImage);
	};
	
	BOOL (^isLinkItem)(id<IRDiscreteLayoutItem>) = ^ (id<IRDiscreteLayoutItem> anItem) {
		return itemHasMediaOfType(anItem, kUTTypeURL);
	};
	
	
	NSMutableArray *cellsToOccupyingItems = [NSMutableArray irArrayByRepeatingObject:[NSNull null] count:8];
	
	//	Layout progress introspection helpers
	
	BOOL (^tileOccupied)(NSUInteger) = ^ (NSUInteger tileIndex) {
		return (BOOL)![[cellsToOccupyingItems objectAtIndex:tileIndex] isEqual:[NSNull null]];
	};
	
	BOOL (^occupiedABEF)() = ^ {
		return (BOOL)(!tileOccupied(0) && !tileOccupied(1) && !tileOccupied(4) && !tileOccupied(5));
	};
	
	BOOL (^occupiedCDGH)() = ^ {
		return (BOOL)(!tileOccupied(2) && !tileOccupied(3) && !tileOccupied(6) && !tileOccupied(7));
	};
	
	
	IRDiscreteLayoutGrid *portraitPrototype = [IRDiscreteLayoutGrid prototype];
	IRDiscreteLayoutGrid *landscapePrototype = [IRDiscreteLayoutGrid prototype];
	
	
	BOOL stop = NO;
	while (!stop) {
	
		id<IRDiscreteLayoutItem> currentItem = nextItem();
		if (!currentItem) {
			stop = YES;
			continue;
		}
		
		if (isImageItem(currentItem)) {
		
			NSLog(@"item is image.");
			
		} else if (isLinkItem(currentItem)) {
		
			NSLog(@"item is link.");			
		
		} else {
		
			NSLog(@"item is plain.");
		
		}
	
	};
	
	
	//	TBD: This creates a lot of retain cycles.  We need to fix this by coalescing stuff perhaps
	//	and also use some internal key-value based grid encoding to save work
	
	[portraitPrototype enumerateLayoutAreaNamesWithBlock:^(NSString *anAreaName) {
		[[portraitPrototype class] markAreaNamed:anAreaName inGridPrototype:portraitPrototype asEquivalentToAreaNamed:anAreaName inGridPrototype:landscapePrototype];
	}];
	
	return portraitPrototype;

}

@end
