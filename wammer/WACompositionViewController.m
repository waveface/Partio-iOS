//
//  WACompositionViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WACompositionViewController.h"
#import "WADataStore.h"
#import "IRImagePickerController.h"
#import "IRConcaveView.h"
#import "IRActionSheetController.h"
#import "IRActionSheet.h"
#import "WACompositionViewPhotoCell.h"
#import "WANavigationBar.h"
#import "WANavigationController.h"
#import "IRLifetimeHelper.h"
#import "IRBarButtonItem.h"

#import "UIWindow+IRAdditions.h"
#import "WADefines.h"

#import "AssetsLibrary+IRAdditions.h"
#import "IRTextAttributor.h"


@interface WACompositionViewController () <AQGridViewDelegate, AQGridViewDataSource, UITextViewDelegate>

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) WAArticle *article;
@property (nonatomic, readwrite, retain) UIPopoverController *imagePickerPopover;

@property (nonatomic, readwrite, copy) void (^completionBlock)(NSURL *returnedURI);

- (void) handleCurrentArticleFilesChangedFrom:(id)fromValue to:(id)toValue changeKind:(NSString *)changeKind;
- (void) handleIncomingSelectedAssetURI:(NSURL *)aFileURL representedAsset:(ALAsset *)photoLibraryAsset;

- (void) adjustPhotos;

@property (nonatomic, readwrite, retain) IRTextAttributor *textAttributor;
@property (nonatomic, readwrite, retain) NSMutableAttributedString *backingContentText;

@end


@implementation WACompositionViewController

@synthesize managedObjectContext, article;
@synthesize containerView;
@synthesize photosView, contentTextView, toolbar;
@synthesize imagePickerPopover;
@synthesize noPhotoReminderView;
@synthesize completionBlock;
@synthesize usesTransparentBackground;
@synthesize noPhotoReminderViewElements;

@synthesize textAttributor;
@synthesize backingContentText;

+ (WACompositionViewController *) controllerWithArticle:(NSURL *)anArticleURLOrNil completion:(void(^)(NSURL *anArticleURLOrNil))aBlock {

	WACompositionViewController *returnedController = [[[self alloc] init] autorelease];
	
	returnedController.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
	
	if (anArticleURLOrNil)
		returnedController.article = (WAArticle *)[returnedController.managedObjectContext irManagedObjectForURI:anArticleURLOrNil];
	
	if (!returnedController.article) {
		returnedController.article = [WAArticle objectInsertingIntoContext:returnedController.managedObjectContext withRemoteDictionary:[NSDictionary dictionary]];
		returnedController.article.draft = [NSNumber numberWithBool:YES];
	}
	
	returnedController.completionBlock = aBlock;
	
	return returnedController;
	
}

- (id) init {

	return [self initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]];

}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if (!self)
		return nil;
	
	self.title = @"Compose";
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(handleCancel:)] autorelease];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(handleDone:)] autorelease];
	
	return self;

}

- (void) setArticle:(WAArticle *)newArticle {

	__block __typeof__(self) nrSelf = self;

	[self willChangeValueForKey:@"article"];
	
	[article irRemoveObserverBlocksForKeyPath:@"files"];	
	[newArticle irAddObserverBlock:^(id inOldValue, id inNewValue, NSString *changeKind) {
		[nrSelf handleCurrentArticleFilesChangedFrom:inOldValue to:inNewValue changeKind:changeKind];
	} forKeyPath:@"fileOrder" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];	
	
	[article release];
	article = [newArticle retain];
	
	[self didChangeValueForKey:@"article"];

}

- (void) dealloc {

	[containerView release];
	
	[photosView release];
	[contentTextView release];
	[noPhotoReminderView release];
	[toolbar release];
	[noPhotoReminderViewElements release];

	[article irRemoveObserverBlocksForKeyPath:@"fileOrder"];
	
	[managedObjectContext release];
	[article release];
	[imagePickerPopover release];
	
	[completionBlock release];
	
	[textAttributor release];
	[backingContentText release];
	
	[super dealloc];

}

