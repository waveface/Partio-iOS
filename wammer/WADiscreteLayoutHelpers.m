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
	
	NSMutableArray *enqueuedLayoutGrids = [NSMutableArray array];
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
	
	IRDiscreteLayoutGrid *gridA = [IRDiscreteLayoutGrid prototype];
	gridA.contentSize = portraitSize;
	gridA.allowsPartialInstancePopulation = YES;
	[gridA registerLayoutAreaNamed:@"A" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridA registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 1, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridA registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 1, 1, 1) displayBlock:genericDisplayBlock];
	[gridA registerLayoutAreaNamed:@"D" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 1, 1, 1, 1) displayBlock:genericDisplayBlock];
	[gridA registerLayoutAreaNamed:@"E" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 2, 1, 1) displayBlock:genericDisplayBlock];
	[gridA registerLayoutAreaNamed:@"F" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 1, 2, 1, 1) displayBlock:genericDisplayBlock];
	
	IRDiscreteLayoutGrid *gridA_H = [IRDiscreteLayoutGrid prototype];
	gridA_H.contentSize = landscapeSize;
	gridA_H.allowsPartialInstancePopulation = YES;
	[gridA_H registerLayoutAreaNamed:@"A" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 0, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridA_H registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 0, 1, 1, 1) displayBlock:genericDisplayBlock];
	[gridA_H registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 1, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridA_H registerLayoutAreaNamed:@"D" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 1, 1, 1, 1) displayBlock:genericDisplayBlock];
	[gridA_H registerLayoutAreaNamed:@"E" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 2, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridA_H registerLayoutAreaNamed:@"F" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 2, 1, 1, 1) displayBlock:genericDisplayBlock];
	
	[[gridA class] markAreaNamed:@"A" inGridPrototype:gridA asEquivalentToAreaNamed:@"A" inGridPrototype:gridA_H];
	[[gridA class] markAreaNamed:@"B" inGridPrototype:gridA asEquivalentToAreaNamed:@"B" inGridPrototype:gridA_H];
	[[gridA class] markAreaNamed:@"C" inGridPrototype:gridA asEquivalentToAreaNamed:@"C" inGridPrototype:gridA_H];
	[[gridA class] markAreaNamed:@"D" inGridPrototype:gridA asEquivalentToAreaNamed:@"D" inGridPrototype:gridA_H];
	[[gridA class] markAreaNamed:@"E" inGridPrototype:gridA asEquivalentToAreaNamed:@"E" inGridPrototype:gridA_H];
	[[gridA class] markAreaNamed:@"F" inGridPrototype:gridA asEquivalentToAreaNamed:@"F" inGridPrototype:gridA_H];

	IRDiscreteLayoutGrid *gridB = [IRDiscreteLayoutGrid prototype];
	gridB.contentSize = portraitSize;
	[gridB registerLayoutAreaNamed:@"A" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 0, 1, 1) displayBlock:genericDisplayBlock];	
	[gridB registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 1, 1, 1) displayBlock:genericDisplayBlock];
	[gridB registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 2, 1, 1) displayBlock:genericDisplayBlock];
	[gridB registerLayoutAreaNamed:@"D" validatorBlock:comboValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 1, 0, 1, 2) displayBlock:genericDisplayBlock];
	[gridB registerLayoutAreaNamed:@"E" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 1, 2, 1, 1) displayBlock:genericDisplayBlock];
	
	IRDiscreteLayoutGrid *gridB_H = [IRDiscreteLayoutGrid prototype];
	gridB_H.contentSize = landscapeSize;
	[gridB_H registerLayoutAreaNamed:@"A" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 0, 0, 1, 1) displayBlock:genericDisplayBlock];	
	[gridB_H registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 1, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridB_H registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 2, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridB_H registerLayoutAreaNamed:@"D" validatorBlock:comboValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 0, 1, 2, 1) displayBlock:genericDisplayBlock];
	[gridB_H registerLayoutAreaNamed:@"E" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 2, 1, 1, 1) displayBlock:genericDisplayBlock];
	
	[[gridB class] markAreaNamed:@"A" inGridPrototype:gridB asEquivalentToAreaNamed:@"A" inGridPrototype:gridB_H];
	[[gridB class] markAreaNamed:@"B" inGridPrototype:gridB asEquivalentToAreaNamed:@"B" inGridPrototype:gridB_H];
	[[gridB class] markAreaNamed:@"C" inGridPrototype:gridB asEquivalentToAreaNamed:@"C" inGridPrototype:gridB_H];
	[[gridB class] markAreaNamed:@"D" inGridPrototype:gridB asEquivalentToAreaNamed:@"D" inGridPrototype:gridB_H];
	[[gridB class] markAreaNamed:@"E" inGridPrototype:gridB asEquivalentToAreaNamed:@"E" inGridPrototype:gridB_H];
	
	IRDiscreteLayoutGrid *gridC = [IRDiscreteLayoutGrid prototype];
	gridC.contentSize = portraitSize;
	[gridC registerLayoutAreaNamed:@"A" validatorBlock:comboValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 0, 1, 2) displayBlock:genericDisplayBlock];
	[gridC registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 2, 1, 1) displayBlock:genericDisplayBlock];
	[gridC registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 1, 0, 1, 1) displayBlock:genericDisplayBlock];	
	[gridC registerLayoutAreaNamed:@"D" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 1, 1, 1, 1) displayBlock:genericDisplayBlock];
	[gridC registerLayoutAreaNamed:@"E" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 1, 2, 1, 1) displayBlock:genericDisplayBlock];
	
	IRDiscreteLayoutGrid *gridC_H = [IRDiscreteLayoutGrid prototype];
	gridC_H.contentSize = landscapeSize;
	[gridC_H registerLayoutAreaNamed:@"A" validatorBlock:comboValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 0, 0, 2, 1) displayBlock:genericDisplayBlock];
	[gridC_H registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 2, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridC_H registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 0, 1, 1, 1) displayBlock:genericDisplayBlock];	
	[gridC_H registerLayoutAreaNamed:@"D" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 1, 1, 1, 1) displayBlock:genericDisplayBlock];
	[gridC_H registerLayoutAreaNamed:@"E" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 2, 1, 1, 1) displayBlock:genericDisplayBlock];
	
	[[gridC class] markAreaNamed:@"A" inGridPrototype:gridC asEquivalentToAreaNamed:@"A" inGridPrototype:gridC_H];
	[[gridC class] markAreaNamed:@"B" inGridPrototype:gridC asEquivalentToAreaNamed:@"B" inGridPrototype:gridC_H];
	[[gridC class] markAreaNamed:@"C" inGridPrototype:gridC asEquivalentToAreaNamed:@"C" inGridPrototype:gridC_H];
	[[gridC class] markAreaNamed:@"D" inGridPrototype:gridC asEquivalentToAreaNamed:@"D" inGridPrototype:gridC_H];
	[[gridC class] markAreaNamed:@"E" inGridPrototype:gridC asEquivalentToAreaNamed:@"E" inGridPrototype:gridC_H];
	
	IRDiscreteLayoutGrid *gridD = [IRDiscreteLayoutGrid prototype];
	gridD.contentSize = portraitSize;
	[gridD registerLayoutAreaNamed:@"A" validatorBlock:defaultFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 4, 0, 0, 2, 2) displayBlock:genericDisplayBlock];
	[gridD registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 4, 0, 2, 1, 1) displayBlock:genericDisplayBlock];
	[gridD registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 4, 1, 2, 1, 1) displayBlock:genericDisplayBlock];
	[gridD registerLayoutAreaNamed:@"D" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 4, 0, 3, 1, 1) displayBlock:genericDisplayBlock];
	[gridD registerLayoutAreaNamed:@"E" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 4, 1, 3, 1, 1) displayBlock:genericDisplayBlock];
	
	IRDiscreteLayoutGrid *gridD_H = [IRDiscreteLayoutGrid prototype];
	gridD_H.contentSize = landscapeSize;
	[gridD_H registerLayoutAreaNamed:@"A" validatorBlock:defaultFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(4, 2, 0, 0, 2, 2) displayBlock:genericDisplayBlock];
	[gridD_H registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(4, 2, 2, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridD_H registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(4, 2, 2, 1, 1, 1) displayBlock:genericDisplayBlock];
	[gridD_H registerLayoutAreaNamed:@"D" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(4, 2, 3, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridD_H registerLayoutAreaNamed:@"E" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(4, 2, 3, 1, 1, 1) displayBlock:genericDisplayBlock];
	
	[[gridD class] markAreaNamed:@"A" inGridPrototype:gridD asEquivalentToAreaNamed:@"A" inGridPrototype:gridD_H];
	[[gridD class] markAreaNamed:@"B" inGridPrototype:gridD asEquivalentToAreaNamed:@"B" inGridPrototype:gridD_H];
	[[gridD class] markAreaNamed:@"C" inGridPrototype:gridD asEquivalentToAreaNamed:@"C" inGridPrototype:gridD_H];
	[[gridD class] markAreaNamed:@"D" inGridPrototype:gridD asEquivalentToAreaNamed:@"D" inGridPrototype:gridD_H];
	[[gridD class] markAreaNamed:@"E" inGridPrototype:gridD asEquivalentToAreaNamed:@"E" inGridPrototype:gridD_H];
	
	IRDiscreteLayoutGrid *gridE = [IRDiscreteLayoutGrid prototype];
	gridE.contentSize = portraitSize;
	gridE.allowsPartialInstancePopulation = YES;
	[gridE registerLayoutAreaNamed:@"A" validatorBlock:defaultFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(1, 2, 0, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridE registerLayoutAreaNamed:@"B" validatorBlock:defaultFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(1, 2, 0, 1, 1, 1) displayBlock:genericDisplayBlock];
		
	IRDiscreteLayoutGrid *gridE_H = [IRDiscreteLayoutGrid prototype];
	gridE_H.contentSize = landscapeSize;
	gridE_H.allowsPartialInstancePopulation = YES;
	[gridE_H registerLayoutAreaNamed:@"A" validatorBlock:defaultFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 1, 0, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridE_H registerLayoutAreaNamed:@"B" validatorBlock:defaultFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 1, 1, 0, 1, 1) displayBlock:genericDisplayBlock];
	
	[[gridE class] markAreaNamed:@"A" inGridPrototype:gridE asEquivalentToAreaNamed:@"A" inGridPrototype:gridE_H];
	[[gridE class] markAreaNamed:@"B" inGridPrototype:gridE asEquivalentToAreaNamed:@"B" inGridPrototype:gridE_H];
	
	[enqueuedLayoutGrids addObject:gridA];
	[enqueuedLayoutGrids addObject:gridB];
	[enqueuedLayoutGrids addObject:gridC];
	[enqueuedLayoutGrids addObject:gridD];
	[enqueuedLayoutGrids addObject:gridE];
	
	return enqueuedLayoutGrids;

}
