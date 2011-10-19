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


@interface WACompositionViewController () <AQGridViewDelegate, AQGridViewDataSource, UITextViewDelegate>

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) WAArticle *article;
@property (nonatomic, readwrite, retain) UIPopoverController *imagePickerPopover;

@property (nonatomic, readwrite, copy) void (^completionBlock)(NSURL *returnedURI);
@property (nonatomic, readwrite, assign) BOOL usesTransparentBackground;

- (void) handleCurrentArticleFilesChangedFrom:(id)fromValue to:(id)toValue changeKind:(NSString *)changeKind;
- (void) handleIncomingSelectedAssetURI:(NSURL *)aFileURL representedAsset:(ALAsset *)photoLibraryAsset;

- (void) adjustPhotos;

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
	
	self.photosView.layoutDirection = AQGridViewLayoutDirectionHorizontal;
	self.photosView.backgroundColor = nil;
	self.photosView.layer.cornerRadius = 4.0f;
	self.photosView.opaque = NO;
	self.photosView.bounces = YES;
	self.photosView.clipsToBounds = NO;
	self.photosView.alwaysBounceHorizontal = YES;
	self.photosView.alwaysBounceVertical = NO;
	self.photosView.directionalLockEnabled = YES;
	self.photosView.contentSizeGrowsToFillBounds = NO;
	self.photosView.showsVerticalScrollIndicator = NO;
	self.photosView.showsHorizontalScrollIndicator = NO;
	self.photosView.leftContentInset = 8.0f;
	
	self.noPhotoReminderView.frame = self.photosView.frame;
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

	return (CGSize){ 144, 144 - 1 };

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
		
	cell.image = [UIImage imageWithContentsOfFile:representedFile.resourceFilePath];

	cell.onRemove = ^ {	
		dispatch_async(dispatch_get_main_queue(), ^ {
			[representedFile.article removeFilesObject:representedFile];
		});
	};
	
	return cell;

}

- (void) handleCurrentArticleFilesChangedFrom:(id)fromValue to:(id)toValue changeKind:(NSString *)changeKind {

	NSLog(@"did change from %@ to %@ with kind %@", fromValue, toValue, changeKind);
	
	//	The idea is to animate removals and insertions using AQGridView’s own animation if possible

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
		
				[self.photosView reloadData];
				
				[self adjustPhotos];
								
				CGRect cellRect = [self.photosView rectForItemAtIndex:(self.photosView.numberOfItems - 1)];
				cellRect.size = [self portraitGridCellSizeForGridView:self.photosView];
				
				[self.photosView scrollRectToVisible:cellRect animated:YES];
			
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
		
		nrSelf.imagePickerPopover = nil;
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
		
	IRImagePickerController *imagePickerController = [IRImagePickerController photoLibraryPickerWithCompletionBlock:^(NSURL *selectedAssetURI, ALAsset *representedAsset) {
		
		[nrSelf handleIncomingSelectedAssetURI:selectedAssetURI representedAsset:representedAsset];
		
	}];
	
	self.imagePickerPopover = [[[UIPopoverController alloc] initWithContentViewController:imagePickerController] autorelease];
	
	return imagePickerPopover;

}

- (void) handleIncomingSelectedAssetURI:(NSURL *)selectedAssetURI representedAsset:(ALAsset *)representedAsset {
	
	if (selectedAssetURI || representedAsset) {

		NSURL *finalFileURL = nil;
		
		if (selectedAssetURI)
			finalFileURL = [[WADataStore defaultStore] persistentFileURLForFileAtURL:selectedAssetURI];
		
		if (!finalFileURL)
		if (!selectedAssetURI && representedAsset)
			finalFileURL = [[WADataStore defaultStore] persistentFileURLForData:UIImagePNGRepresentation([UIImage imageWithCGImage:[[representedAsset defaultRepresentation] fullResolutionImage]]) extension:@"png"];
		
		WAFile *stitchedFile = (WAFile *)[WAFile objectInsertingIntoContext:self.managedObjectContext withRemoteDictionary:[NSDictionary dictionary]];
		stitchedFile.resourceType = (NSString *)kUTTypeImage;
		stitchedFile.resourceURL = [finalFileURL absoluteString];
		stitchedFile.resourceFilePath = [finalFileURL path];
		stitchedFile.article = self.article;
		
	}
	
	[self.modalViewController dismissModalViewControllerAnimated:YES];
	
	if ([imagePickerPopover isPopoverVisible])
		[imagePickerPopover dismissPopoverAnimated:YES];
	
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	return YES;
	
}