- (void) viewDidUnload {

	self.containerView = nil;
	
	self.photosView = nil;
	self.noPhotoReminderView = nil;
	self.contentTextView.delegate = nil;
	self.contentTextView = nil;
	self.toolbar = nil;
	self.imagePickerPopover = nil;
	self.noPhotoReminderViewElements = nil;

	[super viewDidUnload];

}





- (void) viewDidLoad {

	[super viewDidLoad];
	
	
	if (self.usesTransparentBackground) {
		self.view.backgroundColor = nil;
		self.view.opaque = NO;
	} else {
		self.view.backgroundColor = [UIColor colorWithWhite:0.98f alpha:1.0f];
	}
	
	if ([[UIDevice currentDevice].name rangeOfString:@"Simulator"].location != NSNotFound) {
		self.contentTextView.autocorrectionType = UITextAutocorrectionTypeNo;
	}
	self.contentTextView.delegate = self;
	self.contentTextView.text = self.article.text;
	[self textViewDidChange:self.contentTextView];
	
	self.toolbar.opaque = NO;
	self.toolbar.backgroundColor = [UIColor clearColor];
	
	UIView *photosViewWrapper = [[[UIView alloc] initWithFrame:self.photosView.frame] autorelease];
	photosViewWrapper.autoresizingMask = self.photosView.autoresizingMask;
	photosViewWrapper.clipsToBounds = NO;
	[self.photosView.superview addSubview:photosViewWrapper];
	[photosViewWrapper addSubview:self.photosView];	
	self.photosView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.photosView.frame = self.photosView.superview.bounds;
	
	self.photosView.layoutDirection = AQGridViewLayoutDirectionHorizontal;
	self.photosView.backgroundColor = nil;
	self.photosView.opaque = NO;
	self.photosView.bounces = YES;
	self.photosView.clipsToBounds = NO;
	self.photosView.alwaysBounceHorizontal = YES;
	self.photosView.alwaysBounceVertical = NO;
	self.photosView.directionalLockEnabled = YES;
	self.photosView.contentSizeGrowsToFillBounds = NO;
	self.photosView.showsVerticalScrollIndicator = NO;
	self.photosView.showsHorizontalScrollIndicator = NO;
	self.photosView.leftContentInset = 56.0f;
		
	CAGradientLayer *rightGradientMask = [CAGradientLayer layer];
	rightGradientMask.startPoint = irUnitPointForAnchor(irLeft, YES);
	rightGradientMask.endPoint = irUnitPointForAnchor(irRight, YES);
	rightGradientMask.colors = [NSArray arrayWithObjects:
		(id)[UIColor colorWithRed:1 green:1 blue:1 alpha:1].CGColor,
		(id)[UIColor colorWithRed:0 green:0 blue:0 alpha:0].CGColor,
	nil];
	rightGradientMask.locations = [NSArray arrayWithObjects:
		[NSNumber numberWithFloat:1-(20.0f / CGRectGetWidth(self.photosView.frame))],
		[NSNumber numberWithFloat:1],
	nil];
	photosViewWrapper.layer.mask = rightGradientMask;
	photosViewWrapper.layer.mask.anchorPoint = irUnitPointForAnchor(irTopLeft, YES);
	photosViewWrapper.layer.mask.bounds = photosViewWrapper.bounds;
	
	self.noPhotoReminderView.frame = UIEdgeInsetsInsetRect(self.photosView.frame, (UIEdgeInsets){ 0, 0, 0, -32 });
	self.noPhotoReminderView.autoresizingMask = self.photosView.autoresizingMask;
	
	for (UIView *aSubview in self.noPhotoReminderViewElements) {
		if ([aSubview isKindOfClass:[UIView class]]) {
			aSubview.layer.shadowColor = [UIColor colorWithWhite:1 alpha:1].CGColor;
			aSubview.layer.shadowOffset = (CGSize){ 0, 1 };
			aSubview.layer.shadowRadius = 0;
			aSubview.layer.shadowOpacity = .5;
		}
	}
	
	[self.photosView.superview insertSubview:self.noPhotoReminderView aboveSubview:self.photosView];
	
	//	UIView *photosBackgroundView = [[[UIView alloc] initWithFrame:self.photosView.frame] autorelease];
	//	photosBackgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPhotoQueueBackground"]];
	//	photosBackgroundView.autoresizingMask = self.photosView.autoresizingMask;
	//	photosBackgroundView.frame = UIEdgeInsetsInsetRect(photosBackgroundView.frame, (UIEdgeInsets){ -20, -20, -40, -20 });
	//	photosBackgroundView.layer.masksToBounds = YES;
	//	photosBackgroundView.userInteractionEnabled = NO;
	//	[self.view insertSubview:photosBackgroundView atIndex:0];
	
	//	IRConcaveView *photosConcaveEdgeView = [[[IRConcaveView alloc] initWithFrame:self.photosView.frame] autorelease];
	//	photosConcaveEdgeView.autoresizingMask = self.photosView.autoresizingMask;
	//	photosConcaveEdgeView.backgroundColor = nil;
	//	photosConcaveEdgeView.frame = UIEdgeInsetsInsetRect(photosConcaveEdgeView.frame, (UIEdgeInsets){ -20, -20, -40, -20 });
	//	photosConcaveEdgeView.innerShadow = [IRShadow shadowWithColor:[UIColor colorWithWhite:0.0f alpha:0.5f] offset:(CGSize){ 0.0f, -1.0f } spread:3.0f];
	//	photosConcaveEdgeView.layer.masksToBounds = YES;
	//	photosConcaveEdgeView.userInteractionEnabled = NO;
	//	[self.view addSubview:photosConcaveEdgeView];
	
	self.photosView.contentInset = (UIEdgeInsets){ 0, 20, 42, 20 };
	objc_setAssociatedObject(self.photosView, @"defaultInsets", [NSValue valueWithUIEdgeInsets:self.photosView.contentInset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	self.photosView.frame = UIEdgeInsetsInsetRect(self.photosView.frame, (UIEdgeInsets){ 0, -20, -42, -20 });
	
	self.contentTextView.backgroundColor = nil;
	self.contentTextView.opaque = NO;
	self.contentTextView.contentInset = (UIEdgeInsets){ 4, 0, 0, 0 };
	self.contentTextView.bounces = YES;
	self.contentTextView.alwaysBounceVertical = YES;
	
	UIView *contextTextShadowView = [[[UIView alloc] initWithFrame:self.contentTextView.frame] autorelease];
	contextTextShadowView.autoresizingMask = self.contentTextView.autoresizingMask;
	contextTextShadowView.layer.shadowOffset = (CGSize){ 0, 2 };
	contextTextShadowView.layer.shadowRadius = 2;
	contextTextShadowView.layer.shadowOpacity = 0.25;
	contextTextShadowView.layer.cornerRadius = 4;
	contextTextShadowView.layer.backgroundColor = [UIColor blackColor].CGColor;
	[self.contentTextView.superview insertSubview:contextTextShadowView belowSubview:self.contentTextView];
	
	IRConcaveView *contentTextBackgroundView = [[[IRConcaveView alloc] initWithFrame:self.contentTextView.frame] autorelease];
	contentTextBackgroundView.autoresizingMask = self.contentTextView.autoresizingMask;
	contentTextBackgroundView.innerShadow = [IRShadow shadowWithColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.25] offset:(CGSize){ 0, 2 } spread:4];
	contentTextBackgroundView.userInteractionEnabled = NO;
	contentTextBackgroundView.backgroundColor = [UIColor colorWithWhite:0.97f alpha:1];
	contentTextBackgroundView.layer.cornerRadius = 4;
	contentTextBackgroundView.layer.masksToBounds = YES;
	[self.contentTextView.superview insertSubview:contentTextBackgroundView belowSubview:self.contentTextView];
	
}


static NSString * const kWACompositionViewWindowInterfaceBoundsNotificationHandler = @"kWACompositionViewWindowInterfaceBoundsNotificationHandler";

- (void) viewDidAppear:(BOOL)animated {

	[super viewDidAppear:animated];
	
	id notificationObject = [[NSNotificationCenter defaultCenter] addObserverForName:IRWindowInterfaceBoundsDidChangeNotification object:self.view.window queue:nil usingBlock:^(NSNotification *aNotification) {
	
		NSDictionary *userInfo = [aNotification userInfo];
		CGRect newBounds = [[userInfo objectForKey:IRWindowInterfaceChangeNewBoundsKey] CGRectValue];
		
		NSDictionary *keyboardInfo = [[userInfo objectForKey:IRWindowInterfaceChangeUnderlyingKeyboardNotificationKey] userInfo];
		
		UIViewAnimationCurve animationCurve = [[keyboardInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] unsignedIntValue];
		NSTimeInterval animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
		
		UIViewAnimationOptions animationOptions = 0;
		animationOptions |= ((^ {
			switch (animationCurve) {
				case UIViewAnimationCurveEaseIn: return UIViewAnimationOptionCurveEaseIn;
				case UIViewAnimationCurveEaseOut:return UIViewAnimationOptionCurveEaseOut;
				case UIViewAnimationCurveEaseInOut: return UIViewAnimationOptionCurveEaseInOut;
				case UIViewAnimationCurveLinear: return UIViewAnimationOptionCurveLinear;
				default: return 0;
			}
		})());
	
		[UIView animateWithDuration:animationDuration delay:0 options:animationOptions animations:^{

			[self adjustContainerViewWithInterfaceBounds:newBounds];
			
		} completion:nil];
		
	}];
	
	objc_setAssociatedObject(self, &kWACompositionViewWindowInterfaceBoundsNotificationHandler, notificationObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	dispatch_async(dispatch_get_main_queue(), ^ {
	
		[self.contentTextView becomeFirstResponder];
	
	});
	
}

- (void) viewWillDisappear:(BOOL)animated {

	[super viewWillDisappear:animated];
	
	id notificationObject = objc_getAssociatedObject(self, &kWACompositionViewWindowInterfaceBoundsNotificationHandler);
	[[NSNotificationCenter defaultCenter] removeObserver:notificationObject];
	objc_setAssociatedObject(self, &kWACompositionViewWindowInterfaceBoundsNotificationHandler, nil, OBJC_ASSOCIATION_ASSIGN);

}

- (void) adjustContainerViewWithInterfaceBounds:(CGRect)newBounds {

	if (![self isViewLoaded])
		return;
	
	UIWindow *ownWindow = self.view.window;
	if (!ownWindow) {
		self.containerView.frame = self.view.bounds;
		return;
	}
	
	CGRect usableRectInWindow = newBounds;
	CGRect fullViewRectInWindow = [ownWindow convertRect:self.view.bounds fromView:self.view];
	CGRect overlappingRectInWindow = CGRectIntersection(fullViewRectInWindow, usableRectInWindow);
	
	CGRect usableRect = [ownWindow convertRect:overlappingRectInWindow toView:self.view];
	self.containerView.frame = usableRect;

}





- (void) textViewDidChange:(UITextView *)textView {

	self.navigationItem.rightBarButtonItem.enabled = (BOOL)!![[self.contentTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length];

}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {

	if (scrollView != self.photosView)
		return;
	
	self.photosView.contentOffset = (CGPoint){
		self.photosView.contentOffset.x,
		0
	};

}

- (CGSize) portraitGridCellSizeForGridView: (AQGridView *) gridView {

	return (CGSize){ 144, CGRectGetHeight(gridView.frame) - 1 };

}

- (NSUInteger) numberOfItemsInGridView:(AQGridView *)gridView {

	return [self.article.fileOrder count];

}

- (AQGridViewCell *) gridView:(AQGridView *)gridView cellForItemAtIndex:(NSUInteger)index {

	static NSString * const identifier = @"photoCell";
	
	WACompositionViewPhotoCell *cell = (WACompositionViewPhotoCell *)[gridView dequeueReusableCellWithIdentifier:identifier];
	WAFile *representedFile = (WAFile *)[[self.article.files objectsPassingTest: ^ (WAFile *aFile, BOOL *stop) {
		return [[[aFile objectID] URIRepresentation] isEqual:[self.article.fileOrder objectAtIndex:index]];
	}] anyObject];
	
	if (!cell) {
	
		cell = [WACompositionViewPhotoCell cellRepresentingFile:representedFile reuseIdentifier:identifier];
		cell.frame = (CGRect){
			CGPointZero,
			[self portraitGridCellSizeForGridView:gridView]
		};
				
	}
	
	cell.alpha = 1;
		
	cell.image = representedFile.thumbnail;

	cell.onRemove = ^ {
	
		[UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
		
			cell.alpha = 0;
		
		} completion: ^ (BOOL finished) {
		
			dispatch_async(dispatch_get_main_queue(), ^ {
				
				[representedFile.article removeFilesObject:representedFile];
				
			});
			
		}];
	
	};
	
	return cell;

}

- (void) handleCurrentArticleFilesChangedFrom:(NSArray *)fromValue to:(NSArray *)toValue changeKind:(NSString *)changeKind {

	dispatch_async(dispatch_get_main_queue(), ^ {
	
		if (![self isViewLoaded])
			return;
			
		@try {
		
			self.noPhotoReminderView.hidden = ([self.article.fileOrder count] > 0);
		
		} @catch (NSException *e) {
		
			self.noPhotoReminderView.hidden = YES;
		
			if (![e.name isEqualToString:NSObjectInaccessibleException])
				@throw e;
			
    } @finally {
		
			dispatch_async(dispatch_get_main_queue(), ^ {
			
				NSArray *removedObjects = [fromValue filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
					return ![toValue containsObject:evaluatedObject];
				}]];
				
				NSIndexSet *removedObjectIndices = [fromValue indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
					return [removedObjects containsObject:obj];
				}];
				
				NSArray *insertedObjects = [toValue filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
					return ![fromValue containsObject:evaluatedObject];
				}]];
				
				BOOL hasCellNumberChanges = ([insertedObjects count] || [removedObjects count]);
				
				CGPoint oldOffset = self.photosView.contentOffset;
				
				NSIndexSet *oldShownCellIndices = [self.photosView visibleCellIndices];
				NSMutableArray *oldShownCellRects = [NSMutableArray array];
				[oldShownCellIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
						[oldShownCellRects addObject:[NSValue valueWithCGRect:[self.photosView rectForItemAtIndex:idx]]];
				}];
				
				void (^reload)() = ^ {
					[self.photosView reloadData];
					[self adjustPhotos];
				};
				
				if (!hasCellNumberChanges) {
					reload();
					[self.photosView setContentOffset:oldOffset animated:NO];
					return;
				}
				
				NSMutableDictionary *oldFileURIsToCellRects = [NSMutableDictionary dictionary];
				[oldShownCellIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
					[oldFileURIsToCellRects setObject:[NSValue valueWithCGRect:[self.photosView rectForItemAtIndex:idx]] forKey:[fromValue objectAtIndex:idx]];
				}];
				
				reload();
				
				NSUInteger shownCenterItemIndex = (self.photosView.numberOfItems - 1);
				shownCenterItemIndex = (unsigned int)fabsf(ceilf(((float_t)self.photosView.numberOfItems / (float_t)2)));
				
				if ([removedObjectIndices count])
					shownCenterItemIndex = [removedObjectIndices firstIndex];
				
				if ([insertedObjects count])
					shownCenterItemIndex = (self.photosView.numberOfItems - 1);
				
				shownCenterItemIndex = MIN(self.photosView.numberOfItems, shownCenterItemIndex);
				
				CGRect newLastItemRect = (CGRect) {
					[self.photosView rectForItemAtIndex:shownCenterItemIndex].origin,
					[self portraitGridCellSizeForGridView:self.photosView]
				};
				
				[self.photosView scrollRectToVisible:newLastItemRect animated:NO];
				CGPoint newOffset = self.photosView.contentOffset;
				
				NSMutableArray *animationBlocks = [NSMutableArray array];
				[animationBlocks irEnqueueBlock:^{
					[self.photosView setContentOffset:newOffset animated:NO];;
				}];
				
				NSIndexSet *newShownCellIndices = [self.photosView visibleCellIndices];
				NSMutableDictionary *newFileURIsToCellRects = [NSMutableDictionary dictionary];
				[newShownCellIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
					[newFileURIsToCellRects setObject:[NSValue valueWithCGRect:[self.photosView rectForItemAtIndex:idx]] forKey:[toValue objectAtIndex:idx]];
				}];
				
				[animationBlocks irEnqueueBlock:^{
					
					[newShownCellIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
						
						NSValue *oldRectValue = [oldFileURIsToCellRects objectForKey:[toValue objectAtIndex:idx]];
						if (!oldRectValue)
							return;
						
						AQGridViewCell *cell = [self.photosView cellForItemAtIndex:idx];
						if (!cell)
							return;
						
						CGRect cellFrame = cell.frame;
						
						[self.photosView cellForItemAtIndex:idx].layer.frame = [oldRectValue CGRectValue];
						cell.frame = cellFrame;
						
					}];
					
				}];
				
				[self.photosView setContentOffset:oldOffset animated:NO];
				
				[UIView animateWithDuration:0.5f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
					
					[animationBlocks irExecuteAllObjectsAsBlocks];
									
				} completion:nil];
					
			});
		
		}
		
	});

}

