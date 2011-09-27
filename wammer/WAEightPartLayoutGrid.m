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
@synthesize validatorBlock;
@synthesize displayBlock;

- (IRDiscreteLayoutGrid *) instantiatedGridWithAvailableItems:(NSArray *)items {

	__block NSMutableArray *cleanupOperations = [NSMutableArray array];
	void (^cleanup)() = ^ {
		[cleanupOperations irExecuteAllObjectsAsBlocks];
	};

	
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
	
	//	BOOL (^isLinkItem)(id<IRDiscreteLayoutItem>) = ^ (id<IRDiscreteLayoutItem> anItem) {
	//		return itemHasMediaOfType(anItem, kUTTypeURL);
	//	};
	
	
	//	Layout progress introspection helpers
	
	__block unsigned char tileMap = 0b00000000;
	
	BOOL (^tileOccupied)(NSUInteger) = ^ (NSUInteger tileIndex) {
		return (BOOL)(tileMap & (1 << tileIndex));
	};
	
	BOOL (^tilesOccupied)(unsigned char) = ^ (unsigned char bitMask) {
		return (BOOL)(tileMap & bitMask);
	};
	
	//	BOOL (^occupyTile)(NSUInteger) = ^ (NSUInteger tileToOccupy) {
	//		if (tileOccupied(tileToOccupy)) {
	//			return NO;
	//		}
	//		tileMap &= (1 << tileToOccupy);
	//		return YES;
	//	};
	
	IRDiscreteLayoutGrid *portraitPrototype = [IRDiscreteLayoutGrid prototype];
	portraitPrototype.contentSize = (CGSize){ 768, 1024 };
	
	IRDiscreteLayoutGrid *landscapePrototype = [IRDiscreteLayoutGrid prototype];
	landscapePrototype.contentSize = (CGSize){ 1024, 768 };
	
	NSMutableDictionary *layoutAreaNamesToItems = [NSMutableDictionary dictionary];
	
	BOOL stop = NO;
	while (!stop) {
	
		id<IRDiscreteLayoutItem> currentItem = nextItem();
		if (!currentItem) {
			stop = YES;
			continue;
		}
		
		//	 Instead of querying, enumerate all available and usable combos…
		
		NSDictionary *patternsToTiles = [NSDictionary dictionaryWithObjectsAndKeys:
		
			[NSArray arrayWithObjects:
				[NSNumber numberWithUnsignedChar:0b11001100],
				[NSNumber numberWithUnsignedChar:0b00110011],
			nil], @"fourTiles",
			
			[NSArray arrayWithObjects:
				[NSNumber numberWithUnsignedChar:0b11000000],
			//	[NSNumber numberWithUnsignedChar:0b01100000],
				[NSNumber numberWithUnsignedChar:0b00110000],
				[NSNumber numberWithUnsignedChar:0b00001100],
			//	[NSNumber numberWithUnsignedChar:0b00000110],
				[NSNumber numberWithUnsignedChar:0b00000011],
			nil], @"verticalCombo",
			
			[NSArray arrayWithObjects:
			//	[NSNumber numberWithUnsignedChar:0b10001000],
				[NSNumber numberWithUnsignedChar:0b01000100],
				[NSNumber numberWithUnsignedChar:0b00100010],
			//	[NSNumber numberWithUnsignedChar:0b00010001],
			nil], @"horizontalCombo",
			
			[NSArray arrayWithObjects:
				[NSNumber numberWithUnsignedChar:0b10000000],
				[NSNumber numberWithUnsignedChar:0b01000000],
				[NSNumber numberWithUnsignedChar:0b00100000],
				[NSNumber numberWithUnsignedChar:0b00010000],
				[NSNumber numberWithUnsignedChar:0b00001000],
				[NSNumber numberWithUnsignedChar:0b00000100],
				[NSNumber numberWithUnsignedChar:0b00000010],
				[NSNumber numberWithUnsignedChar:0b00000001],
			nil], @"singleTile",
			
		nil];
		
		
		NSMutableArray *usablePatterns = [NSMutableArray array];
		
		if (isImageItem(currentItem))// || isLinkItem(currentItem))
			[usablePatterns addObjectsFromArray:[(NSArray *)[patternsToTiles objectForKey:@"fourTiles"] irShuffle]];
		
		[usablePatterns addObjectsFromArray:[(NSArray *)[patternsToTiles objectForKey:@"verticalCombo"] irShuffle]];
		[usablePatterns addObjectsFromArray:[(NSArray *)[patternsToTiles objectForKey:@"horizontalCombo"] irShuffle]];		
		[usablePatterns addObjectsFromArray:[(NSArray *)[patternsToTiles objectForKey:@"singleTile"] irShuffle]];
		
		NSArray *actualPatterns = [usablePatterns irMap: ^ (NSNumber *pattern, int index, BOOL *stop) {
			return (NSNumber *)(tilesOccupied([pattern unsignedCharValue]) ? nil : pattern);
		}];
		
		if (![actualPatterns count])
			continue;
		
		unsigned char pattern = [[actualPatterns objectAtIndex:0] unsignedCharValue];
		
		tileMap |= pattern;
		
		NSMutableArray *unitRects = [NSMutableArray array];
		
		if (pattern & 0b10000000)
			[unitRects addObject:[NSValue valueWithCGRect:(CGRect){ 0, 0, 1, 1 }]];
		
		if (pattern & 0b01000000)
			[unitRects addObject:[NSValue valueWithCGRect:(CGRect){ 0, 1, 1, 1 }]];

		if (pattern & 0b00100000)
			[unitRects addObject:[NSValue valueWithCGRect:(CGRect){ 0, 2, 1, 1 }]];

		if (pattern & 0b00010000)
			[unitRects addObject:[NSValue valueWithCGRect:(CGRect){ 0, 3, 1, 1 }]];
			
		if (pattern & 0b00001000)
			[unitRects addObject:[NSValue valueWithCGRect:(CGRect){ 1, 0, 1, 1 }]];
		
		if (pattern & 0b00000100)
			[unitRects addObject:[NSValue valueWithCGRect:(CGRect){ 1, 1, 1, 1 }]];

		if (pattern & 0b00000010)
			[unitRects addObject:[NSValue valueWithCGRect:(CGRect){ 1, 2, 1, 1 }]];

		if (pattern & 0b00000001)
			[unitRects addObject:[NSValue valueWithCGRect:(CGRect){ 1, 3, 1, 1 }]];
		
		NSParameterAssert(pattern != 0b0);
		
		CGRect unitRect = [[unitRects lastObject] CGRectValue];
		for (NSValue *aRectValue in unitRects)
			unitRect = CGRectUnion(unitRect, [aRectValue CGRectValue]);
		
		NSString *layoutAreaName = [NSString stringWithFormat:@"_synthesized_%x", pattern];
		
		[portraitPrototype registerLayoutAreaNamed:layoutAreaName validatorBlock:self.validatorBlock layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(
			2,
			4,
			unitRect.origin.x,
			unitRect.origin.y,
			unitRect.size.width,
			unitRect.size.height
		) displayBlock:self.displayBlock];
		
		[landscapePrototype registerLayoutAreaNamed:layoutAreaName validatorBlock:self.validatorBlock layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(
			4,
			2,
			unitRect.origin.y,
			unitRect.origin.x,
			unitRect.size.height,
			unitRect.size.width
		) displayBlock:self.displayBlock];
		
		[layoutAreaNamesToItems setObject:currentItem forKey:layoutAreaName];
	
	};
	
	
	//	TBD: This creates a lot of retain cycles.  We need to fix this by coalescing stuff perhaps
	//	and also use some internal key-value based grid encoding to save work
	
	[portraitPrototype enumerateLayoutAreaNamesWithBlock: ^ (NSString *anAreaName) {
		[[portraitPrototype class] markAreaNamed:anAreaName inGridPrototype:portraitPrototype asEquivalentToAreaNamed:anAreaName inGridPrototype:landscapePrototype];
	}];
	
	IRDiscreteLayoutGrid *returnedInstance = [portraitPrototype instantiatedGrid];
	[layoutAreaNamesToItems enumerateKeysAndObjectsUsingBlock: ^ (NSString *layoutAreaName, id<IRDiscreteLayoutItem>associatedItem, BOOL *stop) {
		[returnedInstance setLayoutItem:associatedItem forAreaNamed:layoutAreaName];
	}];
	
	cleanup();
	return returnedInstance;

}

- (void) dealloc {

	[validatorBlock release];
	[displayBlock release];
	[super dealloc];

}

@end
