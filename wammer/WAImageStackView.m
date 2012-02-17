//
//  WAImageStackView.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/28/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAImageStackView.h"
#import "WADataStore.h"

#import "CGGeometry+IRAdditions.h"
#import "QuartzCore+IRAdditions.h"
#import "UIKit+IRAdditions.h"

#import "WAImageView.h"





static const NSString *kWAImageStackViewElementCanonicalTransform = @"kWAImageStackViewElementCanonicalTransform";
static const NSString *kWAImageStackViewElementImage = @"kWAImageStackViewElementImage";


@interface WAImageStackView () <UIGestureRecognizerDelegate>

- (void) waInit;
@property (nonatomic, readwrite, retain) NSArray *shownImages;
@property (nonatomic, readwrite, retain) UIPinchGestureRecognizer *pinchRecognizer;
@property (nonatomic, readwrite, retain) UIRotationGestureRecognizer *rotationRecognizer;
@property (nonatomic, readwrite, retain) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, readwrite, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, readwrite, assign) UIView *firstPhotoView;
@property (nonatomic, readwrite, assign) BOOL gestureProcessingOngoing;

- (void) setShownImages:(NSArray *)newImages withDecodingCompletion:(void(^)(void))aBlock;

@end


@implementation WAImageStackView

@synthesize state;
@synthesize images, delegate, shownImages;
@synthesize pinchRecognizer, rotationRecognizer, tapRecognizer, activityIndicator, firstPhotoView;
@synthesize gestureProcessingOngoing;
@synthesize maxNumberOfImages;

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

	self.maxNumberOfImages = 2;

	self.gestureProcessingOngoing = NO;
	self.state = WAImageStackViewInteractionNormal;
	
	self.pinchRecognizer = [[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)] autorelease];
	self.pinchRecognizer.delegate = self;
	[self addGestureRecognizer:self.pinchRecognizer];
	
	self.rotationRecognizer = [[[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)] autorelease];
	self.rotationRecognizer.delegate = self;
	[self addGestureRecognizer:self.rotationRecognizer];
	
	self.tapRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)] autorelease];
	[self addGestureRecognizer:self.tapRecognizer];
	
	self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
	self.activityIndicator.center = (CGPoint){
		CGRectGetMidX(self.bounds),
		CGRectGetMidY(self.bounds)
	};
	self.activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin;
	self.activityIndicator.hidesWhenStopped = YES;
	[self insertSubview:self.activityIndicator atIndex:[self.subviews count]];
	
}

- (void) setState:(WAImageStackViewInteractionState)newState {

	if (state == newState)
		return;
	
 	[self willChangeValueForKey:@"state"];
	state = newState;
	[self didChangeValueForKey:@"state"];
	
	if ([self.delegate respondsToSelector:@selector(imageStackView:didChangeInteractionStateToState:)])
		[self.delegate imageStackView:self didChangeInteractionStateToState:newState];

}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {

	if (gestureRecognizer == self.pinchRecognizer)
		return (otherGestureRecognizer == self.rotationRecognizer);
	
	if (gestureRecognizer == self.rotationRecognizer)
		return (otherGestureRecognizer == self.pinchRecognizer);

	return NO;

}

- (void) setImages:(NSArray *)newImages {

	[self setImages:newImages asynchronously:YES withDecodingCompletion:nil];

}

- (void) setImages:(NSArray *)newImages asynchronously:(BOOL)async withDecodingCompletion:(void (^)(void))aBlock {

	async = NO;

	if (images == newImages)
		return;

	[self willChangeValueForKey:@"images"];
	[images release];
	images = [newImages retain];
	[self didChangeValueForKey:@"images"];
	
	NSArray *decodedImages = [self.images objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:(NSRange){ 0, MIN(3, [self.images count]) }]];

	if (async) {
	
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^(void) {
		
			NSArray *actualDecodedImages = [decodedImages irMap: ^ (UIImage *anImage, NSUInteger index, BOOL *stop) {
				return [anImage irDecodedImage];
			}];
			
			dispatch_async(dispatch_get_main_queue(), ^ {
				[self setShownImages:actualDecodedImages withDecodingCompletion:aBlock];
			});
			
		});
	
	} else {
			
		[self setShownImages:decodedImages withDecodingCompletion:aBlock];
	
	}

}

- (void) setShownImages:(NSArray *)newShownImages {

	[self setShownImages:newShownImages withDecodingCompletion:nil];

}

