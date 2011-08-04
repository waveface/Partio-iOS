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
#import "QuartzCore+IRAdditions.h"





static NSString *kWAImageStackViewElementCanonicalTransform;


@interface WAImageStackView () <UIGestureRecognizerDelegate>

- (void) waInit;
@property (nonatomic, readwrite, retain) NSArray *shownImageFilePaths;
@property (nonatomic, readwrite, retain) UIPinchGestureRecognizer *pinchRecognizer;
@property (nonatomic, readwrite, retain) UIRotationGestureRecognizer *rotationRecognizer;

@property (nonatomic, readwrite, assign) UIView *firstPhotoView;

@end


@implementation WAImageStackView

@synthesize files, delegate, shownImageFilePaths;
@synthesize pinchRecognizer, rotationRecognizer, firstPhotoView;

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
	
	self.pinchRecognizer = [[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)] autorelease];
	self.pinchRecognizer.delegate = self;
	[self addGestureRecognizer:self.pinchRecognizer];
	
	self.rotationRecognizer = [[[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)] autorelease];
	self.rotationRecognizer.delegate = self;
	[self addGestureRecognizer:self.rotationRecognizer];
	
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {

	if (gestureRecognizer == self.pinchRecognizer)
		return (otherGestureRecognizer == self.rotationRecognizer);
	
	if (gestureRecognizer == self.rotationRecognizer)
		return (otherGestureRecognizer == self.pinchRecognizer);

	return NO;

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


- (void) setShownImageFilePaths:(NSArray *)newShownImageFilePaths {

	if (newShownImageFilePaths == shownImageFilePaths)
		return;
	
	[self willChangeValueForKey:@"shownImageFilePaths"];
	[shownImageFilePaths release];
	shownImageFilePaths = [newShownImageFilePaths retain];
	[self didChangeValueForKey:@"shownImageFilePaths"];
	
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
			
			self.firstPhotoView = wrappingImageView;

		} else {
		
			CGFloat baseDelta = 2.0f;	//	at least ± 2°
			CGFloat allowedAdditionalDeltaInDegrees = 0.0f; //	 with this much added variance
			CGFloat rotatedDegrees = baseDelta + ((rand() % 2) ? 1 : -1) * (((1.0f * rand()) / (1.0f * INT_MAX)) * allowedAdditionalDeltaInDegrees);
			
			wrappingImageView.layer.transform = CATransform3DMakeRotation((rotatedDegrees / 360.0f) * 2 * M_PI, 	0.0f, 0.0f, 1.0f);
			innerImageView.contentMode = UIViewContentModeScaleAspectFill;

		}
		
		objc_setAssociatedObject(wrappingImageView.layer, kWAImageStackViewElementCanonicalTransform, [NSValue valueWithCATransform3D:wrappingImageView.layer.transform], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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

- (void) handlePinch:(UIPinchGestureRecognizer *)aPinchRecognizer {

	NSValue *canonicalTransformValue = objc_getAssociatedObject(self.firstPhotoView.layer, kWAImageStackViewElementCanonicalTransform);
	CATransform3D canonicalTransform = canonicalTransformValue ? [canonicalTransformValue CATransform3DValue] : CATransform3DIdentity;
	
	switch (aPinchRecognizer.state) {
	
		case UIGestureRecognizerStatePossible:
		case UIGestureRecognizerStateBegan: {
		
			break;
		
		}
		
		case UIGestureRecognizerStateChanged: {
		
			IRCATransact(^ {
				self.firstPhotoView.layer.transform = CATransform3DConcat(
					CATransform3DConcat(
						canonicalTransform,
						CATransform3DMakeScale(self.pinchRecognizer.scale, self.pinchRecognizer.scale, 1.0f)
					),
					CATransform3DMakeRotation(self.rotationRecognizer.rotation, 0.0f, 0.0f, 1.0f)
				);
			});
		
			break;
		
		}
		
		case UIGestureRecognizerStateEnded:
		case UIGestureRecognizerStateCancelled:
		case UIGestureRecognizerStateFailed: {
		
			CATransform3D oldTransform = ((CALayer *)[self.firstPhotoView.layer presentationLayer]).transform;
			CATransform3D newTransform = canonicalTransform;
			
			CABasicAnimation *transformAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
			transformAnimation.fromValue = [NSValue valueWithCATransform3D:oldTransform];
			transformAnimation.toValue = [NSValue valueWithCATransform3D:newTransform];
			transformAnimation.removedOnCompletion = YES;
			transformAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			transformAnimation.duration = 0.3f;
		
			self.firstPhotoView.layer.transform = newTransform;
			[self.firstPhotoView.layer addAnimation:transformAnimation forKey:@"transition"];
			
			break;
		
		}
	
	}

}

- (void) handleRotation:(UIRotationGestureRecognizer *)aRotationRecognizer {

	//	We let this be an empty no-op and have the pinch recognizer do all the work instead.

}

- (void) dealloc {

	[self removeObserver:self forKeyPath:@"files"];
	[shownImageFilePaths release];
	[pinchRecognizer release];
	[rotationRecognizer release];
	[super dealloc];

}

@end
