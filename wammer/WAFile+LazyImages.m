//
//  WAFile+LazyImages.m
//  wammer
//
//  Created by Evadne Wu on 5/21/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAFile+LazyImages.h"
#import "WAFile+WAConstants.h"

#import "UIKit+IRAdditions.h"

static NSString * const kMemoryWarningObserver = @"-[WAFile(LazyImages) handleDidReceiveMemoryWarning:]";

@implementation WAFile (LazyImages)

- (void) createMemoryWarningObserverIfAppropriate {

	id observer = objc_getAssociatedObject(self, &kMemoryWarningObserver);
	if (!observer) {
	
		/*
		
			http://www.mikeash.com/pyblog/friday-qa-2011-09-30-automatic-reference-counting.html
			
			NSManagedObject has overridden -retain and -release causing __weak to fail
			rather miserably
		
		*/
		
		__unsafe_unretained WAFile *wSelf = self;
	
		id observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
		
			[wSelf handleDidReceiveMemoryWarning:note];
			
		}];
	
		objc_setAssociatedObject(self, &kMemoryWarningObserver, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	}

}

- (void) removeMemoryWarningObserverIfAppropriate {
	
	id observer = objc_getAssociatedObject(self, &kMemoryWarningObserver);
	
	if (observer) {
		[[NSNotificationCenter defaultCenter] removeObserver:observer];
		objc_setAssociatedObject(self, &kMemoryWarningObserver, nil, OBJC_ASSOCIATION_ASSIGN);
	}

}

- (void) handleDidReceiveMemoryWarning:(NSNotification *)aNotification {

	[self irAssociateObject:nil usingKey:&kWAFileThumbnailImage policy:OBJC_ASSOCIATION_ASSIGN changingObservedKey:nil];
	[self irAssociateObject:nil usingKey:&kWAFileLargeThumbnailImage policy:OBJC_ASSOCIATION_ASSIGN changingObservedKey:nil];
	[self irAssociateObject:nil usingKey:&kWAFileResourceImage policy:OBJC_ASSOCIATION_ASSIGN changingObservedKey:nil];

}

+ (NSSet *) keyPathsForValuesAffectingBestPresentableImage {

	return [NSSet setWithObjects:
		kWAFileSmallThumbnailImage,
		kWAFileThumbnailImage,
		kWAFileLargeThumbnailImage,
		kWAFileResourceImage,
	nil];

}

- (UIImage *) bestPresentableImage {

	if (self.resourceImage)
		return self.resourceImage;
	
	if (self.largeThumbnailImage)
		return self.largeThumbnailImage;
	
	if (self.thumbnailImage)
		return self.thumbnailImage;
	
	if (self.smallThumbnailImage)
		return self.smallThumbnailImage;
	
	return nil;

}

+ (NSSet *) keyPathsForValuesAffectingSmallestPresentableImage {

	return [NSSet setWithObjects:
		kWAFileSmallThumbnailImage,
		kWAFileThumbnailImage,
		kWAFileLargeThumbnailImage,
		kWAFileResourceImage,
	nil];

}

- (UIImage *) smallestPresentableImage {

	if (self.smallThumbnailImage)
		return self.smallThumbnailImage;
	
	if (self.thumbnailImage)
		return self.thumbnailImage;
	
	if (self.largeThumbnailImage)
		return self.largeThumbnailImage;
	
	if (self.resourceImage)
		return self.resourceImage;
	
	return nil;
	
}

+ (NSSet *) keyPathsForValuesAffectingResourceImage {

	return [NSSet setWithObject:kWAFileResourceFilePath];

}

- (UIImage *) resourceImage {

	[self createMemoryWarningObserverIfAppropriate];

	return [self imageAssociatedWithKey:&kWAFileResourceImage filePath:self.resourceFilePath];
	
}

- (void) setResourceImage:(UIImage *)resourceImage {

	[self irAssociateObject:resourceImage usingKey:&kWAFileResourceImage policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC changingObservedKey:kWAFileResourceImage];

}

+ (NSSet *) keyPathsForValuesAffectingLargeThumbnailImage {

	return [NSSet setWithObject:kWAFileLargeThumbnailFilePath];

}

- (UIImage *) largeThumbnailImage {
	
	[self createMemoryWarningObserverIfAppropriate];
	
	return [self imageAssociatedWithKey:&kWAFileLargeThumbnailImage filePath:self.largeThumbnailFilePath];
	
}

- (void) setLargeThumbnailImage:(UIImage *)largeThumbnailImage {

	[self irAssociateObject:largeThumbnailImage usingKey:&kWAFileLargeThumbnailImage policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC changingObservedKey:kWAFileLargeThumbnailImage];

}

+ (NSSet *) keyPathsForValuesAffectingThumbnailImage {

	return [NSSet setWithObject:kWAFileThumbnailFilePath];

}

- (UIImage *) thumbnailImage {

	[self createMemoryWarningObserverIfAppropriate];
	
	return [self imageAssociatedWithKey:&kWAFileThumbnailImage filePath:self.thumbnailFilePath];
		
}

- (void) setThumbnailImage:(UIImage *)thumbnailImage {

	[self irAssociateObject:thumbnailImage usingKey:&kWAFileThumbnailImage policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC changingObservedKey:kWAFileThumbnailImage];

}

+ (NSSet *) keyPathsForValuesAffectingSmallThumbnailImage {

	return [NSSet setWithObject:kWAFileSmallThumbnailFilePath];

}

- (UIImage *) smallThumbnailImage {

	[self createMemoryWarningObserverIfAppropriate];
	
	return [self imageAssociatedWithKey:&kWAFileSmallThumbnailImage filePath:self.smallThumbnailFilePath];
		
}

- (void) setSmallThumbnailImage:(UIImage *)smallThumbnailImage {

	[self irAssociateObject:smallThumbnailImage usingKey:&kWAFileSmallThumbnailImage policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC changingObservedKey:kWAFileSmallThumbnailImage];

}

- (UIImage *) imageAssociatedWithKey:(const void *)key filePath:(NSString *)filePath {

	if (!filePath)
		return nil;
	
	UIImage *image = objc_getAssociatedObject(self, key);
	if (image)
		return image;
	
	image = [UIImage imageWithData:[NSData dataWithContentsOfMappedFile:filePath]];
	image.irRepresentedObject = [NSValue valueWithNonretainedObject:self];
	
	[self irAssociateObject:image usingKey:key policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC changingObservedKey:nil];
	
	return image;

}

- (UIImage *) thumbnail {

	UIImage *primitiveThumbnail = [self primitiveValueForKey:@"thumbnail"];
	
	if (primitiveThumbnail)
		return primitiveThumbnail;
	
	if (!self.resourceImage)
		return nil;
	
	primitiveThumbnail = [[self.resourceImage irStandardImage] irScaledImageWithSize:IRCGSizeGetCenteredInRect(self.resourceImage.size, (CGRect){ CGPointZero, (CGSize){ 512, 512 } }, 0.0f, YES).size];
	[self setPrimitiveValue:primitiveThumbnail forKey:@"thumbnail"];
	
	return self.thumbnail;

}

@end
