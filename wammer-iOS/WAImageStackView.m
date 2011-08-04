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





static const NSString *kWAImageStackViewElementCanonicalTransform = @"kWAImageStackViewElementCanonicalTransform";
static const NSString *kWAImageStackViewElementImagePath = @"kWAImageStackViewElementImagePath";


@interface WAImageStackView () <UIGestureRecognizerDelegate>

- (void) waInit;
@property (nonatomic, readwrite, retain) NSArray *shownImageFilePaths;
@property (nonatomic, readwrite, retain) UIPinchGestureRecognizer *pinchRecognizer;
@property (nonatomic, readwrite, retain) UIRotationGestureRecognizer *rotationRecognizer;
@property (nonatomic, readwrite, assign) UIView *firstPhotoView;
@property (nonatomic, readwrite, assign) BOOL gestureProcessingOngoing;

@end


@implementation WAImageStackView

@synthesize state;
@synthesize files, delegate, shownImageFilePaths;
@synthesize pinchRecognizer, rotationRecognizer, firstPhotoView;
@synthesize gestureProcessingOngoing;

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

	self.gestureProcessingOngoing = NO;
	self.state = WAImageStackViewInteractionNormal;

	[self addObserver:self forKeyPath:@"files" options:NSKeyValueObservingOptionNew context:nil];
	
	self.pinchRecognizer = [[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)] autorelease];
	self.pinchRecognizer.delegate = self;
	[self addGestureRecognizer:self.pinchRecognizer];
	
	self.rotationRecognizer = [[[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)] autorelease];
	self.rotationRecognizer.delegate = self;
	[self addGestureRecognizer:self.rotationRecognizer];
	
}

- (void) setState:(WAImageStackViewInteractionState)newState {

	if (state == newState)
		return;
	
 	[self willChangeValueForKey:@"state"];
	state = newState;
	[self didChangeValueForKey:@"state"];

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
		
			if (!aFile.resourceFilePath)
				return NO;
			
			if (!UTTypeConformsTo((CFStringRef)aFile.resourceType, kUTTypeImage))
				return NO;
			
			return YES;
			
		}] allObjects] sortedArrayUsingComparator: ^ NSComparisonResult(WAFile *lhsFile, WAFile *rhsFile) {
		
			NSComparisonResult resourceURLResult = [lhsFile.resourceURL compare:rhsFile.resourceURL];
			if (resourceURLResult != NSOrderedSame)
				return resourceURLResult;
			
			//	The timestamp is toxic
			return [lhsFile.timestamp compare:rhsFile.timestamp];
			
		}] irMap: ^ (WAFile *aFile, int index, BOOL *stop) {
		
			return aFile.resourceFilePath;
			
		}];
		
		//	Get the first two photographs if possible.
		self.shownImageFilePaths = [self.shownImageFilePaths objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:(NSRange){ 0, MIN(2, [self.shownImageFilePaths count]) }]];
	
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
	
	[[self.subviews objectsAtIndexes:[self.subviews indexesOfObjectsPassingTest: ^ (UIView *aSubview, NSUInteger idx, BOOL *stop) {
		
		return (BOOL)(aSubview.tag == kPhotoViewTag);
			
	}]] enumerateObjectsUsingBlock:^(UIView *aSubview, NSUInteger idx, BOOL *stop) {
	
		[aSubview removeFromSuperview];
		
	}];
	
	[shownImageFilePaths enumerateObjectsUsingBlock: ^ (NSString *aFilePath, NSUInteger idx, BOOL *stop) {
	
		UIView *imageView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
		objc_setAssociatedObject(imageView, kWAImageStackViewElementImagePath, aFilePath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
		
		UIImageView *innerImageView = [[[UIImageView alloc] initWithFrame:imageView.bounds] autorelease];
		innerImageView.image = [UIImage imageWithContentsOfFile:aFilePath];
		innerImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		innerImageView.layer.masksToBounds = YES;
		
		[imageView addSubview:innerImageView];
				
		[self insertSubview:imageView atIndex:0];		
		
	}];
	
}
	
