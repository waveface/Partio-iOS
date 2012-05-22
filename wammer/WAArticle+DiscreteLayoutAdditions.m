//
//  WAArticle+DiscreteLayoutAdditions.m
//  wammer
//
//  Created by Evadne Wu on 9/22/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAArticle+DiscreteLayoutAdditions.h"
#import "WADataStore.h"

NSString * const WAArticle_DiscreteLayoutAdditions_ItemType = @"WAArticle_DiscreteLayoutAdditions_ItemType";

@implementation WAArticle (DiscreteLayoutAdditions)

- (NSString *) title {
	
	return self.title;
	
}

- (NSArray *) representedMediaItems {

	NSMutableArray *returnedArray = [NSMutableArray array];

	for (WAFile *aFile in self.files) {
		objc_setAssociatedObject(aFile, &WAArticle_DiscreteLayoutAdditions_ItemType, (id)kUTTypeImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		[returnedArray addObject:aFile];
	};
	
	for (WAPreview *aPreview in self.previews) {
		objc_setAssociatedObject(aPreview, &WAArticle_DiscreteLayoutAdditions_ItemType, (id)kUTTypeURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		[returnedArray addObject:aPreview];
	};
	
	return returnedArray;
	
}

- (CFStringRef) typeForRepresentedMediaItem:(id)anItem {
	
	CFStringRef returnedType = (__bridge CFStringRef)objc_getAssociatedObject(anItem, &WAArticle_DiscreteLayoutAdditions_ItemType);
	
	if (!returnedType)
		returnedType = kUTTypeItem;
	
	return returnedType;
	
}

- (NSString *) representedText {

	NSString *previewDescription = ((WAPreview *)[self.previews anyObject]).graphElement.text;

	if (previewDescription)
		return [[self text] stringByAppendingString:previewDescription];
	
	return [self text];
	
}

- (NSURL *) representedImageURI {
	
	return IRDiscreteLayoutItemContentMediaForUTIType(self, kUTTypeImage);
	
}

- (NSURL *) representedVideoURI {
	
	return IRDiscreteLayoutItemContentMediaForUTIType(self, kUTTypeVideo);
	
}

@end