- (void) adjustPhotos {

	UIEdgeInsets insets = [objc_getAssociatedObject(self.photosView, @"defaultInsets") UIEdgeInsetsValue];
	CGFloat addedPadding = roundf(0.5f * MAX(0, CGRectGetWidth(self.photosView.frame) - insets.left - insets.right - self.photosView.contentSize.width));
	insets.left += addedPadding;
	
	self.photosView.contentInset = insets;

}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
	[self adjustPhotos];

}





//	Deleting all the changed stuff and saving is like throwing all the stuff away
//	In that sense just don’t do anything.

- (void) handleDone:(UIBarButtonItem *)sender {

	//	TBD save a draft
	
	self.article.text = self.contentTextView.text;
	
	NSError *savingError = nil;
	if (![self.managedObjectContext save:&savingError])
		NSLog(@"Error saving: %@", savingError);
	
	if (self.completionBlock)
		self.completionBlock([[self.article objectID] URIRepresentation]);

}	

- (void) handleCancel:(UIBarButtonItem *)sender {

	if (self.completionBlock)
		self.completionBlock(nil);

}

- (IBAction) handleCameraItemTap:(UIButton *)sender {
	
	__block __typeof__(self) nrSelf = self;
	
	NSMutableArray *availableActions = [NSMutableArray arrayWithObject:[IRAction actionWithTitle:@"Photo Library" block: ^ {
		
		//	nrSelf.imagePickerPopover = nil;
		[nrSelf.imagePickerPopover presentPopoverFromRect:sender.bounds inView:sender permittedArrowDirections:UIPopoverArrowDirectionLeft|UIPopoverArrowDirectionRight animated:YES];
		
	}]];
	
	if ([IRImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
	
		[availableActions addObject:[IRAction actionWithTitle:@"Take Photo" block: ^ {
			
			[nrSelf presentModalViewController:[IRImagePickerController cameraImageCapturePickerWithCompletionBlock:^(NSURL *selectedAssetURI, ALAsset *representedAsset) {
				[nrSelf handleIncomingSelectedAssetURI:selectedAssetURI representedAsset:representedAsset];
			}] animated:YES];
			
		}]];
		
	}
	
	if ([availableActions count] == 1) {
		
		//	With only one action we don’t even need to show the action sheet
		
		dispatch_async(dispatch_get_main_queue(), ^ {
			[(IRAction *)[availableActions objectAtIndex:0] invoke];
		});
		
	} else {
	
		[(IRActionSheet *)[[IRActionSheetController actionSheetControllerWithTitle:nil cancelAction:nil destructiveAction:nil otherActions:availableActions] singleUseActionSheet] showFromRect:sender.bounds inView:sender animated:YES];
		
	}
	
}

- (UIPopoverController *) imagePickerPopover {

	if (imagePickerPopover)
		return imagePickerPopover;
		
	__block __typeof__(self) nrSelf = self;
	
	//	If you have a lot of stuff, but only in the saved photos album — no other albums exist, we will simply show 
		
	IRImagePickerController *imagePickerController = [IRImagePickerController photoLibraryPickerWithCompletionBlock:^(NSURL *selectedAssetURI, ALAsset *representedAsset) {
		
		[nrSelf handleIncomingSelectedAssetURI:selectedAssetURI representedAsset:representedAsset];
		
	}];
	
	self.imagePickerPopover = [[[UIPopoverController alloc] initWithContentViewController:imagePickerController] autorelease];
	
	return imagePickerPopover;

}

- (void) handleIncomingSelectedAssetURI:(NSURL *)selectedAssetURI representedAsset:(ALAsset *)representedAsset {
	
	if (selectedAssetURI || representedAsset) {

		WAArticle *capturedArticle = self.article;
		WAFile *stitchedFile = (WAFile *)[WAFile objectInsertingIntoContext:self.managedObjectContext withRemoteDictionary:[NSDictionary dictionary]];
		stitchedFile.article = capturedArticle;
		
		//	Create a new file entity, associate it, but leave NO photo in it
		
		dispatch_async(dispatch_get_global_queue(0, 0), ^ {
		
			NSURL *finalFileURL = nil;
				
			if (selectedAssetURI)
				finalFileURL = [[WADataStore defaultStore] persistentFileURLForFileAtURL:selectedAssetURI];
			
			if (!finalFileURL)
			if (!selectedAssetURI && representedAsset) {
			
				UIImage *fullImage = [[representedAsset defaultRepresentation] irImage];
				NSData *fullImageData = UIImagePNGRepresentation(fullImage);
				
				finalFileURL = [[WADataStore defaultStore] persistentFileURLForData:fullImageData extension:@"png"];
				
			}
				
			dispatch_async(dispatch_get_main_queue(), ^ {			
				
				[stitchedFile.article willChangeValueForKey:@"fileOrder"];
				
				stitchedFile.resourceType = (NSString *)kUTTypeImage;
				stitchedFile.resourceURL = [finalFileURL absoluteString];
				stitchedFile.resourceFilePath = [finalFileURL path];
				
				[stitchedFile.article didChangeValueForKey:@"fileOrder"];
				
			});
			
		});
		
	}
	
	[self.modalViewController dismissModalViewControllerAnimated:YES];
	
	if ([imagePickerPopover isPopoverVisible])
		[imagePickerPopover dismissPopoverAnimated:YES];
	
	//	self.imagePickerPopover = nil;
	
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	return YES;
	
}

@end
