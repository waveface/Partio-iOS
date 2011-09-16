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
#import "IRRelativeDateFormatter.h"
#import "IRPaginatedView.h"

#import "WAPaginatedArticlesViewController.h"

@interface WAArticleViewController () <UIGestureRecognizerDelegate, WAImageStackViewDelegate>

@property (nonatomic, readwrite, retain) NSURL *representedObjectURI;
@property (nonatomic, readwrite, assign) WAArticleViewControllerPresentationStyle presentationStyle;
@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) WAArticle *article;

- (void) refreshView;

+ (IRRelativeDateFormatter *) relativeDateFormatter;

@end


@implementation WAArticleViewController
@synthesize representedObjectURI, presentationStyle;
@synthesize managedObjectContext, article;
@synthesize contextInfoContainer, imageStackView, previewBadge, textEmphasisView, avatarView, relativeCreationDateLabel, userNameLabel, articleDescriptionLabel, deviceDescriptionLabel, contextTextView;
@synthesize onPresentingViewController, onViewTap;

+ (WAArticleViewController *) controllerForArticle:(NSURL *)articleObjectURL usingPresentationStyle:(WAArticleViewControllerPresentationStyle)aStyle {

	NSString *loadedNibName = [NSStringFromClass([self class]) stringByAppendingFormat:@"-%@", ((NSString *[]){
		[WAFullFramePlaintextArticleStyle] = @"Plaintext",
		[WAFullFrameImageStackArticleStyle] = @"Default",
		[WAFullFramePreviewArticleStyle] = @"Preview",
		[WADiscretePlaintextArticleStyle] = @"Discrete-Plaintext",
		[WADiscreteSingleImageArticleStyle] = @"Discrete-Default",
		[WADiscretePreviewArticleStyle] = @"Discrete-Preview"
	}[aStyle])];

	WAArticleViewController *returnedController = [[[self alloc] initWithNibName:loadedNibName bundle:[NSBundle bundleForClass:[self class]]] autorelease];
	returnedController.presentationStyle = aStyle;
	returnedController.representedObjectURI = articleObjectURL;
	return returnedController;

}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleManagedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
	
	return self;

}

- (NSManagedObjectContext *) managedObjectContext {

	if (!managedObjectContext)
		self.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
	
	return managedObjectContext;

}

- (WAArticle *) article {

	if (!article)
		self.article = (WAArticle *)[self.managedObjectContext irManagedObjectForURI:self.representedObjectURI];
	
	return article;

}

- (void) handleManagedObjectContextDidSave:(NSNotification *)aNotification {

	NSManagedObjectContext *savedContext = (NSManagedObjectContext *)[aNotification object];
	
	if (savedContext == self.managedObjectContext)
		return;
	
	[self retain];
	
	dispatch_async(dispatch_get_main_queue(), ^ {
	
		[self.managedObjectContext mergeChangesFromContextDidSaveNotification:aNotification];
		[self.managedObjectContext refreshObject:self.article mergeChanges:YES];
		
		if ([self isViewLoaded])
			[self refreshView];
	
		[self autorelease];

	});

}

- (void) viewDidUnload {

	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
	[self.imageStackView irRemoveObserverBlocksForKeyPath:@"state"];
	
	self.managedObjectContext = nil;
	self.article = nil;
	self.contextInfoContainer = nil;
	self.imageStackView = nil;
	self.previewBadge = nil;
	self.textEmphasisView = nil;
	self.avatarView = nil;
	self.relativeCreationDateLabel = nil;
	self.userNameLabel = nil;
	self.articleDescriptionLabel = nil;
	self.contextTextView = nil;

	[super viewDidUnload];

}

- (void) dealloc {

	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
	[self.imageStackView irRemoveObserverBlocksForKeyPath:@"state"];

	[managedObjectContext release];
	[article release];
	[onPresentingViewController release];
	[contextInfoContainer release];
	[imageStackView release];
	[previewBadge release];
	[textEmphasisView release];
	[avatarView release];
	[relativeCreationDateLabel release];
	[userNameLabel release];
	[articleDescriptionLabel release];
	[contextTextView release];
	
	[onViewTap release];
	
	[super dealloc];

}