- (void) layoutSubviews {

	if (self.gestureProcessingOngoing)
		return;
	
	static int kPhotoViewTag = 1024;
	__block CGRect photoViewFrame = CGRectNull;
	
	NSArray *allPhotoViews = [self.subviews objectsAtIndexes:[self.subviews indexesOfObjectsPassingTest: ^ (UIView *aSubview, NSUInteger idx, BOOL *stop) {
		
		return (BOOL)(aSubview.tag == kPhotoViewTag);
			
	}]];
	
	[allPhotoViews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock: ^ (UIView *imageView, NSUInteger idx, BOOL *stop) {
	
		UIImageView *innerImageView = (UIImageView *)[imageView.subviews objectAtIndex:0];
		
		if (idx == ([allPhotoViews count] - 1)) {
		
			photoViewFrame = CGRectIntegral(IRCGSizeGetCenteredInRect(innerImageView.image.size, self.bounds, 8.0f, YES));
			imageView.layer.transform = CATransform3DIdentity;
			innerImageView.contentMode = UIViewContentModeScaleAspectFit;
			
			self.firstPhotoView = imageView;

		} else {
		
			CGFloat baseDelta = 2.0f;	//	at least ± 2°
			CGFloat allowedAdditionalDeltaInDegrees = 0.0f; //	 with this much added variance
			CGFloat rotatedDegrees = baseDelta + ((rand() % 2) ? 1 : -1) * (((1.0f * rand()) / (1.0f * INT_MAX)) * allowedAdditionalDeltaInDegrees);
			
			imageView.layer.transform = CATransform3DMakeRotation((rotatedDegrees / 360.0f) * 2 * M_PI, 0.0f, 0.0f, 1.0f);
			innerImageView.contentMode = UIViewContentModeScaleAspectFill;

		}
		
		imageView.frame = photoViewFrame;
		imageView.layer.shadowPath = [UIBezierPath bezierPathWithRect:imageView.bounds].CGPath;
		objc_setAssociatedObject(imageView.layer, kWAImageStackViewElementCanonicalTransform, [NSValue valueWithCATransform3D:imageView.layer.transform], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		
	}];

}

- (void) handlePinch:(UIPinchGestureRecognizer *)aPinchRecognizer {

	NSValue *canonicalTransformValue = objc_getAssociatedObject(self.firstPhotoView.layer, kWAImageStackViewElementCanonicalTransform);
	CATransform3D canonicalTransform = canonicalTransformValue ? [canonicalTransformValue CATransform3DValue] : CATransform3DIdentity;
	
	switch (aPinchRecognizer.state) {
	
		case UIGestureRecognizerStatePossible:
		case UIGestureRecognizerStateBegan: {
		
			self.state = WAImageStackViewInteractionNormal;
			self.gestureProcessingOngoing = YES;
		
			break;
		
		}
		
		case UIGestureRecognizerStateChanged: {
		
			self.state = (self.pinchRecognizer.scale > 1.2f) ? WAImageStackViewInteractionZoomInPossible : WAImageStackViewInteractionNormal;
		
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
		
			self.state = (self.pinchRecognizer.scale > 1.2f) ? WAImageStackViewInteractionZoomInPossible : WAImageStackViewInteractionNormal;
			
			if (self.state == WAImageStackViewInteractionZoomInPossible)
				[self.delegate imageStackView:self didRecognizePinchZoomGestureWithRepresentedImage:[UIImage imageWithContentsOfFile:(NSString *)objc_getAssociatedObject(self.firstPhotoView, kWAImageStackViewElementImagePath)] contentRect:self.firstPhotoView.frame transform:self.firstPhotoView.layer.transform];
		
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
			
			self.gestureProcessingOngoing = NO;
			
			break;
		
		}
	
	}

}

- (void) handleRotation:(UIRotationGestureRecognizer *)aRotationRecognizer {

	//	We let this be an empty no-op and have the pinch recognizer do all the work instead.
	//	The rotation gesture recognizer is only wired up to provide adequate information.

}

- (void) dealloc {

	[self removeObserver:self forKeyPath:@"files"];
	[shownImageFilePaths release];
	[pinchRecognizer release];
	[rotationRecognizer release];
	[super dealloc];

}

@end
