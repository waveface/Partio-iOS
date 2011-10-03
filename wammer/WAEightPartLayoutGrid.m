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


@interface WAEightPartLayoutPlacementCandidate : NSObject
+ (id) candidateWithPattern:(unsigned char)aPattern occurance:(float_t)anOccurrence;
@end

@interface WAEightPartLayoutPlacementCandidate ()
@property (nonatomic, readwrite, assign) unsigned char pattern;
@property (nonatomic, readwrite, assign) float_t occurrence;
@end

@implementation WAEightPartLayoutPlacementCandidate
@synthesize pattern, occurrence;
+ (id) candidateWithPattern:(unsigned char)aPattern occurance:(float_t)anOccurrence {
	WAEightPartLayoutPlacementCandidate *returnedInstance = [[self alloc] init];
	returnedInstance.pattern = aPattern;
	returnedInstance.occurrence = anOccurrence;
	return returnedInstance;
}
@end


@interface WAEightPartLayoutGrid ()
@property (nonatomic, readwrite, retain) NSDictionary *defaultTilingPatternGroups;
- (NSArray *) patternsInGroupNamed:(NSString *)aName;
- (CGRect) unitRectForPattern:(unsigned char)aPattern;
@end

@implementation WAEightPartLayoutGrid
@synthesize validatorBlock;
@synthesize displayBlock;
@synthesize defaultTilingPatternGroups;

- (NSArray *) patternsInGroupNamed:(NSString *)aName {

	return [[self defaultTilingPatternGroups] objectForKey:aName];

}

- (CGRect) unitRectForPattern:(unsigned char)aPattern {

	NSParameterAssert(aPattern != 0b0);
	
	static CGRect patternToUnitRects[] = (CGRect[]){
		(CGRect){ 0, 0, 1, 1 },	//	0b10000000 == 1 << 7
		(CGRect){ 0, 1, 1, 1 },
		(CGRect){ 0, 2, 1, 1 },
		(CGRect){ 0, 3, 1, 1 },
		(CGRect){ 1, 0, 1, 1 },
		(CGRect){ 1, 1, 1, 1 },
		(CGRect){ 1, 2, 1, 1 },
		(CGRect){ 1, 3, 1, 1 }		//	0b10000000 == 1 << 0
	};
	
	NSMutableArray *unitRects = [NSMutableArray array];
	
	for (int i = 0; i < 8; i++)
		if (aPattern & (1 << i))
			[unitRects addObject:[NSValue valueWithCGRect:patternToUnitRects[7 - i]]];
		
	CGRect unitRect = [[unitRects lastObject] CGRectValue];
	for (NSValue *aRectValue in unitRects)
		unitRect = CGRectUnion(unitRect, [aRectValue CGRectValue]);
	
	return unitRect;

}

- (NSDictionary *) defaultTilingPatternGroups {

	if (defaultTilingPatternGroups)
		return defaultTilingPatternGroups;
	
	[self willChangeValueForKey:@"defaultTilingPatternGroups"];
	
	defaultTilingPatternGroups = [[NSDictionary dictionaryWithObjectsAndKeys:
		
			[NSArray arrayWithObjects:
				[NSNumber numberWithUnsignedChar:0b11001100],
				[NSNumber numberWithUnsignedChar:0b00110011],
			nil], @"fourTiles",
			
			[NSArray arrayWithObjects:
				[NSNumber numberWithUnsignedChar:0b11000000],
				[NSNumber numberWithUnsignedChar:0b00110000],
				[NSNumber numberWithUnsignedChar:0b00001100],
				[NSNumber numberWithUnsignedChar:0b00000011],
			nil], @"verticalCombo",
			
			[NSArray arrayWithObjects:
				[NSNumber numberWithUnsignedChar:0b01000100],
				[NSNumber numberWithUnsignedChar:0b00100010],
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
			
		nil] retain];
		
		[self didChangeValueForKey:@"defaultTilingPatternGroups"];
		
		return defaultTilingPatternGroups;

}

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
	
	BOOL (^isLinkItem)(id<IRDiscreteLayoutItem>) = ^ (id<IRDiscreteLayoutItem> anItem) {
		return itemHasMediaOfType(anItem, kUTTypeURL);
	};
	
	BOOL (^isTextItem)(id<IRDiscreteLayoutItem>) = ^ (id<IRDiscreteLayoutItem> anItem) {
		return (BOOL)!![[[anItem representedText] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length];
	};
	
	BOOL (^isLongTextItem)(id<IRDiscreteLayoutItem>) = ^ (id<IRDiscreteLayoutItem> anItem) {
		return (BOOL)([[[anItem representedText] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 32);
	};
	
	
	//	Layout progress introspection helpers
	
	__block unsigned char tileMap = 0b00000000;
	
	BOOL (^tilesOccupied)(unsigned char) = ^ (unsigned char bitMask) {
		return (BOOL)(tileMap & bitMask);
	};
		
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
		
		NSMutableArray *usablePatterns = [NSMutableArray array];
		
		if (isImageItem(currentItem)) {
			[usablePatterns addObjectsFromArray:[self patternsInGroupNamed:@"fourTiles"]];
		}
		
		if (isImageItem(currentItem) || isLinkItem(currentItem) || isLongTextItem(currentItem)) {
			[usablePatterns addObjectsFromArray:[self patternsInGroupNamed:@"verticalCombo"]];
			[usablePatterns addObjectsFromArray:[self patternsInGroupNamed:@"horizontalCombo"]];
		}
		
		[usablePatterns addObjectsFromArray:[self patternsInGroupNamed:@"singleTile"]];
		
		
		NSArray *actualPatterns = [usablePatterns irMap: ^ (NSNumber *pattern, int index, BOOL *stop) {
			return (NSNumber *)(tilesOccupied([pattern unsignedCharValue]) ? nil : pattern);
		}];
		
		if (![actualPatterns count])
			continue;
		
		
		unsigned char pattern = [[actualPatterns objectAtIndex:0] unsignedCharValue];
		tileMap |= pattern;
		
		CGRect unitRect = [self unitRectForPattern:pattern];
		
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
	[defaultTilingPatternGroups release];
	[super dealloc];

}

@end
