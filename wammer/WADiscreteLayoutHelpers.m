//
//  WADiscreteLayoutHelpers.m
//  wammer
//
//  Created by Evadne Wu on 3/13/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import "WADiscreteLayoutHelpers.h"
#import "WADiscreteLayoutArea.h"
#import "WAArticle.h"

NSArray * WADefaultLayoutGridsMake (void);

static NSString * const kItemHasImage = @"WADiscreteLayoutItemHasImage()";
static NSString * const kItemHasLink = @"WADiscreteLayoutItemHasLink()";
static NSString * const kItemHasShortText = @"WADiscreteLayoutItemHasShortText()";
static NSString * const kItemHasLongText = @"WADiscreteLayoutItemHasLongText()";
static NSString * const kItemIsFavorite = @"WADiscreteLayoutItemIsFavorite()";

BOOL WADiscreteLayoutItemHasMediaOfType (id<IRDiscreteLayoutItem> anItem, CFStringRef aMediaType) {
	
	for (id aMediaItem in [anItem representedMediaItems])
		if (UTTypeConformsTo((CFStringRef)[anItem typeForRepresentedMediaItem:aMediaItem], aMediaType))
			return YES;
	
	return NO;

};
	
BOOL WADiscreteLayoutItemHasImage (id<IRDiscreteLayoutItem> anItem) {

	id const cachedValue = objc_getAssociatedObject(anItem, &kItemHasImage);
	if (cachedValue)
		return (cachedValue == (id)kCFBooleanTrue);
	
	BOOL const answer = [anItem isKindOfClass:[WAArticle class]] ?
		[((WAArticle *)anItem).files count] :
		WADiscreteLayoutItemHasMediaOfType(anItem, kUTTypeImage);
	
	objc_setAssociatedObject(anItem, &kItemHasImage, (id)(answer ? kCFBooleanTrue : kCFBooleanFalse), OBJC_ASSOCIATION_ASSIGN);
	
	return answer;
	
};

BOOL WADiscreteLayoutItemHasLink (id<IRDiscreteLayoutItem> anItem) {
	
	id const cachedValue = objc_getAssociatedObject(anItem, &kItemHasLink);
	if (cachedValue)
		return (cachedValue == (id)kCFBooleanTrue);
	
	BOOL const answer = [anItem isKindOfClass:[WAArticle class]] ?
		[((WAArticle *)anItem).previews count] :
		WADiscreteLayoutItemHasMediaOfType(anItem, kUTTypeURL);
	
	objc_setAssociatedObject(anItem, &kItemHasLink, (id)(answer ? kCFBooleanTrue : kCFBooleanFalse), OBJC_ASSOCIATION_ASSIGN);
	
	return answer;
	
};

