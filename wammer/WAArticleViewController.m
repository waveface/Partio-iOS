//
//  WAArticleViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/28/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "QuartzCore+IRAdditions.h"
#import "WAArticleViewController.h"
#import "WADataStore.h"
#import "WAImageStackView.h"
#import "WAGalleryViewController.h"
#import "IRPaginatedView.h"
#import "IRLifetimeHelper.h"

#import "WAPaginatedArticlesViewController.h"

#import "UIApplication+CrashReporting.h"
#import "IRMailComposeViewController.h"

#import "WAArticleFilesListViewController.h"

#import "WANavigationController.h"

#import "WANavigationBar.h"

#import "WAArticleViewController+Subclasses.h"



@interface WAArticleView (PrivateStuff)
@property (nonatomic, readwrite, assign) WAArticleViewControllerPresentationStyle presentationStyle;
@end


@interface WAArticleViewController () <UIGestureRecognizerDelegate, WAImageStackViewDelegate>

@property (nonatomic, readwrite, retain) NSURL *representedObjectURI;
@property (nonatomic, readwrite, assign) WAArticleViewControllerPresentationStyle presentationStyle;
@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) WAArticle *article;

@end


NSString * NSStringFromWAArticleViewControllerPresentationStyle (WAArticleViewControllerPresentationStyle aStyle) {

	return ((NSString *[]){
		
		[WAFullFramePlaintextArticleStyle] = @"Plaintext",
		[WAFullFrameImageStackArticleStyle] = @"Default",
		[WAFullFramePreviewArticleStyle] = @"Preview",
		[WADiscretePlaintextArticleStyle] = @"Discrete_Plaintext",
		[WADiscreteSingleImageArticleStyle] = @"Discrete_Default",
		[WADiscretePreviewArticleStyle] = @"Discrete_Preview"
		
	}[aStyle]);

}

WAArticleViewControllerPresentationStyle WAArticleViewControllerPresentationStyleFromString (NSString *aString) {

	NSNumber *answer = [[NSDictionary dictionaryWithObjectsAndKeys:
		
		[NSNumber numberWithInt:WAFullFramePlaintextArticleStyle], @"Plaintext",
		[NSNumber numberWithInt:WAFullFrameImageStackArticleStyle], @"Default",
		[NSNumber numberWithInt:WAFullFramePreviewArticleStyle], @"Preview",
		[NSNumber numberWithInt:WADiscretePlaintextArticleStyle], @"Discrete_Plaintext",
		[NSNumber numberWithInt:WADiscreteSingleImageArticleStyle], @"Discrete_Default",
		[NSNumber numberWithInt:WADiscretePreviewArticleStyle], @"Discrete_Preview",
		
	nil] objectForKey:aString];
	
	if (!answer)
		return WAUnknownArticleStyle;
	
	return [answer intValue];

}

WAArticleViewControllerPresentationStyle WAFullFrameArticleStyleFromDiscreteStyle (WAArticleViewControllerPresentationStyle aStyle) {

	return ((WAArticleViewControllerPresentationStyle[]){
		[WADiscretePlaintextArticleStyle] = WAFullFramePlaintextArticleStyle,
		[WADiscreteSingleImageArticleStyle] = WAFullFrameImageStackArticleStyle,
		[WADiscretePreviewArticleStyle] = WAFullFramePreviewArticleStyle,
		[WADiscreteDocumentArticleStyle] = WAFullFrameDocumentArticleStyle
	})[aStyle];

}

WAArticleViewControllerPresentationStyle WADiscreteArticleStyleFromFullFrameStyle (WAArticleViewControllerPresentationStyle aStyle) {

	return ((WAArticleViewControllerPresentationStyle[]){
		[WAFullFramePlaintextArticleStyle] = WADiscretePlaintextArticleStyle,
		[WAFullFrameImageStackArticleStyle] = WADiscreteSingleImageArticleStyle,
		[WAFullFramePreviewArticleStyle] = WADiscretePreviewArticleStyle,
		[WAFullFrameDocumentArticleStyle] = WADiscreteDocumentArticleStyle
	})[aStyle];

}


@implementation WAArticleViewController

@dynamic view;

@synthesize representedObjectURI, presentationStyle;
@synthesize managedObjectContext, article;
@synthesize onPresentingViewController, onViewDidLoad, onViewTap, onViewPinch;

