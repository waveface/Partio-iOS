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

@interface WAArticleViewController () <UIGestureRecognizerDelegate, WAImageStackViewDelegate>

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) WAArticle *article;

- (void) refreshView;

+ (IRRelativeDateFormatter *) relativeDateFormatter;

@end


@implementation WAArticleViewController
@synthesize presentationStyle;
@synthesize managedObjectContext, article;
@synthesize contextInfoContainer, imageStackView, textEmphasisView, avatarView, relativeCreationDateLabel, userNameLabel, articleDescriptionLabel, deviceDescriptionLabel;
@synthesize onPresentingViewController;

+ (WAArticleViewController *) controllerRepresentingArticle:(NSURL *)articleObjectURL {

	NSManagedObjectContext *usedContext = [[WADataStore defaultStore] disposableMOC];
	WAArticle *usedArticle = (WAArticle *)[usedContext irManagedObjectForURI:articleObjectURL];

	NSString *loadedNibName = [NSStringFromClass([self class]) stringByAppendingFormat:@"-%@", ([usedArticle.files count] ? @"Default" : @"Plaintext")];
	
	WAArticleViewController *returnedController = [[[self alloc] initWithNibName:loadedNibName bundle:[NSBundle bundleForClass:[self class]]] autorelease];
	
	returnedController.managedObjectContext = usedContext;
	returnedController.article = usedArticle;
	
	return returnedController;

}

- (NSURL *) representedObjectURI {

	return [[self.article objectID] URIRepresentation];

}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleManagedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
	
	return self;

}

- (void) handleManagedObjectContextDidSave:(NSNotification *)aNotification {

	NSManagedObjectContext *savedContext = (NSManagedObjectContext *)[aNotification object];
	
	if (savedContext == self.managedObjectContext)
		return;
	
	if ([NSThread isMainThread])
		[self retain];
	else
		dispatch_sync(dispatch_get_main_queue(), ^ { [self retain]; });
	
	dispatch_async(dispatch_get_main_queue(), ^ {
	
		[self.managedObjectContext mergeChangesFromContextDidSaveNotification:aNotification];
		[self.managedObjectContext refreshObject:self.article mergeChanges:YES];
		
		if ([self isViewLoaded])
			[self refreshView];
			
		[self autorelease];
	
	});

}

- (void) viewDidUnload {

	[self.imageStackView irRemoveObserverBlocksForKeyPath:@"state"];

	self.contextInfoContainer = nil;
	self.imageStackView = nil;
	self.textEmphasisView = nil;
	self.avatarView = nil;
	self.relativeCreationDateLabel = nil;
	self.userNameLabel = nil;
	self.articleDescriptionLabel = nil;

	[super viewDidUnload];

}

- (void) didReceiveMemoryWarning {

	[self retain];
	[super didReceiveMemoryWarning];
	[self autorelease];

}

- (void) dealloc {

	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
	
	[self.imageStackView irRemoveObserverBlocksForKeyPath:@"state"];

	[managedObjectContext release];
	[article release];
	[onPresentingViewController release];
	
	[contextInfoContainer release];
	[imageStackView release];
	[textEmphasisView release];
	[avatarView release];
	[relativeCreationDateLabel release];
	[userNameLabel release];
	[articleDescriptionLabel release];
	
	[super dealloc];

}

