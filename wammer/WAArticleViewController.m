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
#import "IRActionSheet.h"

#import "WAViewController.h"
#import "WAPaginatedArticlesViewController.h"

#import "UIApplication+CrashReporting.h"
#import "IRMailComposeViewController.h"



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
		[WADiscretePlaintextArticleStyle] = @"Discrete-Plaintext",
		[WADiscreteSingleImageArticleStyle] = @"Discrete-Default",
		[WADiscretePreviewArticleStyle] = @"Discrete-Preview"
		
	}[aStyle]);

}

WAArticleViewControllerPresentationStyle WAArticleViewControllerPresentationStyleFromString (NSString *aString) {

	NSNumber *answer = [[NSDictionary dictionaryWithObjectsAndKeys:
		
		[NSNumber numberWithInt:WAFullFramePlaintextArticleStyle], @"Plaintext",
		[NSNumber numberWithInt:WAFullFrameImageStackArticleStyle], @"Default",
		[NSNumber numberWithInt:WAFullFramePreviewArticleStyle], @"Preview",
		[NSNumber numberWithInt:WADiscretePlaintextArticleStyle], @"Discrete-Plaintext",
		[NSNumber numberWithInt:WADiscreteSingleImageArticleStyle], @"Discrete-Default",
		[NSNumber numberWithInt:WADiscretePreviewArticleStyle], @"Discrete-Preview",
		
	nil] objectForKey:aString];
	
	if (!answer)
		return WAUnknownArticleStyle;
	
	return [answer intValue];

}


@implementation WAArticleViewController

@dynamic view;

@synthesize representedObjectURI, presentationStyle;
@synthesize managedObjectContext, article;
@synthesize onPresentingViewController, onViewDidLoad, onViewTap, onViewPinch;

+ (WAArticleViewControllerPresentationStyle) suggestedStyleForArticle:(WAArticle *)anArticle {

	//	TBD style + context might be better than mixing the context with the style as what we currently do
	//	TBD this does not even handle single-article pages at all

	if (!anArticle)
		return WADiscretePlaintextArticleStyle;
		
	for (WAPreview *aPreview in anArticle.previews)
		if (aPreview.text || aPreview.graphElement.text || aPreview.graphElement.title)
			return WADiscretePreviewArticleStyle;
			
	for (WAFile *aFile in anArticle.files)
		if (aFile.resourceURL || aFile.thumbnailURL)
			return WADiscreteSingleImageArticleStyle;
	
	return WADiscretePlaintextArticleStyle;

}

+ (WAArticleViewController *) controllerForArticle:(NSURL *)articleObjectURL usingPresentationStyle:(WAArticleViewControllerPresentationStyle)aStyle {

	NSString *preferredClassName = [NSStringFromClass([self class]) stringByAppendingFormat:@"-%@", NSStringFromWAArticleViewControllerPresentationStyle(aStyle)];
	NSString *loadedNibName = preferredClassName;
	
	Class loadedClass = NSClassFromString(preferredClassName);
	if (!loadedClass)
		loadedClass = [self class];
	
	NSBundle *usedBundle = [NSBundle bundleForClass:[self class]];
	if (![UINib nibWithNibName:loadedNibName bundle:usedBundle])
		loadedNibName = NSStringFromClass([self class]);
	
	WAArticleViewController *returnedController = [[[loadedClass alloc] initWithNibName:loadedNibName bundle:usedBundle] autorelease];
	returnedController.presentationStyle = aStyle;
	returnedController.representedObjectURI = articleObjectURL;
	return returnedController;

}

- (NSManagedObjectContext *) managedObjectContext {

	if (!managedObjectContext)
		self.managedObjectContext = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
	
	return managedObjectContext;

}

- (WAArticle *) article {

	if (!article)
		self.article = (WAArticle *)[self.managedObjectContext irManagedObjectForURI:self.representedObjectURI];
	
	return article;

}

- (void) viewDidUnload {

//	[self.imageStackView irRemoveObserverBlocksForKeyPath:@"state"];
	
	self.managedObjectContext = nil;
	self.article = nil;

	[super viewDidUnload];

}

- (void) dealloc {

	//	[self disassociateBindings];

	[managedObjectContext release];
	[article release];
	[onPresentingViewController release];
	
	[onViewTap release];
	[onViewDidLoad release];
	[onViewPinch release];
	
	[super dealloc];

}

- (void) viewDidLoad {

	[super viewDidLoad];
	
	[self.view addGestureRecognizer:[[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGlobalTap:)] autorelease]];
	[self.view addGestureRecognizer:[[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleGlobalPinch:)] autorelease]];
  
  if (WAAdvancedFeaturesEnabled())
    [self.view addGestureRecognizer:[[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleGlobalInspect:)] autorelease]];
	
	self.view.article = self.article;
	self.view.presentationStyle = self.presentationStyle;
	
	self.view.imageStackView.delegate = self;
	
	if (self.onViewDidLoad)
		self.onViewDidLoad(self, self.view);
	
}

