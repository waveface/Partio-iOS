//
//  WADiscreteLayoutHelpers.m
//  wammer
//
//  Created by Evadne Wu on 3/13/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import "WADiscreteLayoutHelpers.h"
#import "WAArticle.h"

BOOL WADiscreteLayoutItemHasMediaOfType (id<IRDiscreteLayoutItem> anItem, CFStringRef aMediaType) {
	
	for (id aMediaItem in [anItem representedMediaItems])
		if (UTTypeConformsTo((CFStringRef)[anItem typeForRepresentedMediaItem:aMediaItem], aMediaType))
			return YES;
	
	return NO;

};
	
BOOL WADiscreteLayoutItemHasImage (id<IRDiscreteLayoutItem> anItem) {
	
	return WADiscreteLayoutItemHasMediaOfType(anItem, kUTTypeImage);
	
};

BOOL WADiscreteLayoutItemHasLink (id<IRDiscreteLayoutItem> anItem) {
	
	return WADiscreteLayoutItemHasMediaOfType(anItem, kUTTypeURL);
	
};

BOOL WADiscreteLayoutItemHasShortText (id<IRDiscreteLayoutItem> anItem) {
	
	return (BOOL)([[[anItem representedText] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] < 140);

}
	
BOOL WADiscreteLayoutItemHasLongText (id<IRDiscreteLayoutItem> anItem) {
	
	return (BOOL)([[[anItem representedText] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 320);
	
}

NSArray * WADefaultLayoutGrids (void) {

	IRDiscreteLayoutGridAreaDisplayBlock genericDisplayBlock = nil;
	
	CGSize portraitSize = (CGSize){ 768, 1024 };
	CGSize landscapeSize = (CGSize){ 1024, 768 };
	
	BOOL (^itemIsFavorite)(id<IRDiscreteLayoutItem>) = ^ (id<IRDiscreteLayoutItem> item) {
	
		if (![item isKindOfClass:[WAArticle class]])
			return NO;
		
		return [((WAArticle *)item).favorite isEqualToNumber:(id)kCFBooleanTrue];
	
	};
	
	IRDiscreteLayoutGridAreaValidatorBlock defaultNonFavoriteValidator = ^ (IRDiscreteLayoutGrid *self, id anItem) {
	
		return (BOOL)!itemIsFavorite(anItem);
	
	};
	
	IRDiscreteLayoutGridAreaValidatorBlock defaultFavoriteValidator = ^ (IRDiscreteLayoutGrid *self, id anItem) {
	
		return (BOOL)itemIsFavorite(anItem);
	
	};
	
	IRDiscreteLayoutGridAreaValidatorBlock comboValidator = ^ (IRDiscreteLayoutGrid *self, id anItem) {
	
		if (itemIsFavorite(anItem))
			return NO;
	
		return (BOOL)((WADiscreteLayoutItemHasLink(anItem) && WADiscreteLayoutItemHasLongText(anItem)) || WADiscreteLayoutItemHasImage(anItem));
	
	};
	
	IRDiscreteLayoutGridAreaLayoutBlock (^layoutBlockForProportions)(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat) = ^ (CGFloat xUnits, CGFloat yUnits, CGFloat xOffset, CGFloat yOffset, CGFloat xSpan, CGFloat ySpan) {
	
		IRDiscreteLayoutGridAreaLayoutBlock prototype = IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(xUnits, yUnits, xOffset, yOffset, xSpan, ySpan);
		
		return (IRDiscreteLayoutGridAreaLayoutBlock)[^ (IRDiscreteLayoutGrid *grid, id<IRDiscreteLayoutItem>item) {
		
			CGRect answer = prototype(grid, item);
			return CGRectInset(answer, 8, 8);
		
		} copy];
	
	};
	
	return [NSArray arrayWithObjects:
	
		((^{

			IRDiscreteLayoutGrid *grid = [IRDiscreteLayoutGrid prototype];
			grid.identifier = @"6_any_portrait";
			grid.contentSize = portraitSize;
			grid.allowsPartialInstancePopulation = YES;
			[grid registerLayoutAreaNamed:@"A" validatorBlock:nil layoutBlock:layoutBlockForProportions(2, 3, 0, 0, 1, 1) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"B" validatorBlock:nil layoutBlock:layoutBlockForProportions(2, 3, 1, 0, 1, 1) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"C" validatorBlock:nil layoutBlock:layoutBlockForProportions(2, 3, 0, 1, 1, 1) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"D" validatorBlock:nil layoutBlock:layoutBlockForProportions(2, 3, 1, 1, 1, 1) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"E" validatorBlock:nil layoutBlock:layoutBlockForProportions(2, 3, 0, 2, 1, 1) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"F" validatorBlock:nil layoutBlock:layoutBlockForProportions(2, 3, 1, 2, 1, 1) displayBlock:genericDisplayBlock];
			
			IRDiscreteLayoutGrid *gridH = [IRDiscreteLayoutGrid prototype];
			gridH.identifier = @"6_any_landscape";
			gridH.contentSize = landscapeSize;
			gridH.allowsPartialInstancePopulation = YES;
			[gridH registerLayoutAreaNamed:@"A" validatorBlock:nil layoutBlock:layoutBlockForProportions(3, 2, 0, 0, 1, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"B" validatorBlock:nil layoutBlock:layoutBlockForProportions(3, 2, 0, 1, 1, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"C" validatorBlock:nil layoutBlock:layoutBlockForProportions(3, 2, 1, 0, 1, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"D" validatorBlock:nil layoutBlock:layoutBlockForProportions(3, 2, 1, 1, 1, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"E" validatorBlock:nil layoutBlock:layoutBlockForProportions(3, 2, 2, 0, 1, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"F" validatorBlock:nil layoutBlock:layoutBlockForProportions(3, 2, 2, 1, 1, 1) displayBlock:genericDisplayBlock];
			
			[[grid class] markAreaNamed:@"A" inGridPrototype:grid asEquivalentToAreaNamed:@"A" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"B" inGridPrototype:grid asEquivalentToAreaNamed:@"B" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"C" inGridPrototype:grid asEquivalentToAreaNamed:@"C" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"D" inGridPrototype:grid asEquivalentToAreaNamed:@"D" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"E" inGridPrototype:grid asEquivalentToAreaNamed:@"E" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"F" inGridPrototype:grid asEquivalentToAreaNamed:@"F" inGridPrototype:gridH];
			
			return grid;
		
		})()),
		
		((^{
		
			IRDiscreteLayoutGrid *grid = [IRDiscreteLayoutGrid prototype];
			grid.identifier = @"5_non_faves_A_portrait";
			grid.contentSize = portraitSize;
			[grid registerLayoutAreaNamed:@"A" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(2, 3, 0, 0, 1, 1) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(2, 3, 0, 1, 1, 1) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(2, 3, 0, 2, 1, 1) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"D" validatorBlock:comboValidator layoutBlock:layoutBlockForProportions(2, 3, 1, 0, 1, 2) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"E" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(2, 3, 1, 2, 1, 1) displayBlock:genericDisplayBlock];
			
			IRDiscreteLayoutGrid *gridH = [IRDiscreteLayoutGrid prototype];
			gridH.contentSize = landscapeSize;
			gridH.identifier = @"5_non_faves_A_landscape";
			[gridH registerLayoutAreaNamed:@"A" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(3, 2, 0, 0, 1, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(3, 2, 1, 0, 1, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(3, 2, 2, 0, 1, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"D" validatorBlock:comboValidator layoutBlock:layoutBlockForProportions(3, 2, 0, 1, 2, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"E" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(3, 2, 2, 1, 1, 1) displayBlock:genericDisplayBlock];
			
			[[grid class] markAreaNamed:@"A" inGridPrototype:grid asEquivalentToAreaNamed:@"A" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"B" inGridPrototype:grid asEquivalentToAreaNamed:@"B" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"C" inGridPrototype:grid asEquivalentToAreaNamed:@"C" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"D" inGridPrototype:grid asEquivalentToAreaNamed:@"D" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"E" inGridPrototype:grid asEquivalentToAreaNamed:@"E" inGridPrototype:gridH];
			
			return grid;
				
		})()),
		
		((^{
		
			IRDiscreteLayoutGrid *grid = [IRDiscreteLayoutGrid prototype];
			grid.contentSize = portraitSize;
			grid.identifier = @"5_non_faves_B_portrait";
			[grid registerLayoutAreaNamed:@"A" validatorBlock:comboValidator layoutBlock:layoutBlockForProportions(2, 3, 0, 0, 1, 2) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(2, 3, 0, 2, 1, 1) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(2, 3, 1, 0, 1, 1) displayBlock:genericDisplayBlock];	
			[grid registerLayoutAreaNamed:@"D" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(2, 3, 1, 1, 1, 1) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"E" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(2, 3, 1, 2, 1, 1) displayBlock:genericDisplayBlock];
			
			IRDiscreteLayoutGrid *gridH = [IRDiscreteLayoutGrid prototype];
			gridH.contentSize = landscapeSize;
			gridH.identifier = @"5_non_faves_B_landscape";
			[gridH registerLayoutAreaNamed:@"A" validatorBlock:comboValidator layoutBlock:layoutBlockForProportions(3, 2, 0, 0, 2, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(3, 2, 2, 0, 1, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(3, 2, 0, 1, 1, 1) displayBlock:genericDisplayBlock];	
			[gridH registerLayoutAreaNamed:@"D" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(3, 2, 1, 1, 1, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"E" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(3, 2, 2, 1, 1, 1) displayBlock:genericDisplayBlock];
			
			[[grid class] markAreaNamed:@"A" inGridPrototype:grid asEquivalentToAreaNamed:@"A" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"B" inGridPrototype:grid asEquivalentToAreaNamed:@"B" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"C" inGridPrototype:grid asEquivalentToAreaNamed:@"C" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"D" inGridPrototype:grid asEquivalentToAreaNamed:@"D" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"E" inGridPrototype:grid asEquivalentToAreaNamed:@"E" inGridPrototype:gridH];
			
			return grid;
		
		})()),

		((^{
		
			IRDiscreteLayoutGrid *grid = [IRDiscreteLayoutGrid prototype];
			grid.identifier = @"4_non_faves_A_portrait";
			grid.contentSize = portraitSize;
			[grid registerLayoutAreaNamed:@"A" validatorBlock:comboValidator layoutBlock:layoutBlockForProportions(2, 3, 0, 0, 1, 2) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(2, 3, 0, 2, 1, 1) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(2, 3, 1, 0, 1, 1) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"D" validatorBlock:comboValidator layoutBlock:layoutBlockForProportions(2, 3, 1, 1, 1, 2) displayBlock:genericDisplayBlock];
			
			IRDiscreteLayoutGrid *gridH = [IRDiscreteLayoutGrid prototype];
			gridH.contentSize = landscapeSize;
			gridH.identifier = @"4_non_faves_A_landscape";
			[gridH registerLayoutAreaNamed:@"A" validatorBlock:comboValidator layoutBlock:layoutBlockForProportions(3, 2, 0, 0, 2, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(3, 2, 2, 0, 1, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(3, 2, 0, 1, 1, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"D" validatorBlock:comboValidator layoutBlock:layoutBlockForProportions(3, 2, 1, 1, 2, 1) displayBlock:genericDisplayBlock];
			
			[[grid class] markAreaNamed:@"A" inGridPrototype:grid asEquivalentToAreaNamed:@"A" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"B" inGridPrototype:grid asEquivalentToAreaNamed:@"B" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"C" inGridPrototype:grid asEquivalentToAreaNamed:@"C" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"D" inGridPrototype:grid asEquivalentToAreaNamed:@"D" inGridPrototype:gridH];
			
			return grid;
				
		})()),
		
		((^{
		
			IRDiscreteLayoutGrid *grid = [IRDiscreteLayoutGrid prototype];
			grid.contentSize = portraitSize;
			grid.identifier = @"4_non_faves_B_portrait";
			[grid registerLayoutAreaNamed:@"A" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(2, 3, 0, 0, 1, 1) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"B" validatorBlock:comboValidator layoutBlock:layoutBlockForProportions(2, 3, 0, 1, 1, 2) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"C" validatorBlock:comboValidator layoutBlock:layoutBlockForProportions(2, 3, 1, 0, 1, 2) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"D" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(2, 3, 1, 2, 1, 1) displayBlock:genericDisplayBlock];
			
			IRDiscreteLayoutGrid *gridH = [IRDiscreteLayoutGrid prototype];
			gridH.contentSize = landscapeSize;
			gridH.identifier = @"4_non_faves_B_landscape";
			[gridH registerLayoutAreaNamed:@"A" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(3, 2, 0, 0, 1, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"B" validatorBlock:comboValidator layoutBlock:layoutBlockForProportions(3, 2, 1, 0, 2, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"C" validatorBlock:comboValidator layoutBlock:layoutBlockForProportions(3, 2, 0, 1, 2, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"D" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(3, 2, 2, 1, 1, 1) displayBlock:genericDisplayBlock];
			
			[[grid class] markAreaNamed:@"A" inGridPrototype:grid asEquivalentToAreaNamed:@"A" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"B" inGridPrototype:grid asEquivalentToAreaNamed:@"B" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"C" inGridPrototype:grid asEquivalentToAreaNamed:@"C" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"D" inGridPrototype:grid asEquivalentToAreaNamed:@"D" inGridPrototype:gridH];
			
			return grid;
		
		})()),
		
		((^{

			IRDiscreteLayoutGrid *grid = [IRDiscreteLayoutGrid prototype];
			grid.contentSize = portraitSize;
			grid.identifier = @"1_fave_with_4_non_faves_portrait";
			[grid registerLayoutAreaNamed:@"A" validatorBlock:defaultFavoriteValidator layoutBlock:layoutBlockForProportions(2, 4, 0, 0, 2, 2) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(2, 4, 0, 2, 1, 1) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(2, 4, 1, 2, 1, 1) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"D" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(2, 4, 0, 3, 1, 1) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"E" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(2, 4, 1, 3, 1, 1) displayBlock:genericDisplayBlock];
			
			IRDiscreteLayoutGrid *gridH = [IRDiscreteLayoutGrid prototype];
			gridH.contentSize = landscapeSize;
			gridH.identifier = @"1_fave_with_4_non_faves_landscape";
			[gridH registerLayoutAreaNamed:@"A" validatorBlock:defaultFavoriteValidator layoutBlock:layoutBlockForProportions(4, 2, 0, 0, 2, 2) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(4, 2, 2, 0, 1, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(4, 2, 2, 1, 1, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"D" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(4, 2, 3, 0, 1, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"E" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(4, 2, 3, 1, 1, 1) displayBlock:genericDisplayBlock];
			
			[[grid class] markAreaNamed:@"A" inGridPrototype:grid asEquivalentToAreaNamed:@"A" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"B" inGridPrototype:grid asEquivalentToAreaNamed:@"B" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"C" inGridPrototype:grid asEquivalentToAreaNamed:@"C" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"D" inGridPrototype:grid asEquivalentToAreaNamed:@"D" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"E" inGridPrototype:grid asEquivalentToAreaNamed:@"E" inGridPrototype:gridH];

			return grid;
			
		})()),
		
		((^{

			IRDiscreteLayoutGrid *grid = [IRDiscreteLayoutGrid prototype];
			grid.contentSize = portraitSize;
			grid.identifier = @"1_fave_with_3_non_faves_A_portrait";
			[grid registerLayoutAreaNamed:@"A" validatorBlock:defaultFavoriteValidator layoutBlock:layoutBlockForProportions(2, 4, 0, 0, 2, 2) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(2, 4, 0, 2, 1, 1) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(2, 4, 0, 3, 1, 1) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"D" validatorBlock:comboValidator layoutBlock:layoutBlockForProportions(2, 4, 1, 2, 1, 2) displayBlock:genericDisplayBlock];
			
			IRDiscreteLayoutGrid *gridH = [IRDiscreteLayoutGrid prototype];
			gridH.contentSize = landscapeSize;
			gridH.identifier = @"1_fave_with_3_non_faves_A_landscape";
			[gridH registerLayoutAreaNamed:@"A" validatorBlock:defaultFavoriteValidator layoutBlock:layoutBlockForProportions(4, 2, 0, 0, 2, 2) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(4, 2, 2, 0, 1, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(4, 2, 3, 0, 1, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"D" validatorBlock:comboValidator layoutBlock:layoutBlockForProportions(4, 2, 2, 1, 2, 1) displayBlock:genericDisplayBlock];
			
			[[grid class] markAreaNamed:@"A" inGridPrototype:grid asEquivalentToAreaNamed:@"A" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"B" inGridPrototype:grid asEquivalentToAreaNamed:@"B" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"C" inGridPrototype:grid asEquivalentToAreaNamed:@"C" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"D" inGridPrototype:grid asEquivalentToAreaNamed:@"D" inGridPrototype:gridH];

			return grid;
			
		})()),
		
		((^{

			IRDiscreteLayoutGrid *grid = [IRDiscreteLayoutGrid prototype];
			grid.contentSize = portraitSize;
			grid.identifier = @"1_fave_with_3_non_faves_B_portrait";
			[grid registerLayoutAreaNamed:@"A" validatorBlock:defaultFavoriteValidator layoutBlock:layoutBlockForProportions(2, 4, 0, 0, 2, 2) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"B" validatorBlock:comboValidator layoutBlock:layoutBlockForProportions(2, 4, 0, 2, 1, 2) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(2, 4, 1, 2, 1, 1) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"D" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(2, 4, 1, 3, 1, 1) displayBlock:genericDisplayBlock];
			
			IRDiscreteLayoutGrid *gridH = [IRDiscreteLayoutGrid prototype];
			gridH.contentSize = landscapeSize;
			gridH.identifier = @"1_fave_with_3_non_faves_B_landscape";
			[gridH registerLayoutAreaNamed:@"A" validatorBlock:defaultFavoriteValidator layoutBlock:layoutBlockForProportions(4, 2, 0, 0, 2, 2) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"B" validatorBlock:comboValidator layoutBlock:layoutBlockForProportions(4, 2, 2, 0, 2, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(4, 2, 2, 1, 1, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"D" validatorBlock:defaultNonFavoriteValidator layoutBlock:layoutBlockForProportions(4, 2, 3, 1, 1, 1) displayBlock:genericDisplayBlock];
			
			[[grid class] markAreaNamed:@"A" inGridPrototype:grid asEquivalentToAreaNamed:@"A" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"B" inGridPrototype:grid asEquivalentToAreaNamed:@"B" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"C" inGridPrototype:grid asEquivalentToAreaNamed:@"C" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"D" inGridPrototype:grid asEquivalentToAreaNamed:@"D" inGridPrototype:gridH];

			return grid;
			
		})()),
			
		((^{

			IRDiscreteLayoutGrid *grid = [IRDiscreteLayoutGrid prototype];
			grid.contentSize = portraitSize;
			grid.identifier = @"2_faves_portrait";
			[grid registerLayoutAreaNamed:@"A" validatorBlock:defaultFavoriteValidator layoutBlock:layoutBlockForProportions(1, 2, 0, 0, 1, 1) displayBlock:genericDisplayBlock];
			[grid registerLayoutAreaNamed:@"B" validatorBlock:defaultFavoriteValidator layoutBlock:layoutBlockForProportions(1, 2, 0, 1, 1, 1) displayBlock:genericDisplayBlock];
				
			IRDiscreteLayoutGrid *gridH = [IRDiscreteLayoutGrid prototype];
			gridH.contentSize = landscapeSize;
			gridH.identifier = @"2_faves_landscape";
			[gridH registerLayoutAreaNamed:@"A" validatorBlock:defaultFavoriteValidator layoutBlock:layoutBlockForProportions(2, 1, 0, 0, 1, 1) displayBlock:genericDisplayBlock];
			[gridH registerLayoutAreaNamed:@"B" validatorBlock:defaultFavoriteValidator layoutBlock:layoutBlockForProportions(2, 1, 1, 0, 1, 1) displayBlock:genericDisplayBlock];
			
			[[grid class] markAreaNamed:@"A" inGridPrototype:grid asEquivalentToAreaNamed:@"A" inGridPrototype:gridH];
			[[grid class] markAreaNamed:@"B" inGridPrototype:grid asEquivalentToAreaNamed:@"B" inGridPrototype:gridH];
			
			return grid;
			
		})()),

	nil];

}