- (void) viewDidLoad {

	[super viewDidLoad];
	
	self.avatarView.layer.cornerRadius = 4.0f;
	self.avatarView.layer.masksToBounds = YES;
	
	UIView *avatarContainingView = [[[UIView alloc] initWithFrame:self.avatarView.frame] autorelease];
	avatarContainingView.autoresizingMask = self.avatarView.autoresizingMask;
	self.avatarView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[self.avatarView.superview insertSubview:avatarContainingView belowSubview:self.avatarView];
	[avatarContainingView addSubview:self.avatarView];
	self.avatarView.center = (CGPoint){ CGRectGetMidX(self.avatarView.superview.bounds), CGRectGetMidY(self.avatarView.superview.bounds) };
	avatarContainingView.layer.shadowPath = [UIBezierPath bezierPathWithRect:avatarContainingView.bounds].CGPath;
	avatarContainingView.layer.shadowOpacity = 0.5f;
	avatarContainingView.layer.shadowOffset = (CGSize){ 0, 1 };
	avatarContainingView.layer.shadowRadius = 2.0f;
	
	self.imageStackView.delegate = self;
	
	__block __typeof__(self) nrSelf = self;
	
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
	self.textEmphasisView.label.font = [UIFont systemFontOfSize:20.0f];
	self.textEmphasisView.backgroundView = [[[UIView alloc] initWithFrame:self.textEmphasisView.bounds] autorelease];
	self.textEmphasisView.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	
	UIImageView *bubbleView = [[[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"WASpeechBubble"] stretchableImageWithLeftCapWidth:84 topCapHeight:32]] autorelease];
	bubbleView.frame = UIEdgeInsetsInsetRect(self.textEmphasisView.backgroundView.bounds, (UIEdgeInsets){ -28, -32, -32, -32 });
	bubbleView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[self.textEmphasisView.backgroundView addSubview:bubbleView];
	
	((WAView *)self.view).onLayoutSubviews = ^ {
	
		id self = (id)0x1; // Disables accidental referencing, and automatic block_retain(), of self
		self = self;
	
		if (nrSelf.textEmphasisView && !nrSelf.textEmphasisView.hidden) {
		
			CGRect usableRect = UIEdgeInsetsInsetRect(nrSelf.view.bounds, (UIEdgeInsets){ 32, 0, 32, 0 });
		
			[nrSelf.textEmphasisView sizeToFit];
			
			switch (nrSelf.presentationStyle) {
				case WAArticleViewControllerPresentationFullFrame: {
					nrSelf.textEmphasisView.frame = (CGRect){
						nrSelf.textEmphasisView.frame.origin,
						(CGSize) {
							MIN(CGRectGetWidth(usableRect) - 54, MAX(256, nrSelf.textEmphasisView.frame.size.width)),
							MIN(CGRectGetHeight(usableRect) - 80, MAX(144 - 32 - 32, nrSelf.textEmphasisView.frame.size.height))
						}
					};
					break;
				}
				case WAArticleViewControllerPresentationStandalone: {
					nrSelf.textEmphasisView.frame = (CGRect){
						nrSelf.textEmphasisView.frame.origin,
						(CGSize) {
							MAX(540, nrSelf.textEmphasisView.frame.size.width),
							MIN(480, MAX(144 - 32 - 32, nrSelf.textEmphasisView.frame.size.height))
						}
					};
					break;
				}
			}
			
			nrSelf.textEmphasisView.center = (CGPoint){
				CGRectGetMidX(usableRect),
				CGRectGetMidY(usableRect)
			};
			nrSelf.textEmphasisView.frame = CGRectIntegral(nrSelf.textEmphasisView.frame);
			
			nrSelf.contextInfoContainer.frame = (CGRect){
				nrSelf.contextInfoContainer.frame.origin,
				(CGSize){
					MIN(CGRectGetWidth(usableRect) - 32, CGRectGetWidth(nrSelf.textEmphasisView.frame)),
					CGRectGetHeight(nrSelf.contextInfoContainer.frame)
				}
			};
			
			nrSelf.contextInfoContainer.center = (CGPoint){
				CGRectGetMidX(usableRect),
				CGRectGetMidY(usableRect) + 0.5f * CGRectGetHeight(nrSelf.textEmphasisView.frame) + CGRectGetHeight(nrSelf.contextInfoContainer.frame) + 10.0f
			};			
			
			CGRect actualContentRect = CGRectUnion(
				nrSelf.textEmphasisView.frame, 
				nrSelf.contextInfoContainer.frame
			);
			CGFloat delta = roundf(0.5f * (CGRectGetHeight(usableRect) - CGRectGetHeight(actualContentRect))) - CGRectGetMinY(nrSelf.textEmphasisView.frame);
			nrSelf.textEmphasisView.frame = CGRectOffset(
				nrSelf.textEmphasisView.frame, 
				usableRect.origin.x,
				usableRect.origin.y + delta
			);
			nrSelf.contextInfoContainer.frame = CGRectOffset(
				nrSelf.contextInfoContainer.frame,
				usableRect.origin.x,
				usableRect.origin.y + delta
			);
			
			[nrSelf.relativeCreationDateLabel sizeToFit];
			
			nrSelf.deviceDescriptionLabel.frame = (CGRect){
				(CGPoint){
					CGRectGetMaxX(nrSelf.relativeCreationDateLabel.frame) + 10,
					nrSelf.deviceDescriptionLabel.frame.origin.y
				},
				nrSelf.deviceDescriptionLabel.frame.size
			};
						
		} else {
		
			nrSelf.imageStackView.frame = UIEdgeInsetsInsetRect(nrSelf.view.bounds, (UIEdgeInsets){ 0, 0, 12 + CGRectGetHeight(nrSelf.contextInfoContainer.frame), 0 });
		
			nrSelf.contextInfoContainer.frame = (CGRect){
				(CGPoint){
					0,
					CGRectGetHeight(nrSelf.view.bounds) - CGRectGetHeight(nrSelf.contextInfoContainer.frame) - 8
				},
				(CGSize){
					CGRectGetWidth(nrSelf.view.bounds),
					nrSelf.contextInfoContainer.frame.size.height
				}
			};
		
			[nrSelf.relativeCreationDateLabel sizeToFit];
			nrSelf.relativeCreationDateLabel.frame = (CGRect){
				(CGPoint) {
					CGRectGetWidth(
						nrSelf.relativeCreationDateLabel.superview.frame
					) - CGRectGetWidth(
						nrSelf.relativeCreationDateLabel.frame
					) - 32,
					nrSelf.relativeCreationDateLabel.frame.origin.y
				},
				nrSelf.relativeCreationDateLabel.frame.size
			};
			
			nrSelf.deviceDescriptionLabel.frame = (CGRect){
				(CGPoint){
					nrSelf.relativeCreationDateLabel.frame.origin.x - CGRectGetWidth(
						nrSelf.deviceDescriptionLabel.frame
					) - 10,
					nrSelf.deviceDescriptionLabel.frame.origin.y
				},
				nrSelf.deviceDescriptionLabel.frame.size
			};
		
		}
		
	};
	
	[self refreshView];
		
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
	
	[self willChangeValueForKey:@"presentationStyle"];
	presentationStyle = newPresentationStyle;
	[self didChangeValueForKey:@"presentationStyle"];
	
	if ([self isViewLoaded])
		[self.view setNeedsLayout];

}

