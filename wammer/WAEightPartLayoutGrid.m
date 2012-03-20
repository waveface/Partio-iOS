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

+ (WAEightPartLayoutGrid *) prototype {

	return (WAEightPartLayoutGrid *)[super prototype];

}

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

/*

+---+---+
| 0 | 4 |
+---+---+
| 1 | 5 |
+---+---+
| 2 | 6 |
+---+---+
| 3 | 7 |
+---+---+

*/

- (NSDictionary *) defaultTilingPatternGroups {

	if (defaultTilingPatternGroups)
		return defaultTilingPatternGroups;
	
	[self willChangeValueForKey:@"defaultTilingPatternGroups"];
	
	defaultTilingPatternGroups = [NSDictionary dictionaryWithObjectsAndKeys:
		
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
				[NSNumber numberWithUnsignedChar:0b10001000],
				[NSNumber numberWithUnsignedChar:0b00010001],
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
		
		[self didChangeValueForKey:@"defaultTilingPatternGroups"];
		
		return defaultTilingPatternGroups;

}

- (IRDiscreteLayoutGrid *) instantiatedGridWithAvailableItems:(NSArray *)items {

	__block NSMutableArray *cleanupOperations = [NSMutableArray array];
	void (^cleanup)() = ^ {
		[cleanupOperations irExecuteAllObjectsAsBlocks];
	};

	
	//	Item introspection helpers
	
	NSMutableArray *availableItems = [[items objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:(NSRange){ 0, MIN([items count], 8) }]] mutableCopy];
	
	id<IRDiscreteLayoutItem> (^nextItem)() = ^ {
	
		if (![availableItems count])
			return (id<IRDiscreteLayoutItem>)nil;
		
		id<IRDiscreteLayoutItem> returnedItem = [availableItems objectAtIndex:0];
		[availableItems removeObjectAtIndex:0];
		
		return returnedItem;
		
	};
	
	//	Layout progress introspection helpers
	
	__block unsigned char tileMap = 0b00000000;
	__block unsigned char nextTile = 0b00000000;
  
  BOOL (^usableTile)(unsigned char) = ^ (unsigned char bitMask) {

    for (unsigned char i = 0b10000000; i > 0; i >>= 1)
      if ( !(tileMap & i) ){
        nextTile = i;
        break;
      }  
		return (BOOL) ( !(tileMap & bitMask) && (bitMask & nextTile) ) ;
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
		
		if (WADiscreteLayoutItemHasImage(currentItem)) {
			[usablePatterns addObjectsFromArray:[self patternsInGroupNamed:@"fourTiles"]];
		}
		
		if (WADiscreteLayoutItemHasImage(currentItem) || WADiscreteLayoutItemHasLongText(currentItem) || WADiscreteLayoutItemHasLink(currentItem) ) {
			[usablePatterns addObjectsFromArray:[self patternsInGroupNamed:@"verticalCombo"]];
			[usablePatterns addObjectsFromArray:[self patternsInGroupNamed:@"horizontalCombo"]];
		}
		
		// increase web preview 2 cell 
		if (WADiscreteLayoutItemHasLink(currentItem)) {
			[usablePatterns addObjectsFromArray:[self patternsInGroupNamed:@"verticalCombo"]];
			[usablePatterns addObjectsFromArray:[self patternsInGroupNamed:@"horizontalCombo"]];
		}
		
		[usablePatterns addObjectsFromArray:[self patternsInGroupNamed:@"singleTile"]];
		
		NSArray *actualPatterns = [usablePatterns irMap: ^ (NSNumber *pattern, NSUInteger index, BOOL *stop) {
			return (NSNumber *)(usableTile([pattern unsignedCharValue]) ? pattern: nil);
		}];
		
		if (![actualPatterns count])
			continue;
		
		unsigned char pattern = [[actualPatterns objectAtIndex:arc4random_uniform([actualPatterns count])] unsignedCharValue];
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
	
	BOOL fullyPopulated = (tileMap == 0b11111111);
	
	if (!fullyPopulated) {
	
		portraitPrototype.populationInspectorBlock = ^ (IRDiscreteLayoutGrid *self) {
			return NO;
		};
		
		landscapePrototype.populationInspectorBlock = ^ (IRDiscreteLayoutGrid *self) {
			return NO;
		};
	
	}
	
	cleanup();
	return returnedInstance;

}

@end