+ (WAArticleViewControllerPresentationStyle) suggestedDiscreteStyleForArticle:(WAArticle *)anArticle {

	if (!anArticle)
		return WADiscretePlaintextArticleStyle;
		
	for (WAPreview *aPreview in anArticle.previews)
		if (aPreview.text || aPreview.url || aPreview.graphElement.text || aPreview.graphElement.title)
			return WADiscretePreviewArticleStyle;
			
	for (WAFile *aFile in anArticle.files)
		if (aFile.resourceURL || aFile.thumbnailURL || [aFile.remoteResourceType isEqualToString:@"image"])
			return WADiscreteSingleImageArticleStyle;
	
	return WADiscretePlaintextArticleStyle;

}

+ (WAArticleViewControllerPresentationStyle) suggestedStyleForArticle:(WAArticle *)anArticle {

	return [self suggestedDiscreteStyleForArticle:anArticle];

}

+ (WAArticleViewController *) controllerForArticle:(NSURL *)articleObjectURL usingPresentationStyle:(WAArticleViewControllerPresentationStyle)aStyle {

	NSString *preferredClassName = [NSStringFromClass([self class]) stringByAppendingFormat:@"_%@", NSStringFromWAArticleViewControllerPresentationStyle(aStyle)];
	NSString *loadedNibName = preferredClassName;
	
	Class loadedClass = NSClassFromString(preferredClassName);
	if (!loadedClass)
		loadedClass = [self class];
	
	NSBundle *usedBundle = [NSBundle bundleForClass:[self class]];
	if (![UINib nibWithNibName:loadedNibName bundle:usedBundle])
		loadedNibName = NSStringFromClass([self class]);
  
  if (![UINib nibWithNibName:loadedNibName bundle:usedBundle])
    loadedNibName = nil;
	
	WAArticleViewController *returnedController = [[loadedClass alloc] initWithNibName:loadedNibName bundle:usedBundle];
	returnedController.presentationStyle = aStyle;
	returnedController.representedObjectURI = articleObjectURL;
	return returnedController;

}

- (NSManagedObjectContext *) managedObjectContext {

	if (!managedObjectContext)
		self.managedObjectContext = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
	
	return managedObjectContext;

}

+ (NSSet *) keyPathsForValuesAffectingArticle {

	return [NSSet setWithObjects:
	
		@"representedObjectURI",
	
	nil];

}

- (WAArticle *) article {

	if (!article && self.representedObjectURI)
		article = (WAArticle *)[self.managedObjectContext irManagedObjectForURI:self.representedObjectURI];
	
	return article;

}

- (void) viewDidUnload {

	self.managedObjectContext = nil;
	self.article = nil;
	self.inspectionActionSheetController = nil;
	self.coverPhotoSwitchPopoverController = nil;
	
	[super viewDidUnload];

}

- (void) viewDidLoad {

	[super viewDidLoad];
	
	UITapGestureRecognizer *globalTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGlobalTap:)];
	UIPinchGestureRecognizer *globalPinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleGlobalPinch:)];
	UILongPressGestureRecognizer *globalInspectRecognizer = [self newInspectionGestureRecognizer];
	
	globalTapRecognizer.delegate = self;
	globalPinchRecognizer.delegate = self;
	globalInspectRecognizer.delegate = self;
	
	[self.view addGestureRecognizer:globalTapRecognizer];
	[self.view addGestureRecognizer:globalPinchRecognizer];
	[self.view addGestureRecognizer:globalInspectRecognizer];
	
	self.view.article = self.article;
	
	if ([self.view isKindOfClass:[WAArticleView class]])
		((WAArticleView *)self.view).presentationStyle = self.presentationStyle;
	
	self.view.imageStackView.delegate = self;
	
	if (self.onViewDidLoad)
		self.onViewDidLoad(self, self.view);
	
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {

	__block __typeof__(self) nrSelf = self;
	__block BOOL (^wrappedIn)(UIView *, Class) = ^ (UIView *aView, Class aClass) {
	
		if ([aView isKindOfClass:aClass])
			return YES;
		
		if (!aView.superview)
			return NO;
		
		if (aView == nrSelf.view)
			return NO;
		
		return wrappedIn(aView.superview, aClass);
		
	};

	if ([touch.view isKindOfClass:[UIButton class]])
		return NO;
	
	if (wrappedIn(touch.view, [UIScrollView class]))
		return NO;
	
	return YES;

}

- (void) handleGlobalTap:(UITapGestureRecognizer *)tapRecognizer {

	if (self.onViewTap)
		self.onViewTap();

}