- (void) setShownImages:(NSArray *)newShownImages withDecodingCompletion:(void(^)(void))aBlock {

	if (self.gestureProcessingOngoing) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0f * NSEC_PER_SEC), dispatch_get_current_queue(), ^(void){
				[self performSelector:_cmd withObject:newShownImages withObject:aBlock];
		});
		return;
	}
	
	if ([newShownImages isEqualToArray:shownImages]) {
		if (aBlock)
			aBlock();
		return;
	}
	
	[self willChangeValueForKey:@"shownImages"];
	[shownImages release];
	shownImages = [newShownImages retain];
	[self didChangeValueForKey:@"shownImages"];
	
	
	static int kPhotoViewTag = 1024;
	
	self.firstPhotoView = nil;

		[[self.subviews objectsAtIndexes:[self.subviews indexesOfObjectsPassingTest: ^ (UIView *aSubview, NSUInteger idx, BOOL *stop) {
			
			return (BOOL)(aSubview.tag == kPhotoViewTag);
				
		}]] enumerateObjectsUsingBlock: ^ (UIView *aSubview, NSUInteger idx, BOOL *stop) {
		
			[aSubview removeFromSuperview];
			
		}];
			
		[shownImages enumerateObjectsUsingBlock: ^ (UIImage *anImage, NSUInteger idx, BOOL *stop) {
		
			UIView *frameView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
			objc_setAssociatedObject(frameView, kWAImageStackViewElementImage, anImage, OBJC_ASSOCIATION_RETAIN);
			frameView.tag = kPhotoViewTag;
			frameView.layer.shouldRasterize = YES;
			frameView.layer.rasterizationScale = [UIScreen mainScreen].scale;
			frameView.layer.backgroundColor = [UIColor colorWithWhite:0.75 alpha:1].CGColor;
			frameView.layer.borderColor = [UIColor whiteColor].CGColor;
			frameView.layer.borderWidth = 1.0f;
			frameView.layer.shadowOffset = (CGSize){ 0, 1 };
			frameView.layer.shadowRadius = 1.0f;
			frameView.layer.shadowOpacity = 0.25f;
			frameView.layer.edgeAntialiasingMask = kCALayerLeftEdge|kCALayerRightEdge|kCALayerTopEdge|kCALayerBottomEdge;
			[frameView.layer setActions:[NSDictionary dictionaryWithObjectsAndKeys:
				[NSNull null], @"shadowPath",
			nil]];
			frameView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
			frameView.opaque = NO;
			
			WAImageView *imageView = [[[WAImageView alloc] initWithFrame:frameView.bounds] autorelease];
			imageView.image = (UIImage *)objc_getAssociatedObject(frameView, kWAImageStackViewElementImage);
			imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
			imageView.contentMode = UIViewContentModeScaleAspectFill;
			imageView.layer.masksToBounds = YES;
			
			[frameView addSubview:imageView];					
			[self addSubview:frameView];		
			
			[self.activityIndicator stopAnimating];
			
		}];
		
		[self layoutSubviews];
		[self setNeedsLayout];
		
		if (aBlock)
			aBlock();
	
}
	
- (void) layoutSubviews {

	[self.activityIndicator startAnimating];

	if (self.gestureProcessingOngoing)
		return;
	
	static int kPhotoViewTag = 1024;

	NSArray *photoViews = [self.subviews objectsAtIndexes:[self.subviews indexesOfObjectsPassingTest: ^ (UIView *aSubview, NSUInteger idx, BOOL *stop) {
		
		return (BOOL)(aSubview.tag == kPhotoViewTag);
			
	}]];
	
	switch ([photoViews count]) {
		case 1: {
			UIView *photoView = [photoViews objectAtIndex:0];
			photoView.frame = CGRectMake(  0,  0,296,196);
			[self addSubview:photoView];
			break; }
			
		case 2: {
			UIView *photoView = [photoViews objectAtIndex:0];
			photoView.frame = CGRectMake(  0,  0,146,196);
			[self addSubview:photoView];

			photoView = [photoViews objectAtIndex:1];
			photoView.frame = CGRectMake(150,  0,146,196);
			[self addSubview:photoView];
			[self.activityIndicator stopAnimating];
			break; }
			
		case 3:{
			UIView *photoView = [photoViews objectAtIndex:0];
			photoView.frame = CGRectMake(  0,  0,196,196);
			[self addSubview:photoView];

			photoView = [photoViews objectAtIndex:1];
			photoView.frame = CGRectMake(200,  0, 96, 96);
			[self addSubview:photoView];

			photoView = [photoViews objectAtIndex:2];
			photoView.frame = CGRectMake(200,100, 96, 96);
			[self addSubview:photoView];
			break; }
		
		default:
			break;
	}

}