- (void) handleGlobalTap:(UITapGestureRecognizer *)tapRecognizer {

	if (self.onViewTap)
		self.onViewTap();

}

- (void) handleGlobalPinch:(UIPinchGestureRecognizer *)pinchRecognizer {

	if (self.onViewPinch)
		self.onViewPinch(pinchRecognizer.state, pinchRecognizer.scale, pinchRecognizer.velocity);

}

- (void) handleGlobalInspect:(UILongPressGestureRecognizer *)longPressRecognizer {

	if (longPressRecognizer.state != UIGestureRecognizerStateRecognized)
		return;

	static NSString * const kGlobalInspectActionSheet = @"kGlobalInspectActionSheet";
	
	__block __typeof__(self) nrSelf = self;
	__block IRActionSheetController *controller = objc_getAssociatedObject(self, &kGlobalInspectActionSheet);
	
	if (controller)
	if ([(UIActionSheet *)[controller managedActionSheet] isVisible])
		return;
	
	controller = [IRActionSheetController actionSheetControllerWithTitle:nil cancelAction:nil destructiveAction:nil otherActions:[NSArray arrayWithObjects:
		
		[IRAction actionWithTitle:@"Inspect" block: ^ {
			
			dispatch_async(dispatch_get_current_queue(), ^ {
			
				NSString *inspectionText = [NSString stringWithFormat:@"Article: %@\nFiles: %@\nFileOrder: %@\nComments: %@", self.article, self.article.files, self.article.fileOrder, self.article.comments];
				
				if (nrSelf.onPresentingViewController) {

					WAViewController *shownViewController = [[[WAViewController alloc] init] autorelease];
					
					shownViewController.onLoadview = ^ (WAViewController *self) {
						self.view = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
						UITextView *textView = [[UITextView alloc] initWithFrame:self.view.bounds];
						textView.text = inspectionText;
						textView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
						textView.editable = NO;
						[self.view addSubview:textView];
					};
					
					shownViewController.onShouldAutorotateToInterfaceOrientation = ^ (UIInterfaceOrientation toOrientation) {
						return YES;
					};
					
					__block UINavigationController *shownNavController = [[[UINavigationController alloc] initWithRootViewController:shownViewController] autorelease];
					shownNavController.modalPresentationStyle = UIModalPresentationFormSheet;
					
					shownViewController.title = @"Inspect";
					
					shownViewController.navigationItem.leftBarButtonItem = [IRBarButtonItem itemWithTitle:@"Email" action:^{
					
						NSArray *mailRecipients = [[UIApplication sharedApplication] crashReportRecipients];
						
						NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
						NSString *versionString = [NSString stringWithFormat:@"%@ %@ (%@) Commit %@", [bundleInfo objectForKey:(id)kCFBundleNameKey], [bundleInfo objectForKey:@"CFBundleShortVersionString"], [bundleInfo objectForKey:(id)kCFBundleVersionKey], [bundleInfo objectForKey:@"IRCommitSHA"]];
						
						NSString *mailSubject = [NSString stringWithFormat:@"Inspected Article — %@", versionString];
						
						__block IRMailComposeViewController *mailComposeController = [IRMailComposeViewController controllerWithMessageToRecipients:mailRecipients withSubject:mailSubject messageBody:inspectionText inHTML:NO completion:^(MFMailComposeViewController *controller, MFMailComposeResult result, NSError *error) {
							
							SEL presentingVCSelector = [mailComposeController respondsToSelector:@selector(presentingViewController)] ? @selector(presentingViewController) : @selector(parentViewController);
							UIViewController *presentingVC = [mailComposeController performSelector:presentingVCSelector];
							
							[presentingVC dismissModalViewControllerAnimated:YES];
							
						}];
						
						mailComposeController.modalPresentationStyle = UIModalPresentationFormSheet;
						
						[CATransaction begin];
						
						CATransition *transition = [CATransition animation];
						transition.type = kCATransitionFade;
						transition.duration = 0.3f;
						transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
						transition.fillMode = kCAFillModeForwards;
						transition.removedOnCompletion = YES;
						
						[shownViewController.navigationController presentModalViewController:mailComposeController animated:NO];
						[shownViewController.navigationController.view.window.layer addAnimation:transition forKey:kCATransition];
						
						[CATransaction commit];
						
					}];
					
					shownViewController.navigationItem.rightBarButtonItem = [IRBarButtonItem itemWithSystemItem:UIBarButtonSystemItemDone wiredAction:^(IRBarButtonItem *senderItem) {
					
						[shownNavController dismissModalViewControllerAnimated:YES];
						
					}];
					
					nrSelf.onPresentingViewController( ^ (UIViewController <WAArticleViewControllerPresenting> *parentViewController) {
						[parentViewController presentModalViewController:shownNavController animated:YES];
					});
				
				} else {
			
					[[[[IRAlertView alloc] initWithTitle:@"Inspect" message:inspectionText delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
				
				}
				
				objc_setAssociatedObject(nrSelf, &kGlobalInspectActionSheet, nil, OBJC_ASSOCIATION_ASSIGN);
				
			});
			
		}],
		
	nil]];
	
	objc_setAssociatedObject(self, &kGlobalInspectActionSheet, controller, OBJC_ASSOCIATION_RETAIN);
	
	[(UIActionSheet *)[controller managedActionSheet] showFromRect:(CGRect){
		(CGPoint){
			CGRectGetMidX(self.view.bounds),
			CGRectGetMidY(self.view.bounds)
		},
		(CGSize){ 2, 2 }
	} inView:self.view animated:YES];
	
	((IRActionSheet *)[controller managedActionSheet]).dismissesOnOrientationChange = YES;

}

- (void) setArticle:(WAArticle *)newArticle {

	if (article == newArticle)
		return;
	
	[self willChangeValueForKey:@"article"];
	[article release];
	article = [newArticle retain];
	[self didChangeValueForKey:@"article"];
	
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
				transition.toValue = (id)oldShadowPath;
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
	CATransform3D (^shrinkingTransform)(CGRect aRect, CGRect enclosingRect);
	
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

	shrinkingTransform = ^ (CGRect aRect, CGRect enclosingRect) {
		CGRect fullRect = CGRectIntegral(IRCGSizeGetCenteredInRect((CGSize){ 16.0f * aRect.size.width, 16.0f * aRect.size.height }, enclosingRect, 0.0f, YES));
		CGFloat aspectRatio = CGRectGetWidth(aRect) / CGRectGetWidth(fullRect);
		return CATransform3DConcat(
			CATransform3DMakeScale(aspectRatio, aspectRatio, 1.0f), 
			CATransform3DMakeTranslation((CGRectGetMidX(fullRect) - CGRectGetMidX(aRect)), (CGRectGetMidY(fullRect) - CGRectGetMidY(aRect)), 0.0f)
		);
	};
	
	__block UIView *rootView, *backdropView, *statusBarPaddingView, *fauxView;
	
	IRCATransact(^ {
	
		rootView = self.view.window.rootViewController.modalViewController.view;
		
		backdropView = [[[UIView alloc] initWithFrame:rootView.bounds] autorelease];
		backdropView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		backdropView.backgroundColor = [UIColor blackColor];
		[rootView addSubview:backdropView];

		statusBarPaddingView = [[[UIView alloc] initWithFrame:[rootView.window convertRect:[[UIApplication sharedApplication] statusBarFrame] toView:rootView]] autorelease];
		statusBarPaddingView.backgroundColor = [UIColor blackColor];
		[rootView addSubview:statusBarPaddingView];
		
		fauxView = [[[UIView alloc] initWithFrame:[rootView convertRect:aRect fromView:aStackView]] autorelease];
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
	
	[backdropView retain];
	[statusBarPaddingView retain];
	[fauxView retain];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, animationDuration * NSEC_PER_SEC), dispatch_get_main_queue(), ^ {
	
		[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.35f * NSEC_PER_SEC), dispatch_get_main_queue(), ^ {

			IRCATransact(^ {
		
				[statusBarPaddingView removeFromSuperview];
				[fauxView removeFromSuperview];
				[fauxView autorelease];
				[backdropView removeFromSuperview];
				
				aStackView.firstPhotoView.alpha = 1.0f;
				
				__block WAGalleryViewController *galleryViewController = [WAGalleryViewController controllerRepresentingArticleAtURI:articleURI];
				__block __typeof__(self) nrSelf = self;
				galleryViewController.modalPresentationStyle = UIModalPresentationFullScreen;
				galleryViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
				
				galleryViewController.onDismiss = ^ {
				
					[nrSelf view];
					
					NSArray *originalImages = [[nrSelf.view.imageStackView.images retain] autorelease];
					NSMutableArray *tempImages = [[originalImages mutableCopy] autorelease];
					
					UIImage *currentImage = [galleryViewController currentImage];
					
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
						
						rootView = [UIApplication sharedApplication].keyWindow.rootViewController.modalViewController.view;
						NSParameterAssert(rootView);
						backdropView.frame = rootView.bounds;
						
						fauxView = [[[UIView alloc] initWithFrame:[rootView convertRect:nrSelf.view.imageStackView.firstPhotoView.frame fromView:nrSelf.view.imageStackView]] autorelease];
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
						
						[fauxView retain];
						
						dispatch_after(dispatch_time(DISPATCH_TIME_NOW, animationDuration * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
													
							[backdropView removeFromSuperview];
							[statusBarPaddingView removeFromSuperview];
							[fauxView removeFromSuperview];
							
							[backdropView autorelease];
							[statusBarPaddingView autorelease];
							[fauxView autorelease];
							
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

@end
