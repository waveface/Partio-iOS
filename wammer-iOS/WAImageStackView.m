//
//  WAImageStackView.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/28/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WAImageStackView.h"
#import "WADataStore.h"

#import "CGGeometry+IRAdditions.h"


@interface WAImageStackView ()

- (void) waInit;
@property (nonatomic, readwrite, retain) NSArray *shownImageFilePaths;

@end


@implementation WAImageStackView

@synthesize files, shownImageFilePaths;

- (id) initWithCoder:(NSCoder *)aDecoder {

	self = [super initWithCoder:aDecoder];
	
	if (!self)
		return nil;
		
	[self waInit];
	
	return self;

}

- (id) initWithFrame:(CGRect)frame {

	self = [super initWithFrame:frame];
	
	if (!self)
		return nil;
	
	[self waInit];
	
	return self;

}

- (void) waInit {

	[self addObserver:self forKeyPath:@"files" options:NSKeyValueObservingOptionNew context:nil];

}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	if (object == self)
	if ([keyPath isEqualToString:@"files"]) {
	
	 
	
		self.shownImageFilePaths = [[[[self.files objectsPassingTest: ^ (WAFile *aFile, BOOL *stop) {
			
			return (BOOL)UTTypeConformsTo((CFStringRef)aFile.resourceType, kUTTypeImage);
			
		}] allObjects] sortedArrayUsingComparator:^NSComparisonResult(WAFile *lhsFile, WAFile *rhsFile) {
		
			return [lhsFile.timestamp compare:rhsFile.timestamp];
			
		}] irMap: ^ (WAFile *aFile, int index, BOOL *stop) {
		
			if (index >= 2) {
					*stop = YES;
					return (id)nil;
			}
			
			if (aFile.resourceFilePath)
				return aFile.resourceFilePath;
				
			NSString *resourceName = [NSString stringWithFormat:@"IPSample_%03i", (1 + (rand() % 48))];
			return [[[NSBundle mainBundle] URLForResource:resourceName withExtension:@"jpg" subdirectory:@"IPSample"] path];
			
			
		}];
		
	}

}

- (void) layoutSubviews {

	static int kPhotoViewTag = 1024;
	
	NSMutableSet *removedPhotoViews = [NSMutableSet setWithArray:[self.subviews objectsAtIndexes:[self.subviews indexesOfObjectsPassingTest: ^ (UIView *aSubview, NSUInteger idx, BOOL *stop) {
		return (BOOL)(aSubview.tag == kPhotoViewTag);
	}]]];
	
	
	static NSString *kImagePath = @"WAImageStackView_Subview_ImagePath";
	void (^setImagePath)(id object, NSString *path) = ^ (id object, NSString *path) {
		objc_setAssociatedObject(object, kImagePath, path, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	};
	NSString * (^getImagePath)(id object) = ^ (id object) {
		return (NSString *)objc_getAssociatedObject(object, kImagePath);
	};
	

	for (NSString *aPath in self.shownImageFilePaths) {
		
		if (![[removedPhotoViews objectsPassingTest: ^ (UIView *aSubview, BOOL *stop) {
			
			return [getImagePath(aSubview) isEqual:aPath];
			
		}] count]) {
			
			UIView *imageView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
			UIImageView *innerImageView = [[[UIImageView alloc] initWithFrame:imageView.bounds] autorelease];
			
			innerImageView.image = [UIImage imageWithContentsOfFile:aPath];
			innerImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
			innerImageView.layer.masksToBounds = YES;
			[imageView addSubview:innerImageView];
			
			imageView.tag = kPhotoViewTag;
			imageView.layer.borderColor = [UIColor whiteColor].CGColor;
			imageView.layer.borderWidth = 4.0f;
			imageView.layer.shadowOffset = (CGSize){ 0, 2 };
			imageView.layer.shadowRadius = 2.0f;
			imageView.layer.shadowOpacity = 0.25f;
			imageView.layer.edgeAntialiasingMask = kCALayerLeftEdge|kCALayerRightEdge|kCALayerTopEdge|kCALayerBottomEdge;
			imageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
			imageView.layer.shouldRasterize = YES;
			imageView.opaque = NO;
			
			setImagePath(imageView, aPath);
			[removedPhotoViews addObject:imageView];
			
		}
		
	}
	
	
	CGRect photoViewFrame = CGRectNull;
	BOOL hasUsedFirstPhoto = NO;
	
	for (UIView *wrappingImageView in [[removedPhotoViews copy] autorelease]) {
	
		UIImageView *innerImageView = (UIImageView *)[[wrappingImageView subviews] objectAtIndex:0];
		
		if (!hasUsedFirstPhoto) {
		
			photoViewFrame = IRCGSizeGetCenteredInRect(innerImageView.image.size, self.bounds, 8.0f, YES);
			
			wrappingImageView.layer.transform = CATransform3DIdentity;
			innerImageView.contentMode = UIViewContentModeScaleAspectFit;

		} else {
		
			CGFloat baseDelta = 2.0f;	//	at least ± 2°
			CGFloat allowedAdditionalDeltaInDegrees = 0.0f; //	 with this much added variance
			CGFloat rotatedDegrees = baseDelta + ((rand() % 2) ? 1 : -1) * (((1.0f * rand()) / (1.0f * INT_MAX)) * allowedAdditionalDeltaInDegrees);
			
			wrappingImageView.layer.transform = CATransform3DMakeRotation((rotatedDegrees / 360.0f) * 2 * M_PI, 	0.0f, 0.0f, 1.0f);
			innerImageView.contentMode = UIViewContentModeScaleAspectFill;

		}
		
		wrappingImageView.frame = photoViewFrame;
		
		if (!hasUsedFirstPhoto)
			hasUsedFirstPhoto = YES;

		wrappingImageView.layer.shadowPath = [UIBezierPath bezierPathWithRect:wrappingImageView.bounds].CGPath;
	 
		if (wrappingImageView.superview != self) {
			
			[self addSubview:wrappingImageView];
			[self sendSubviewToBack:wrappingImageView];
			
		}
				
		[removedPhotoViews removeObject:wrappingImageView];
		
	}
	
	for (UIView *anImageView in removedPhotoViews)
		[anImageView removeFromSuperview];

}

- (void) dealloc {

	[self removeObserver:self forKeyPath:@"files"];
	[shownImageFilePaths release];
	[super dealloc];

}

@end