- (void) viewDidLoad {

	__block __typeof__(self) nrSelf = self;	
	__block WAView *nrView = (WAView *)self.view;
	
	[super viewDidLoad];
	[self.view addGestureRecognizer:[[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGlobalTap:)] autorelease]];
	[self.view addGestureRecognizer:[[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleGlobalInspect:)] autorelease]];
	
	//	self.avatarView.layer.cornerRadius = 4.0f;
	self.avatarView.layer.masksToBounds = YES;
	
	UIView *avatarContainingView = [[[UIView alloc] initWithFrame:self.avatarView.frame] autorelease];
	avatarContainingView.autoresizingMask = self.avatarView.autoresizingMask;
	self.avatarView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[self.avatarView.superview insertSubview:avatarContainingView belowSubview:self.avatarView];
	[avatarContainingView addSubview:self.avatarView];
	self.avatarView.center = (CGPoint){ CGRectGetMidX(self.avatarView.superview.bounds), CGRectGetMidY(self.avatarView.superview.bounds) };
	avatarContainingView.layer.shadowPath = [UIBezierPath bezierPathWithRect:avatarContainingView.bounds].CGPath;
	avatarContainingView.layer.shadowOpacity = 0.25f;
	avatarContainingView.layer.shadowOffset = (CGSize){ 0, 1 };
	avatarContainingView.layer.shadowRadius = 1.0f;
	avatarContainingView.layer.borderColor = [UIColor whiteColor].CGColor;
	avatarContainingView.layer.borderWidth = 1.0f;
	
	
	self.imageStackView.delegate = self;	
	[self.imageStackView irAddObserverBlock:^(id inOldValue, id inNewValue, NSString *changeKind) {
	
		WAImageStackViewInteractionState state = WAImageStackViewInteractionNormal;
		[inNewValue getValue:&state];
		
		nrSelf.onPresentingViewController( ^ (UIViewController <WAArticleViewControllerPresenting> *parentViewController) {
			switch (state) {
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
		
	} forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
	
	self.textEmphasisView.frame = (CGRect){ 0, 0, 540, 128 };
	self.textEmphasisView.backgroundView = [[[UIView alloc] initWithFrame:self.textEmphasisView.bounds] autorelease];
	self.textEmphasisView.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	
	UIView *bubbleView = [[[UIView alloc] initWithFrame:self.textEmphasisView.backgroundView.bounds] autorelease];
	bubbleView.layer.contents = (id)[UIImage imageNamed:@"WASpeechBubble"].CGImage;
	bubbleView.layer.contentsCenter = (CGRect){ 80.0/128.0, 32.0/88.0, 1.0/128.0, 8.0/88.0 };
	bubbleView.frame = UIEdgeInsetsInsetRect(bubbleView.frame, (UIEdgeInsets){ -28, -32, -44, -32 });
	bubbleView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[self.textEmphasisView.backgroundView addSubview:bubbleView];
	
	nrView.onLayoutSubviews = ^ {
	
		CGPoint centerOffset = CGPointZero;
	
		CGRect usableRect = UIEdgeInsetsInsetRect(nrSelf.view.bounds, (UIEdgeInsets){ 32, 32, 64, 32 });
		const CGFloat maximumTextWidth = MIN(CGRectGetWidth(usableRect), 480);
		const CGFloat minimumTextWidth = MIN(maximumTextWidth, MAX(CGRectGetWidth(usableRect), 280));
		
		if (usableRect.size.width > maximumTextWidth) {
			usableRect.origin.x += roundf(0.5f * (usableRect.size.width - maximumTextWidth));
			usableRect.size.width = maximumTextWidth;
		}
		usableRect.size.width = MAX(usableRect.size.width, minimumTextWidth);
		
		CGRect textRect = usableRect;
		textRect.size.height = 1;
		nrSelf.textEmphasisView.frame = textRect;
		[nrSelf.textEmphasisView sizeToFit];
		textRect = nrSelf.textEmphasisView.frame;
		textRect.size.height = MIN(textRect.size.height, usableRect.size.height);
		nrSelf.textEmphasisView.frame = textRect;
		
		
		BOOL contextInfoAnchorsPlaintextBubble = NO;
		
		switch (nrSelf.presentationStyle) {
		
			case WAFullFramePlaintextArticleStyle: {
				centerOffset.y -= 0.5f * CGRectGetHeight(nrSelf.contextInfoContainer.frame) + 24;
				contextInfoAnchorsPlaintextBubble = YES;
				//	Fall through
			}
			case WAFullFrameImageStackArticleStyle:
			case WAFullFramePreviewArticleStyle: {
				nrSelf.previewBadge.minimumAcceptibleFullFrameAspectRatio = 0.01f;
				break;
			}
	
			case WADiscretePlaintextArticleStyle:
			case WADiscreteSingleImageArticleStyle:
			case WADiscretePreviewArticleStyle: {
			
				centerOffset.y -= 16;
			
				nrSelf.previewBadge.frame = UIEdgeInsetsInsetRect(nrView.bounds, (UIEdgeInsets){ 0, 0, 32, 0 });
				nrSelf.previewBadge.backgroundView = nil;
				
				[nrSelf.userNameLabel sizeToFit];
				
				[nrSelf.relativeCreationDateLabel sizeToFit];
				nrSelf.relativeCreationDateLabel.frame = (CGRect){
					(CGPoint){
						nrSelf.userNameLabel.frame.origin.x + nrSelf.userNameLabel.frame.size.width + 10,
						nrSelf.userNameLabel.frame.origin.y + 2
					},
					nrSelf.relativeCreationDateLabel.frame.size
				};
				
				[nrSelf.deviceDescriptionLabel sizeToFit];
				nrSelf.deviceDescriptionLabel.frame = (CGRect){
					(CGPoint){
						nrSelf.relativeCreationDateLabel.frame.origin.x + nrSelf.relativeCreationDateLabel.frame.size.width + 10,
						nrSelf.relativeCreationDateLabel.frame.origin.y - 1
					},
					nrSelf.deviceDescriptionLabel.frame.size
				};
				
				break;
			}
			
			default:
				break;
		}
		
		CGPoint center = (CGPoint){
			roundf(CGRectGetMidX(nrView.bounds)),
			roundf(CGRectGetMidY(nrView.bounds))
		};
		
		nrSelf.textEmphasisView.center = irCGPointAddPoint(center, centerOffset);
		nrSelf.textEmphasisView.frame = CGRectIntegral(nrSelf.textEmphasisView.frame);
		
		if (contextInfoAnchorsPlaintextBubble) {
			nrSelf.contextInfoContainer.frame = (CGRect){
				(CGPoint){
					CGRectGetMinX(nrSelf.textEmphasisView.frame),
					CGRectGetMaxY(nrSelf.textEmphasisView.frame) + 32
				},
				nrSelf.contextInfoContainer.frame.size
			};
		}
		
	};
	
	[self refreshView];
		
}

- (void) handleGlobalTap:(UITapGestureRecognizer *)tapRecognizer {

	if (self.onViewTap)
		self.onViewTap();

}

- (void) handleGlobalInspect:(UILongPressGestureRecognizer *)longPressRecognizer {

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
			
				[[[[IRAlertView alloc] initWithTitle:@"Inspect" message:inspectionText delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
				
				NSLog(inspectionText);
			
				objc_setAssociatedObject(nrSelf, &kGlobalInspectActionSheet, nil, OBJC_ASSOCIATION_ASSIGN);
			});
			
		}],
		
	nil]];
	
	objc_setAssociatedObject(self, &kGlobalInspectActionSheet, controller, OBJC_ASSOCIATION_RETAIN);
	
	[(UIActionSheet *)[controller managedActionSheet] showFromRect:self.view.bounds inView:self.view animated:YES];

}