- (void) handleGlobalPinch:(UIPinchGestureRecognizer *)pinchRecognizer {

	if (self.onViewPinch)
		self.onViewPinch(pinchRecognizer.state, pinchRecognizer.scale, pinchRecognizer.velocity);

}


- (void) setArticle:(WAArticle *)newArticle {

	if (article == newArticle)
		return;
	
	article = newArticle;
	
	if ([self isViewLoaded])
		self.view.article = newArticle;

}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	[CATransaction begin];
	[CATransaction setDisableActions:YES];

	for (UIView *aView in self.view.imageStackView.subviews) {
	
		CGPathRef oldShadowPath = aView.layer.shadowPath;
		if (oldShadowPath) {
			CFRetain(oldShadowPath);
			[aView.layer removeAnimationForKey:@"shadowPath"];
			[aView.layer addAnimation:((^ {
				CABasicAnimation *transition = [CABasicAnimation animationWithKeyPath:@"shadowPath"];
				transition.fromValue = (id)[UIBezierPath bezierPathWithRect:(CGRect){
					CGPointZero,
					((CALayer *)[aView.layer presentationLayer]).bounds.size
				}].CGPath;
				transition.toValue = (__bridge id)oldShadowPath;
				transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
				transition.duration = duration;
				transition.removedOnCompletion = YES;
				return transition;
			})()) forKey:@"transition"];
			aView.layer.shadowPath = oldShadowPath;
			CFRelease(oldShadowPath);
		}
	
	}
	
	[CATransaction commit];
		
}





- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	return 0;

}