BOOL WADiscreteLayoutItemHasShortText (id<IRDiscreteLayoutItem> anItem) {
	
	id const cachedValue = objc_getAssociatedObject(anItem, &kItemHasShortText);
	if (cachedValue)
		return (cachedValue == (id)kCFBooleanTrue);
	
	BOOL const answer = [anItem isKindOfClass:[WAArticle class]] ?
		([((WAArticle *)anItem).text length] < 140) :
		([[[anItem representedText] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] < 140);
	
	objc_setAssociatedObject(anItem, &kItemHasShortText, (id)(answer ? kCFBooleanTrue : kCFBooleanFalse), OBJC_ASSOCIATION_ASSIGN);
	
	return answer;

}
	
BOOL WADiscreteLayoutItemHasLongText (id<IRDiscreteLayoutItem> anItem) {

	id const cachedValue = objc_getAssociatedObject(anItem, &kItemHasLongText);
	if (cachedValue)
		return (cachedValue == (id)kCFBooleanTrue);
	
	BOOL const answer = [anItem isKindOfClass:[WAArticle class]] ?
		([((WAArticle *)anItem).text length] > 320) :
		([[[anItem representedText] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 320);
	
	objc_setAssociatedObject(anItem, &kItemHasLongText, (id)(answer ? kCFBooleanTrue : kCFBooleanFalse), OBJC_ASSOCIATION_ASSIGN);
		
	return answer;
	
}

BOOL WADiscreteLayoutItemIsFavorite (id<IRDiscreteLayoutItem> anItem) {

	id const cachedValue = objc_getAssociatedObject(anItem, &kItemIsFavorite);
	if (cachedValue)
		return (cachedValue == (id)kCFBooleanTrue);
	
	BOOL const answer = [anItem isKindOfClass:[WAArticle class]] ?
		[((WAArticle *)anItem).favorite isEqualToNumber:(id)kCFBooleanTrue] :
		NO;
	
	objc_setAssociatedObject(anItem, &kItemIsFavorite, (id)(answer ? kCFBooleanTrue : kCFBooleanFalse), OBJC_ASSOCIATION_ASSIGN);
		
	return answer;

}

void WADiscreteLayoutResetCachedValuesForItem (id<IRDiscreteLayoutItem> item) {

	objc_setAssociatedObject(item, &kItemHasImage, nil, OBJC_ASSOCIATION_ASSIGN);
	objc_setAssociatedObject(item, &kItemHasLink, nil, OBJC_ASSOCIATION_ASSIGN);
	objc_setAssociatedObject(item, &kItemHasShortText, nil, OBJC_ASSOCIATION_ASSIGN);
	objc_setAssociatedObject(item, &kItemHasLongText, nil, OBJC_ASSOCIATION_ASSIGN);
	objc_setAssociatedObject(item, &kItemIsFavorite, nil, OBJC_ASSOCIATION_ASSIGN);

}

NSArray * WADefaultLayoutGrids (void) {

	static NSArray *grids = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		 
		grids = WADefaultLayoutGridsMake();
				
	});

	return grids;

}

NSArray * WADefaultLayoutGridsMake (void) {

	CGSize portraitSize = (CGSize){ 768, 1024 };
	CGSize landscapeSize = (CGSize){ 1024, 768 };
	
	IRDiscreteLayoutAreaValidatorBlock notFave = ^ (IRDiscreteLayoutArea *self, id anItem) {
	
		return (BOOL)!WADiscreteLayoutItemIsFavorite(anItem);
	
	};
	
	IRDiscreteLayoutAreaValidatorBlock fave = ^ (IRDiscreteLayoutArea *self, id anItem) {
	
		return (BOOL)WADiscreteLayoutItemIsFavorite(anItem);
	
	};
	
	IRDiscreteLayoutAreaValidatorBlock combo = ^ (IRDiscreteLayoutArea *self, id anItem) {
	
		if (WADiscreteLayoutItemIsFavorite(anItem))
			return NO;
	
		return (BOOL)((WADiscreteLayoutItemHasLink(anItem) && WADiscreteLayoutItemHasLongText(anItem) && WADiscreteLayoutItemHasImage(anItem)) || WADiscreteLayoutItemHasImage(anItem));
	
	};
	
	IRDiscreteLayoutAreaLayoutBlock (^layoutBlock)(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat) = ^ (CGFloat xUnits, CGFloat yUnits, CGFloat xOffset, CGFloat yOffset, CGFloat xSpan, CGFloat ySpan) {
	
		IRDiscreteLayoutAreaLayoutBlock prototype = IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(xUnits, yUnits, xOffset, yOffset, xSpan, ySpan);
		
		return (IRDiscreteLayoutAreaLayoutBlock)[^ (IRDiscreteLayoutArea *area, id<IRDiscreteLayoutItem>item) {
		
			CGRect answer = prototype(area, item);
			return CGRectInset(answer, 8, 8);
		
		} copy];
	
	};
	
	WADiscreteLayoutArea * (^area)(NSString *, IRDiscreteLayoutAreaValidatorBlock, IRDiscreteLayoutAreaLayoutBlock, WALayoutAreaTemplateNameBlock) = ^ (NSString *identifier, IRDiscreteLayoutAreaValidatorBlock validatorBlock, IRDiscreteLayoutAreaLayoutBlock layoutBlock, WALayoutAreaTemplateNameBlock templateNameBlock) {
	
		WADiscreteLayoutArea *area = [[WADiscreteLayoutArea alloc] init];
		area.identifier = identifier;
		area.validatorBlock = validatorBlock;
		area.layoutBlock = layoutBlock;
		area.templateNameBlock = templateNameBlock;
		return area;
	
	};
	
	WALayoutAreaTemplateNameBlock (^templateName)(NSString *, NSString *, NSString *) = ^ (NSString *text, NSString *previewOnly, NSString *previewWithText) {
	
		return (WALayoutAreaTemplateNameBlock)[^ (IRDiscreteLayoutArea *area) {
		
			WAArticle *article = (WAArticle *)area.item;
			
			if (![article.previews count])
				return text;
			
			if ([article.text length])
				return previewWithText;
			
			return previewOnly;
		
		} copy];
	
	};
	
	IRDiscreteLayoutGrid * (^pair)(IRDiscreteLayoutGrid *, IRDiscreteLayoutGrid *) = ^ (IRDiscreteLayoutGrid *lhsGrid, IRDiscreteLayoutGrid *rhsGrid) {
	
		NSCParameterAssert([lhsGrid class] == [rhsGrid class]);
		Class class = [lhsGrid class];
		
		for (IRDiscreteLayoutArea *area in lhsGrid.layoutAreas) {
			
			NSString *name = area.identifier;
			[class markAreaNamed:name inGridPrototype:lhsGrid asEquivalentToAreaNamed:name inGridPrototype:rhsGrid];
			
		}
		
		return lhsGrid;
	
	};
	
	WALayoutAreaTemplateNameBlock singleYStack = templateName(
		@"WFPreviewTemplate_Discrete_Plaintext",
		@"WFPreviewTemplate_Discrete_Web_Image",
		@"WFPreviewTemplate-Discrete_Web_ImageWithDescription_Horizontal");
	
	WALayoutAreaTemplateNameBlock H5 = templateName(
		@"WFPreviewTemplate_Discrete_Plaintext",
		@"WFPreviewTemplate_Discrete_Web_Image",
		@"WFPreviewTemplate-Discrete_Web_ImageWithDescription_Horizontal_for_6");
	
	WALayoutAreaTemplateNameBlock singleXStack = templateName(
		@"WFPreviewTemplate_Discrete_Plaintext",
		@"WFPreviewTemplate_Discrete_Web_Image",
		@"WFPreviewTemplate-Discrete_Web_ImageWithDescription_Vertical");
		
	WALayoutAreaTemplateNameBlock annotationTop_verticalFave = templateName(
		@"WFPreviewTemplate_Discrete_Plaintext",
		@"WFPreviewTemplate-Discrete_Web_Image_Vertical",
		@"WFPreviewTemplate-Discrete_Web_ImageWithDescription_Vertical_Fave");
		
	WALayoutAreaTemplateNameBlock annotationTop_horizontalFave = templateName(
		@"WFPreviewTemplate_Discrete_Plaintext",
		@"WFPreviewTemplate-Discrete_Web_ImageWithDescription_Horizontal_Fave",
		@"WFPreviewTemplate-Discrete_Web_ImageWithDescription_AnnotationTop");
		
	return [NSArray arrayWithObjects:
	
		pair(
		
			[[IRDiscreteLayoutGrid alloc] initWithIdentifier:@"6_any_portrait" contentSize:portraitSize layoutAreas:[NSArray arrayWithObjects:
				area(@"A", nil, layoutBlock(2, 3, 0, 0, 1, 1), H5),
				area(@"B", nil, layoutBlock(2, 3, 1, 0, 1, 1), H5),
				area(@"C", nil, layoutBlock(2, 3, 0, 1, 1, 1), H5),
				area(@"D", nil, layoutBlock(2, 3, 1, 1, 1, 1), H5),
				area(@"E", nil, layoutBlock(2, 3, 0, 2, 1, 1), H5),
				area(@"F", nil, layoutBlock(2, 3, 1, 2, 1, 1), H5),
			nil]],
			
			[[IRDiscreteLayoutGrid alloc] initWithIdentifier:@"6_any_landscape" contentSize:landscapeSize layoutAreas:[NSArray arrayWithObjects:
				area(@"A", nil, layoutBlock(3, 2, 0, 0, 1, 1), singleXStack),
				area(@"B", nil, layoutBlock(3, 2, 2, 0, 1, 1), singleXStack),
				area(@"C", nil, layoutBlock(3, 2, 1, 0, 1, 1), singleXStack),
				area(@"D", nil, layoutBlock(3, 2, 1, 1, 1, 1), singleXStack),
				area(@"E", nil, layoutBlock(3, 2, 0, 1, 1, 1), singleXStack),
				area(@"F", nil, layoutBlock(3, 2, 2, 1, 1, 1), singleXStack),
			nil]]
			
		),
		
		pair(
		
			[[IRDiscreteLayoutGrid alloc] initWithIdentifier:@"5_non_faves_A_portrait" contentSize:portraitSize layoutAreas:[NSArray arrayWithObjects:
				area(@"A", notFave, layoutBlock(2, 3, 0, 0, 1, 1), H5),
				area(@"B", notFave, layoutBlock(2, 3, 0, 1, 1, 1), H5),
				area(@"C", notFave, layoutBlock(2, 3, 0, 2, 1, 1), H5),
				area(@"D", combo,   layoutBlock(2, 3, 1, 0, 1, 2), singleYStack),
				area(@"E", notFave, layoutBlock(2, 3, 1, 2, 1, 1), H5),
			nil]],
			
			[[IRDiscreteLayoutGrid alloc] initWithIdentifier:@"5_non_faves_A_landscape" contentSize:landscapeSize layoutAreas:[NSArray arrayWithObjects:
				area(@"A", notFave, layoutBlock(3, 2, 0, 0, 1, 1), singleXStack),
				area(@"B", notFave, layoutBlock(3, 2, 0, 1, 1, 1), singleXStack),
				area(@"C", notFave, layoutBlock(3, 2, 1, 1, 1, 1), singleXStack),
				area(@"D", combo,		layoutBlock(3, 2, 1, 0, 2, 1), singleXStack),
				area(@"E", notFave, layoutBlock(3, 2, 2, 1, 1, 1), singleXStack),
			nil]]
			
		),
		
		pair(
		
			[[IRDiscreteLayoutGrid alloc] initWithIdentifier:@"5_non_faves_B_portrait" contentSize:portraitSize layoutAreas:[NSArray arrayWithObjects:
				area(@"A", combo,   layoutBlock(2, 3, 0, 0, 1, 2), singleYStack),
				area(@"B", notFave, layoutBlock(2, 3, 0, 2, 1, 1), H5),
				area(@"C", notFave, layoutBlock(2, 3, 1, 0, 1, 1), H5),
				area(@"D", notFave, layoutBlock(2, 3, 1, 1, 1, 1), H5),
				area(@"E", notFave, layoutBlock(2, 3, 1, 2, 1, 1), H5),
			nil]],
			
			[[IRDiscreteLayoutGrid alloc] initWithIdentifier:@"5_non_faves_B_landscape" contentSize:landscapeSize layoutAreas:[NSArray arrayWithObjects:
				area(@"A", combo,   layoutBlock(3, 2, 0, 0, 2, 1), singleXStack),
				area(@"B", notFave, layoutBlock(3, 2, 0, 1, 1, 1), singleXStack),
				area(@"C", notFave, layoutBlock(3, 2, 2, 0, 1, 1), singleXStack),
				area(@"D", notFave, layoutBlock(3, 2, 1, 1, 1, 1), singleXStack),
				area(@"E", notFave, layoutBlock(3, 2, 2, 1, 1, 1), singleXStack),
			nil]]
			
		),
		
		pair(
		
			[[IRDiscreteLayoutGrid alloc] initWithIdentifier:@"4_non_faves_A_portrait" contentSize:portraitSize layoutAreas:[NSArray arrayWithObjects:
				area(@"A", combo,   layoutBlock(2, 3, 0, 0, 1, 2), singleYStack),
				area(@"B", notFave, layoutBlock(2, 3, 0, 2, 1, 1), H5),
				area(@"C", notFave, layoutBlock(2, 3, 1, 0, 1, 1), H5),
				area(@"D", combo,   layoutBlock(2, 3, 1, 1, 1, 2), singleYStack),
			nil]],
			
			[[IRDiscreteLayoutGrid alloc] initWithIdentifier:@"4_non_faves_A_landscape" contentSize:landscapeSize layoutAreas:[NSArray arrayWithObjects:
				area(@"A", combo,   layoutBlock(3, 2, 0, 0, 2, 1), H5),
				area(@"B", notFave, layoutBlock(3, 2, 0, 1, 1, 1), singleXStack),
				area(@"C", notFave, layoutBlock(3, 2, 2, 0, 1, 1), singleXStack),
				area(@"D", combo,   layoutBlock(3, 2, 1, 1, 2, 1), H5),
			nil]]
			
		),
		
		pair(
		
			[[IRDiscreteLayoutGrid alloc] initWithIdentifier:@"4_non_faves_B_portrait" contentSize:portraitSize layoutAreas:[NSArray arrayWithObjects:
				area(@"A", notFave, layoutBlock(2, 3, 0, 0, 1, 1), H5),
				area(@"B", combo,   layoutBlock(2, 3, 0, 1, 1, 2), singleYStack),
				area(@"C", combo,   layoutBlock(2, 3, 1, 0, 1, 2), singleYStack),
				area(@"D", notFave, layoutBlock(2, 3, 1, 2, 1, 1), H5),
			nil]],
			
			[[IRDiscreteLayoutGrid alloc] initWithIdentifier:@"4_non_faves_B_landscape" contentSize:landscapeSize layoutAreas:[NSArray arrayWithObjects:
				area(@"A", notFave, layoutBlock(3, 2, 0, 0, 1, 1), H5),
				area(@"B", combo,   layoutBlock(3, 2, 0, 1, 2, 1), singleXStack),
				area(@"C", combo,   layoutBlock(3, 2, 1, 0, 2, 1), singleXStack),
				area(@"D", notFave, layoutBlock(3, 2, 2, 1, 1, 1), H5),
			nil]]
			
		),
		
		pair(
		
			[[IRDiscreteLayoutGrid alloc] initWithIdentifier:@"1_fave_with_4_non_faves_portrait" contentSize:portraitSize layoutAreas:[NSArray arrayWithObjects:
				area(@"A", fave,    layoutBlock(2, 4, 0, 0, 2, 2), annotationTop_horizontalFave),
				area(@"B", notFave, layoutBlock(2, 4, 0, 2, 1, 1), singleYStack),
				area(@"C", notFave, layoutBlock(2, 4, 1, 2, 1, 1), singleYStack),
				area(@"D", notFave, layoutBlock(2, 4, 0, 3, 1, 1), singleYStack),
				area(@"E", notFave, layoutBlock(2, 4, 1, 3, 1, 1), singleYStack),
			nil]],
			
			[[IRDiscreteLayoutGrid alloc] initWithIdentifier:@"1_fave_with_4_non_faves_landscape" contentSize:landscapeSize layoutAreas:[NSArray arrayWithObjects:
				area(@"A", fave,    layoutBlock(4, 2, 0, 0, 2, 2), annotationTop_verticalFave),
				area(@"B", notFave, layoutBlock(4, 2, 2, 0, 1, 1), singleXStack),
				area(@"C", notFave, layoutBlock(4, 2, 2, 1, 1, 1), singleXStack),
				area(@"D", notFave, layoutBlock(4, 2, 3, 0, 1, 1), singleXStack),
				area(@"E", notFave, layoutBlock(4, 2, 3, 1, 1, 1), singleXStack),
			nil]]
			
		),
		
		pair(
		
			[[IRDiscreteLayoutGrid alloc] initWithIdentifier:@"1_fave_with_3_non_faves_A_portrait" contentSize:portraitSize layoutAreas:[NSArray arrayWithObjects:
				area(@"A", fave,    layoutBlock(2, 4, 0, 0, 2, 2), annotationTop_horizontalFave),
				area(@"B", notFave, layoutBlock(2, 4, 0, 2, 1, 1), singleYStack),
				area(@"C", notFave, layoutBlock(2, 4, 0, 3, 1, 1), singleYStack),
				area(@"D", combo,   layoutBlock(2, 4, 1, 2, 1, 2), singleYStack),
			nil]],
			
			[[IRDiscreteLayoutGrid alloc] initWithIdentifier:@"1_fave_with_3_non_faves_A_landscape" contentSize:landscapeSize layoutAreas:[NSArray arrayWithObjects:
				area(@"A", fave,    layoutBlock(4, 2, 0, 0, 2, 2), annotationTop_verticalFave),
				area(@"B", notFave, layoutBlock(4, 2, 2, 0, 1, 1), singleXStack),
				area(@"C", notFave, layoutBlock(4, 2, 3, 0, 1, 1), singleXStack),
				area(@"D", combo,   layoutBlock(4, 2, 2, 1, 2, 1), singleXStack),
			nil]]
			
		),
		
		pair(
		
			[[IRDiscreteLayoutGrid alloc] initWithIdentifier:@"1_fave_with_3_non_faves_B_portrait" contentSize:portraitSize layoutAreas:[NSArray arrayWithObjects:
				area(@"A", fave,    layoutBlock(2, 4, 0, 0, 2, 2), annotationTop_horizontalFave),
				area(@"B", combo,   layoutBlock(2, 4, 0, 2, 1, 2), singleYStack),
				area(@"C", notFave, layoutBlock(2, 4, 1, 2, 1, 1), singleYStack),
				area(@"D", notFave, layoutBlock(2, 4, 1, 3, 1, 1), singleYStack),
			nil]],
			
			[[IRDiscreteLayoutGrid alloc] initWithIdentifier:@"1_fave_with_3_non_faves_B_landscape" contentSize:landscapeSize layoutAreas:[NSArray arrayWithObjects:
				area(@"A", fave,   layoutBlock(4, 2, 0, 0, 2, 2), annotationTop_verticalFave),
				area(@"B", combo,   layoutBlock(4, 2, 2, 0, 2, 1), singleXStack),
				area(@"C", notFave, layoutBlock(4, 2, 2, 1, 1, 1), singleXStack),
				area(@"D", notFave, layoutBlock(4, 2, 3, 1, 1, 1), singleXStack),
			nil]]
			
		),
		
		pair(
		
			[[IRDiscreteLayoutGrid alloc] initWithIdentifier:@"2_faves_portrait" contentSize:portraitSize layoutAreas:[NSArray arrayWithObjects:
				area(@"A", fave, layoutBlock(1, 2, 0, 0, 1, 1), annotationTop_horizontalFave),
				area(@"B", fave, layoutBlock(1, 2, 0, 1, 1, 1), annotationTop_horizontalFave),
			nil]],
			
			[[IRDiscreteLayoutGrid alloc] initWithIdentifier:@"2_faves_landscape" contentSize:landscapeSize layoutAreas:[NSArray arrayWithObjects:
				area(@"A", fave, layoutBlock(2, 1, 0, 0, 1, 1), annotationTop_verticalFave),
				area(@"B", fave, layoutBlock(2, 1, 1, 0, 1, 1), annotationTop_verticalFave),
			nil]]
			
		),
		
	nil];

}