- (void) setArticle:(WAArticle *)newArticle {

	if (article == newArticle)
		return;
	
	[self willChangeValueForKey:@"article"];
	[article release];
	article = [newArticle retain];
	[self didChangeValueForKey:@"article"];
	
	if ([self isViewLoaded])
		[self refreshView];

}

- (void) setPresentationStyle:(WAArticleViewControllerPresentationStyle)newPresentationStyle {

	if (presentationStyle == newPresentationStyle)
		return;
	
	NSParameterAssert(![self isViewLoaded]);
	
	[self willChangeValueForKey:@"presentationStyle"];
	presentationStyle = newPresentationStyle;
	[self didChangeValueForKey:@"presentationStyle"];
	
}

- (void) refreshView {

	self.contextTextView.text = [self description];

	self.userNameLabel.text = self.article.owner.nickname;
	self.relativeCreationDateLabel.text = [[[self class] relativeDateFormatter] stringFromDate:self.article.timestamp];
	self.articleDescriptionLabel.text = self.article.text;
	
	WAPreview *anyPreview = (WAPreview *)[[[self.article.previews allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObjects:
		[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES],
	nil]] lastObject];
	
	[self.previewBadge configureWithPreview:anyPreview];
	
	if (self.imageStackView) {
	
		static NSString * const waArticleViewCOntrollerStackImagePaths = @"waArticleViewCOntrollerStackImagePaths";
		
		NSParameterAssert([self.article.fileOrder count] == [self.article.files count]);
		
		NSArray *allFilePaths = [self.article.fileOrder irMap: ^ (id inObject, int index, BOOL *stop) {
		
			return ((WAFile *)[[self.article.files objectsPassingTest: ^ (WAFile *aFile, BOOL *stop) {		
				return [[[aFile objectID] URIRepresentation] isEqual:inObject];
			}] anyObject]).resourceFilePath;
		
		}];
		
		if ([allFilePaths count] == [self.article.files count]) {
		
			//	TBD it might be totally unnecessaary to wait for all the stuff to load if we can simply show one loaded image
		
			NSArray *existingPaths = objc_getAssociatedObject(self.imageStackView, &waArticleViewCOntrollerStackImagePaths);

			if (!existingPaths || ![existingPaths isEqualToArray:allFilePaths]) {
			
				self.imageStackView.images = [allFilePaths irMap: ^ (NSString *aPath, int index, BOOL *stop) {
					
					UIImage *returnedImage = [UIImage imageWithContentsOfFile:aPath];
					NSParameterAssert(returnedImage);
					
					return returnedImage;
					
				}];
				
				objc_setAssociatedObject(self.imageStackView, &waArticleViewCOntrollerStackImagePaths, allFilePaths, OBJC_ASSOCIATION_RETAIN);
			
			}
			
		} else {
		
			self.imageStackView.images = nil;
		
		}
	
	}

	
	self.avatarView.image = self.article.owner.avatar;
	self.deviceDescriptionLabel.text = [NSString stringWithFormat:@"via %@", self.article.creationDeviceName ? self.article.creationDeviceName : @"an unknown device"];
	
	self.textEmphasisView.text = self.article.text;
	self.textEmphasisView.hidden = ([self.article.files count] != 0);
	
	if (!self.userNameLabel.text)
		self.userNameLabel.text = @"A Certain User";
	
	[self.view setNeedsLayout];
	
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	[CATransaction begin];
	[CATransaction setDisableActions:YES];

	for (UIView *aView in self.imageStackView.subviews) {
	
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
	
		rootView = self.view.window.rootViewController.view;
		
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
					NSParameterAssert(imageStackView == [nrSelf imageStackView]);

					NSParameterAssert(![UIApplication sharedApplication].statusBarHidden);
					
					NSArray *originalImages = [[imageStackView.images retain] autorelease];
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
					
					NSParameterAssert(imageStackView.window);
					
					[imageStackView setImages:tempImages asynchronously:NO withDecodingCompletion: ^ {
						
						NSParameterAssert(imageStackView.firstPhotoView);
						
						imageStackView.firstPhotoView.alpha = 0.0f;
						
						rootView = [UIApplication sharedApplication].keyWindow.rootViewController.view;
						NSParameterAssert(rootView);
						backdropView.frame = rootView.bounds;
						
						fauxView = [[[UIView alloc] initWithFrame:[rootView convertRect:imageStackView.firstPhotoView.frame fromView:imageStackView]] autorelease];
						NSParameterAssert(fauxView);
						fauxView.layer.contents = (id)currentImage.CGImage;
						fauxView.layer.transform = imageStackView.firstPhotoView.layer.transform;
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
							
							imageStackView.firstPhotoView.alpha = 1.0f;
							
							dispatch_after(dispatch_time(DISPATCH_TIME_NOW, animationDuration * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
							
								CATransition *fadeTransition = [CATransition animation];
								fadeTransition.duration = 0.5f * animationDuration;
								fadeTransition.type = kCATransitionFade;
								fadeTransition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
								fadeTransition.fillMode = kCAFillModeForwards;
								fadeTransition.removedOnCompletion = YES;
							
								[CATransaction begin];
							
								[imageStackView setImages:originalImages asynchronously:NO withDecodingCompletion:nil];
								[imageStackView.layer addAnimation:fadeTransition forKey:@"transition"];

								[CATransaction setCompletionBlock: ^ {
								
									//	Handle final completion stuff if appropriate and necessary
									
								}];
								
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





+ (IRRelativeDateFormatter *) relativeDateFormatter {

	static IRRelativeDateFormatter *formatter = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{

		formatter = [[IRRelativeDateFormatter alloc] init];
		formatter.approximationMaxTokenCount = 1;
			
	});

	return formatter;

}

@end