- (void) imageStackView:(WAImageStackView *)aStackView didRecognizePinchZoomGestureWithRepresentedImage:(UIImage *)representedImage contentRect:(CGRect)aRect transform:(CATransform3D)layerTransform {

	if (!representedImage)
		return;
	
	NSURL *articleURI = [[self.article objectID] URIRepresentation];
	
	if (!articleURI)
		return;
	
	NSTimeInterval const animationDuration = 0.3f;
	NSString * const animationTimingFunctionName = kCAMediaTimingFunctionEaseInEaseOut;
	CABasicAnimation * (^animation)(NSString *keyPath, id fromValue, id toValue, NSTimeInterval duration);
	CATransform3D (^fillingTransform)(CGRect aRect, CGRect enclosingRect);
	//	CATransform3D (^shrinkingTransform)(CGRect aRect, CGRect enclosingRect);
	
	animation = ^ (NSString *keyPath, id fromValue, id toValue, NSTimeInterval duration) {
		CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:keyPath];
		animation.fromValue = fromValue;
		animation.toValue = toValue;
		animation.duration = duration;
		animation.timingFunction = [CAMediaTimingFunction functionWithName:animationTimingFunctionName];
		animation.fillMode = kCAFillModeForwards;
		animation.removedOnCompletion = YES;
		return animation;
	};
	
	fillingTransform = ^ (CGRect aRect, CGRect enclosingRect) {
		CGRect fullRect = CGRectIntegral(IRCGSizeGetCenteredInRect((CGSize){ 16.0f * aRect.size.width, 16.0f * aRect.size.height }, enclosingRect, 0.0f, YES));
		CGFloat aspectRatio = CGRectGetWidth(fullRect) / CGRectGetWidth(aRect);
		return CATransform3DConcat(
			CATransform3DMakeScale(aspectRatio, aspectRatio, 1.0f), 
			CATransform3DMakeTranslation((CGRectGetMidX(fullRect) - CGRectGetMidX(aRect)), (CGRectGetMidY(fullRect) - CGRectGetMidY(aRect)), 0.0f)
		);
	};

	//	shrinkingTransform = ^ (CGRect aRect, CGRect enclosingRect) {
	//		CGRect fullRect = CGRectIntegral(IRCGSizeGetCenteredInRect((CGSize){ 16.0f * aRect.size.width, 16.0f * aRect.size.height }, enclosingRect, 0.0f, YES));
	//		CGFloat aspectRatio = CGRectGetWidth(aRect) / CGRectGetWidth(fullRect);
	//		return CATransform3DConcat(
	//			CATransform3DMakeScale(aspectRatio, aspectRatio, 1.0f), 
	//			CATransform3DMakeTranslation((CGRectGetMidX(fullRect) - CGRectGetMidX(aRect)), (CGRectGetMidY(fullRect) - CGRectGetMidY(aRect)), 0.0f)
	//		);
	//	};
	
	__block UIView *rootView, *backdropView, *statusBarPaddingView, *fauxView;
	
	IRCATransact(^ {
	
		rootView = self.view.window.rootViewController.modalViewController.view;
		
		if (!rootView)
			rootView = self.view.window.rootViewController.view;
		
		backdropView = [[UIView alloc] initWithFrame:rootView.bounds];
		backdropView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		backdropView.backgroundColor = [UIColor blackColor];
		[rootView addSubview:backdropView];

		statusBarPaddingView = [[UIView alloc] initWithFrame:[rootView.window convertRect:[[UIApplication sharedApplication] statusBarFrame] toView:rootView]];
		statusBarPaddingView.backgroundColor = [UIColor blackColor];
		[rootView addSubview:statusBarPaddingView];
		
		fauxView = [[UIView alloc] initWithFrame:[rootView convertRect:aRect fromView:aStackView]];
		fauxView.layer.contents = (id)representedImage.CGImage;
		fauxView.layer.contentsGravity = kCAGravityResizeAspect;
		[rootView addSubview:fauxView];
		
		CABasicAnimation *backdropShowing = animation(@"opacity",
			[NSNumber numberWithFloat:0.0f],
			[NSNumber numberWithFloat:1.0f],
			animationDuration
		);
		
		CABasicAnimation *fauxViewZoomIn = animation(@"transform", 
			[NSValue valueWithCATransform3D:layerTransform],
			[NSValue valueWithCATransform3D:fillingTransform(fauxView.frame, rootView.bounds)],
			animationDuration
		);
		
		aStackView.firstPhotoView.alpha = 0.0f;
		
		[backdropView.layer setValue:[backdropShowing toValue] forKeyPath:[backdropShowing keyPath]];
		[backdropView.layer addAnimation:backdropShowing forKey:@"transition"];
		[fauxView.layer setValue:[fauxViewZoomIn toValue] forKeyPath:[fauxViewZoomIn keyPath]];
		[fauxView.layer addAnimation:fauxViewZoomIn forKey:@"transition"];
	
	});
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, animationDuration * NSEC_PER_SEC), dispatch_get_main_queue(), ^ {
	
		[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.35f * NSEC_PER_SEC), dispatch_get_main_queue(), ^ {

			IRCATransact(^ {
		
				[statusBarPaddingView removeFromSuperview];
				[fauxView removeFromSuperview];
				[backdropView removeFromSuperview];
				
				aStackView.firstPhotoView.alpha = 1.0f;
				
				__weak WAGalleryViewController *galleryViewController = [WAGalleryViewController controllerRepresentingArticleAtURI:articleURI];
				__weak WAArticleViewController *nrSelf = self;
				
				galleryViewController.modalPresentationStyle = UIModalPresentationFullScreen;
				galleryViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
				
				galleryViewController.onDismiss = ^ {
				
					[nrSelf view];
					
					NSArray *originalImages = nrSelf.view.imageStackView.images;
					NSMutableArray *tempImages = [originalImages mutableCopy];
					
					UIImage *currentImage = [galleryViewController currentImage];
          
          if (!currentImage)
          if ([tempImages count] > 0)
            currentImage = [tempImages objectAtIndex:0];
          
          if (currentImage) {					
            if (![tempImages containsObject:currentImage]) {
              if ([tempImages count] > 0) {
                [tempImages replaceObjectAtIndex:0 withObject:currentImage];
              } else {
                [tempImages insertObject:currentImage atIndex:0];
              }
            } else {
              [tempImages removeObject:currentImage];
              [tempImages insertObject:currentImage atIndex:0];
            }
          }
										
					UINavigationController *parentVC = (UINavigationController *)galleryViewController.parentViewController;
					[galleryViewController dismissModalViewControllerAnimated:NO];
					
					//	Nav controller will NOT update its view until necessary
					[parentVC.view setNeedsLayout];
					[parentVC.view layoutIfNeeded];
					[parentVC.topViewController.view setNeedsLayout];
					[parentVC.topViewController.view layoutIfNeeded];
					
					NSParameterAssert(nrSelf.view.imageStackView.window);
					
					[nrSelf.view.imageStackView setImages:tempImages asynchronously:NO withDecodingCompletion: ^ {
						
						NSParameterAssert(nrSelf.view.imageStackView.firstPhotoView);
						
						nrSelf.view.imageStackView.firstPhotoView.alpha = 0.0f;
						
            UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
            if (rootVC.modalViewController)
              rootView = rootVC.modalViewController.view;
            else
              rootView = rootVC.view;
            
						NSParameterAssert(rootView);
						backdropView.frame = rootView.bounds;
						
						fauxView = [[UIView alloc] initWithFrame:[rootView convertRect:nrSelf.view.imageStackView.firstPhotoView.frame fromView:nrSelf.view.imageStackView]];
						NSParameterAssert(fauxView);
						fauxView.layer.contents = (id)currentImage.CGImage;
						fauxView.layer.transform = nrSelf.view.imageStackView.firstPhotoView.layer.transform;
						fauxView.layer.contentsGravity = kCAGravityResizeAspect;
						
						CABasicAnimation *backdropHiding = animation(@"opacity",
							[NSNumber numberWithFloat:1.0f],
							[NSNumber numberWithFloat:0.0f],
							animationDuration
						);
		
						CABasicAnimation *fauxViewZoomOut = animation(@"transform", 
							[NSValue valueWithCATransform3D:fillingTransform(fauxView.frame, rootView.bounds)],
							[NSValue valueWithCATransform3D:fauxView.layer.transform],
							animationDuration
						);
						
						[backdropView.layer setValue:[backdropHiding toValue] forKeyPath:[backdropHiding keyPath]];
						[backdropView.layer addAnimation:backdropHiding forKey:@"transition"];
						[fauxView.layer setValue:[fauxViewZoomOut toValue] forKeyPath:[fauxViewZoomOut keyPath]];
						[fauxView.layer addAnimation:fauxViewZoomOut forKey:@"transition"];
											
						[rootView addSubview:backdropView];
						[rootView addSubview:fauxView];
						[rootView addSubview:statusBarPaddingView];
						
						dispatch_after(dispatch_time(DISPATCH_TIME_NOW, animationDuration * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
													
							[backdropView removeFromSuperview];
							[statusBarPaddingView removeFromSuperview];
							[fauxView removeFromSuperview];
							
							nrSelf.view.imageStackView.firstPhotoView.alpha = 1.0f;
							
							dispatch_after(dispatch_time(DISPATCH_TIME_NOW, animationDuration * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
							
								CATransition *fadeTransition = [CATransition animation];
								fadeTransition.duration = 0.5f * animationDuration;
								fadeTransition.type = kCATransitionFade;
								fadeTransition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
								fadeTransition.fillMode = kCAFillModeForwards;
								fadeTransition.removedOnCompletion = YES;
							
								[CATransaction begin];
							
								[nrSelf.view.imageStackView setImages:originalImages asynchronously:NO withDecodingCompletion:nil];
								[nrSelf.view.imageStackView.layer addAnimation:fadeTransition forKey:@"transition"];

								[CATransaction commit];
								
							});

						});
						
					}];
					
				};
				
				if (self.onPresentingViewController) {
					self.onPresentingViewController( ^ (UIViewController <WAArticleViewControllerPresenting> *parentViewController) {
						[parentViewController presentModalViewController:galleryViewController animated:NO];
					});
				}
			
			});

		});
	
	});

}

- (void) imageStackView:(WAImageStackView *)aStackView didChangeInteractionStateToState:(WAImageStackViewInteractionState)newState {

	if (self.onPresentingViewController) {
		self.onPresentingViewController( ^ (UIViewController <WAArticleViewControllerPresenting> *parentViewController) {
		
			switch (newState) {
				case WAImageStackViewInteractionNormal: {			
					[parentViewController setContextControlsVisible:YES animated:YES];
					break;
				}
				case WAImageStackViewInteractionZoomInPossible: {			
					[parentViewController setContextControlsVisible:NO animated:YES];
					break;
				}
			}
	
		});
	}

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {

	return YES;

}





- (WANavigationController *) wrappingNavController {

	NSParameterAssert(!self.navigationController);
	WANavigationController *controller = [[WANavigationController alloc] initWithRootViewController:self];
	
	return controller;

}

- (void) setContextControlsVisible:(BOOL)contextControlsVisible animated:(BOOL)animated {

	if ([self.navigationController topViewController] != self)
		return;
	
	WANavigationBar *navBar = (WANavigationBar *)self.navigationController.navigationBar;
	if ([navBar isKindOfClass:[WANavigationBar class]])
		navBar.alpha = contextControlsVisible ? 1 : 0.03;

}

@end