- (void) handlePinch:(UIPinchGestureRecognizer *)aPinchRecognizer {

	static CGPoint startingTouchPoint;

	NSValue *canonicalTransformValue = objc_getAssociatedObject(self.firstPhotoView.layer, kWAImageStackViewElementCanonicalTransform);
	CATransform3D canonicalTransform = canonicalTransformValue ? [canonicalTransformValue CATransform3DValue] : CATransform3DIdentity;
	
	switch (aPinchRecognizer.state) {
	
		case UIGestureRecognizerStatePossible:
		case UIGestureRecognizerStateBegan: {
		
			startingTouchPoint = [aPinchRecognizer locationInView:self];
		
			self.state = WAImageStackViewInteractionNormal;
			self.gestureProcessingOngoing = YES;
		
			break;
		
		}
		
		case UIGestureRecognizerStateChanged: {
		
			CGPoint currentTouchPoint = [aPinchRecognizer locationInView:self];
			
			self.state = (self.pinchRecognizer.scale > 1.2f) ? WAImageStackViewInteractionZoomInPossible : WAImageStackViewInteractionNormal;
		
			IRCATransact(^ {
			
				CATransform3D translationTransform = CATransform3DMakeTranslation(
					currentTouchPoint.x - startingTouchPoint.x, 
					currentTouchPoint.y - startingTouchPoint.y,
					0.0f
				);
				
				CATransform3D scaleTransform = CATransform3DMakeScale(
					self.pinchRecognizer.scale,
					self.pinchRecognizer.scale,
					1.0f
				);
				
				CATransform3D rotationTransform = CATransform3DMakeRotation(
					self.rotationRecognizer.rotation, 
					0.0f, 
					0.0f, 
					1.0f
				);
			
				self.firstPhotoView.layer.transform = CATransform3DConcat(CATransform3DConcat(CATransform3DConcat(canonicalTransform, scaleTransform), rotationTransform), translationTransform);
			});
		
			break;
		
		}
		
		case UIGestureRecognizerStateEnded:
		case UIGestureRecognizerStateCancelled:
		case UIGestureRecognizerStateFailed: {
		
			UIView *capturedFirstPhotoView = [[self.firstPhotoView retain] autorelease];
		
			self.state = (self.pinchRecognizer.scale > 1.2f) ? WAImageStackViewInteractionZoomInPossible : WAImageStackViewInteractionNormal;
			
			CGRect capturedRect = capturedFirstPhotoView.layer.bounds;
			capturedRect.origin = capturedFirstPhotoView.layer.position;
			capturedRect.origin.x -= 0.5f * CGRectGetWidth(capturedRect);
			capturedRect.origin.y -= 0.5f * CGRectGetHeight(capturedRect);
			
			CATransform3D oldTransform = ((CALayer *)[capturedFirstPhotoView.layer presentationLayer]).transform;
			CATransform3D newTransform = canonicalTransform;

			if (self.state == WAImageStackViewInteractionZoomInPossible) {
			
				dispatch_async(dispatch_get_main_queue(), ^ {
												
					[self.delegate imageStackView:self didRecognizePinchZoomGestureWithRepresentedImage:objc_getAssociatedObject(capturedFirstPhotoView, kWAImageStackViewElementImage) contentRect:capturedRect transform:oldTransform];
					
					capturedFirstPhotoView.layer.transform = newTransform;
				
				});

			} else {
							
				CABasicAnimation *transformAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
				transformAnimation.fromValue = [NSValue valueWithCATransform3D:oldTransform];
				transformAnimation.toValue = [NSValue valueWithCATransform3D:newTransform];
				transformAnimation.removedOnCompletion = YES;
				transformAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
				transformAnimation.duration = 0.3f;
			
				capturedFirstPhotoView.layer.transform = newTransform;
				[capturedFirstPhotoView.layer addAnimation:transformAnimation forKey:@"transition"];
			
			}
		
			self.gestureProcessingOngoing = NO;
			
			break;
		
		}
	
	}

}

- (void) handleRotation:(UIRotationGestureRecognizer *)aRotationRecognizer {

	//	We let this be an empty no-op and have the pinch recognizer do all the work instead.
	//	The rotation gesture recognizer is only wired up to provide adequate information.

}

- (void) handleTap:(UITapGestureRecognizer *)aTapRecognizer {

	if (self.gestureProcessingOngoing)
		return;
	
	UIView *capturedFirstPhotoView = [[self.firstPhotoView retain] autorelease];
	[self.delegate imageStackView:self didRecognizePinchZoomGestureWithRepresentedImage:objc_getAssociatedObject(capturedFirstPhotoView, kWAImageStackViewElementImage) contentRect:capturedFirstPhotoView.frame transform:capturedFirstPhotoView.layer.transform];

}

- (void) reset {

	self.gestureProcessingOngoing = NO;
	[self setNeedsLayout];

}

- (void) dealloc {

	[images release];
	[shownImages release];
	[pinchRecognizer release];
	[rotationRecognizer release];
	[tapRecognizer release];
	[activityIndicator release];
	
	[super dealloc];

}

@end