@end


@implementation WACompositionViewController (CustomUI)

- (UINavigationController *) wrappingNavigationController {

	NSAssert2(!self.navigationController, @"%@ must not have been put within another navigation controller when %@ is invoked.", self, NSStringFromSelector(_cmd));
	NSAssert2((UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM()), @"%@: %s is not supported on this device.", self, NSStringFromSelector(_cmd));
	
	WANavigationController *navController = [[[WANavigationController alloc] initWithRootViewController:[[[UIViewController alloc] init] autorelease]] autorelease];
	
	NSKeyedUnarchiver *unarchiver = [[[NSKeyedUnarchiver alloc] initForReadingWithData:[NSKeyedArchiver archivedDataWithRootObject:navController]] autorelease];
	[unarchiver setClass:[WANavigationBar class] forClassName:@"UINavigationBar"];
	navController = [unarchiver decodeObjectForKey:@"root"];
	
	static NSString * const kViewControllerActionOnPop = @"waCompositionViewController_wrappingNavigationController_viewControllerActionOnPop";

	navController.willPushViewControllerAnimated = ^ (WANavigationController *self, UIViewController *pushedVC, BOOL animated) {
		
		if (![pushedVC isKindOfClass:[WACompositionViewController class]])
			return;
		
		((WACompositionViewController *)pushedVC).usesTransparentBackground = YES;
		
		UIBarButtonItem *oldLeftItem = [[pushedVC.navigationItem.leftBarButtonItem retain] autorelease];
		__block id leftTarget = oldLeftItem.target;
		__block SEL leftAction = oldLeftItem.action;
		NSString *leftTitle = oldLeftItem.title ? oldLeftItem.title : @"Cancel";
		
		UIBarButtonItem *oldRightItem = [[pushedVC.navigationItem.rightBarButtonItem retain] autorelease];
		__block id rightTarget = oldRightItem.target;
		__block SEL rightAction = oldRightItem.action;
		NSString *rightTitle = oldRightItem.title ? oldRightItem.title : @"Done";
		
		IRBorder *border = [IRBorder borderForEdge:IREdgeNone withType:IRBorderTypeInset width:1 color:[UIColor colorWithRed:0 green:0 blue:0 alpha:.5]];
		IRShadow *innerShadow = [IRShadow shadowWithColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.55] offset:(CGSize){ 0, 1 } spread:2];
		IRShadow *shadow = [IRShadow shadowWithColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1] offset:(CGSize){ 0, 1 } spread:1];
		
		UIFont *titleFont = [UIFont boldSystemFontOfSize:12];
		UIColor *titleColor = [UIColor colorWithRed:.3 green:.3 blue:.3 alpha:1];
		IRShadow *titleShadow = [IRShadow shadowWithColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:.35] offset:(CGSize){ 0, 1 } spread:0];
		
		UIColor *normalFromColor = [UIColor colorWithRed:.9 green:.9 blue:.9 alpha:1];
		UIColor *normalToColor = [UIColor colorWithRed:.5 green:.5 blue:.5 alpha:1];
		UIColor *normalBackgroundColor = nil;
		NSArray *normalGradientColors = [NSArray arrayWithObjects:(id)normalFromColor.CGColor, (id)normalToColor.CGColor, nil];
		
		UIColor *highlightedFromColor = [normalFromColor colorWithAlphaComponent:.95];
		UIColor *highlightedToColor = [normalToColor colorWithAlphaComponent:.95];
		UIColor *highlightedBackgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
		NSArray *highlightedGradientColors = [NSArray arrayWithObjects:(id)highlightedFromColor.CGColor, (id)highlightedToColor.CGColor, nil];
		
		UIImage *leftItemImage = [IRBarButtonItem buttonImageForStyle:IRBarButtonItemStyleBack withTitle:leftTitle font:titleFont color:titleColor shadow:titleShadow backgroundColor:normalBackgroundColor gradientColors:normalGradientColors innerShadow:innerShadow border:border shadow:shadow];
		UIImage *highlightedLeftItemImage = [IRBarButtonItem buttonImageForStyle:IRBarButtonItemStyleBack withTitle:leftTitle font:titleFont color:titleColor shadow:titleShadow backgroundColor:highlightedBackgroundColor gradientColors:highlightedGradientColors innerShadow:innerShadow border:border shadow:shadow];
		__block IRBarButtonItem *newLeftItem = [IRBarButtonItem itemWithCustomImage:leftItemImage highlightedImage:highlightedLeftItemImage];
		newLeftItem.block = ^ { [leftTarget performSelector:leftAction withObject:newLeftItem]; };
		pushedVC.navigationItem.leftBarButtonItem = newLeftItem;
		
		UIImage *rightItemImage = [IRBarButtonItem buttonImageForStyle:IRBarButtonItemStyleBordered withTitle:rightTitle font:titleFont color:titleColor shadow:titleShadow backgroundColor:normalFromColor gradientColors:normalGradientColors innerShadow:innerShadow border:border shadow:shadow];
		UIImage *highlightedRightItemImage = [IRBarButtonItem buttonImageForStyle:IRBarButtonItemStyleBordered withTitle:rightTitle font:titleFont color:titleColor shadow:titleShadow backgroundColor:highlightedBackgroundColor gradientColors:highlightedGradientColors innerShadow:innerShadow border:border shadow:shadow];
		__block IRBarButtonItem *newRightItem = [IRBarButtonItem itemWithCustomImage:rightItemImage highlightedImage:highlightedRightItemImage];
		newRightItem.block = ^ { [rightTarget performSelector:rightAction withObject:newRightItem]; };
		pushedVC.navigationItem.rightBarButtonItem = newRightItem;

		if (!pushedVC.navigationItem.titleView) {
			
			__block UILabel *titleLabel = [[[UILabel alloc] init] autorelease];
			titleLabel.textColor = [UIColor colorWithWhite:0.35 alpha:1];
			titleLabel.font = [UIFont fontWithName:@"Sansus Webissimo" size:24.0f];
			titleLabel.shadowColor = [UIColor whiteColor];
			titleLabel.shadowOffset = (CGSize){ 0, 1 };
			titleLabel.opaque = NO;
			titleLabel.backgroundColor = nil;
			
			[titleLabel irBind:@"text" toObject:pushedVC keyPath:@"title" options:[NSDictionary dictionaryWithObjectsAndKeys:
				
				[[^ (id oldValue, id newValue, NSString *changeType) {
					
					titleLabel.text = newValue;
					[titleLabel sizeToFit];
					
					return newValue;
				
				} copy] autorelease], kIRBindingsValueTransformerBlock,
				
				kCFBooleanTrue, kIRBindingsAssignOnMainThreadOption,
			
			nil]];
			
			objc_setAssociatedObject(pushedVC, &kViewControllerActionOnPop, ^ {
			
				[titleLabel irUnbind:@"text"];
			
			}, OBJC_ASSOCIATION_COPY_NONATOMIC);
			
			pushedVC.navigationItem.titleView = titleLabel;

		}
		
		if (![pushedVC isViewLoaded])
			return;
			
		pushedVC.view.backgroundColor = nil;
		pushedVC.view.opaque = NO;
		
	};
	
	navController.onDismissModalViewControllerAnimated = ^ (WANavigationController *self, BOOL animated) {
	
		void (^action)() = objc_getAssociatedObject(self.topViewController, &kViewControllerActionOnPop);
		if (action)
				action();
		
	};
	
	[navController initWithRootViewController:self];
	
	navController.onViewDidLoad = ^ (WANavigationController *self) {
		
		((WANavigationBar *)self.navigationBar).backgroundView = [WANavigationBar defaultGradientBackgroundView];
		
		self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPatternWoodTexture"]];
		
		UIColor *baseColor = [UIColor colorWithRed:.75 green:.65 blue:.52 alpha:1];
		
		IRGradientView *gradientView = [[[IRGradientView alloc] initWithFrame:(CGRect){ CGPointZero, (CGSize){ CGRectGetWidth(self.view.frame), 512 } }] autorelease];
		[gradientView setLinearGradientFromColor:[baseColor colorWithAlphaComponent:1] anchor:irTop toColor:[baseColor colorWithAlphaComponent:0] anchor:irBottom];
		
		gradientView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
		
		[self.view addSubview:gradientView];
		[self.view sendSubviewToBack:gradientView];
					
	};
	
	if ([navController isViewLoaded])
		navController.onViewDidLoad(navController);
	
	return navController;

}

@end