- (void) refreshView {

	self.userNameLabel.text = self.article.owner.nickname;
	self.relativeCreationDateLabel.text = [[[self class] relativeDateFormatter] stringFromDate:self.article.timestamp];
	self.articleDescriptionLabel.text = self.article.text;
	
	
	if (self.imageStackView) {
	
		static NSString * const waArticleViewCOntrollerStackImagePaths = @"waArticleViewCOntrollerStackImagePaths";
		
		NSArray *allFilePaths = [self.article.fileOrder irMap: ^ (id inObject, int index, BOOL *stop) {
		
			return ((WAFile *)[[self.article.files objectsPassingTest: ^ (WAFile *aFile, BOOL *stop) {		
				return [[[aFile objectID] URIRepresentation] isEqual:inObject];
			}] anyObject]).resourceFilePath;
		
		}];
		
		if ([allFilePaths count] == [self.article.files count]) {
		
			NSArray *existingPaths = objc_getAssociatedObject(self.imageStackView, &waArticleViewCOntrollerStackImagePaths);

			if (!existingPaths || ![existingPaths isEqualToArray:allFilePaths]) {

				self.imageStackView.images = [allFilePaths irMap: ^ (NSString *aPath, int index, BOOL *stop) {
					
					return [UIImage imageWithContentsOfFile:aPath];
					
				}];
				
				objc_setAssociatedObject(self.imageStackView, &waArticleViewCOntrollerStackImagePaths, allFilePaths, OBJC_ASSOCIATION_RETAIN);
			
			}
		
		} else {
		
			self.imageStackView.images = nil;
		
		}
	
	}

	
	self.avatarView.image = self.article.owner.avatar;
	self.deviceDescriptionLabel.text = [NSString stringWithFormat:@"via %@", self.article.creationDeviceName ? self.article.creationDeviceName : @"an unknown device"];
	
	self.textEmphasisView.label.text = self.article.text;
	self.textEmphasisView.hidden = ([self.article.files count] != 0);
	
	if (!self.userNameLabel.text)
		self.userNameLabel.text = @"A Certain User";
	
	[self.view setNeedsLayout];
	
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	for (UIView *aView in self.imageStackView.subviews) {
	
		CGPathRef oldShadowPath = aView.layer.shadowPath;

		if (oldShadowPath) {
			CFRetain(oldShadowPath);
			[aView.layer addAnimation:((^ {
				CABasicAnimation *transition = [CABasicAnimation animationWithKeyPath:@"shadowPath"];
				transition.fromValue = (id)oldShadowPath;
				transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
				transition.duration = duration;
				return transition;
			})()) forKey:@"transition"];
			CFRelease(oldShadowPath);
		}
	
	}
		
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
				galleryViewController.modalPresentationStyle = UIModalPresentationFullScreen;
				galleryViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
				
				galleryViewController.onDismiss = ^ {
					
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
					
					[imageStackView setImages:tempImages asynchronously:YES withDecodingCompletion: ^ {
					
						[galleryViewController dismissModalViewControllerAnimated:NO];
						NSParameterAssert(imageStackView.window);
						
						imageStackView.firstPhotoView.alpha = 0.0f;
						
						rootView = [UIApplication sharedApplication].keyWindow.rootViewController.view;
						NSParameterAssert(rootView);
						backdropView.frame = rootView.bounds;
						
						fauxView = [[[UIView alloc] initWithFrame:[rootView convertRect:imageStackView.firstPhotoView.frame fromView:aStackView]] autorelease];
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
