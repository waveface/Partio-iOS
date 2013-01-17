//
//  WACompositionViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WACompositionViewController.h"

#import "Foundation+IRAdditions.h"
#import "UIKit+IRAdditions.h"
#import "AssetsLibrary+IRAdditions.h"

#import "IRTextAttributor.h"

#import "WADefines.h"
#import "WADataStore.h"
#import "WARemoteInterface.h"

#import "WACompositionViewPhotoCell.h"
#import "WANavigationController.h"
#import "WAOverlayBezel.h"
#import "WACompositionViewController+ImageHandling.h"
#import "WAAssetsLibraryManager.h"

@interface WACompositionViewController () <UITextViewDelegate, IRTextAttributorDelegate>

@property (nonatomic, readwrite, copy) void (^completionBlock)(WAArticle *returnedArticle, NSManagedObjectContext *moc);
@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) WAArticle *article;

@property (nonatomic, readwrite, retain) IRTextAttributor *textAttributor;
@property (nonatomic, readwrite, retain) IRActionSheetController *cancellationActionSheetController;

- (BOOL)associatedImagesMadeForFile:(WAFile *)file;

@end


@implementation WACompositionViewController

@synthesize managedObjectContext = _managedObjectContext;
@synthesize article = _article;
@synthesize containerView = _containerView;
@synthesize contentTextView = _contentTextView;
@synthesize completionBlock = _completionBlock;
@synthesize usesTransparentBackground = _usesTransparentBackground;
@synthesize textAttributor = _textAttributor;
@synthesize cancellationActionSheetController = _cancellationActionSheetController;
@synthesize queue = _queue;

+ (id) alloc {

	if ([self class] != [WACompositionViewController class])
		return [super alloc];

	switch ([UIDevice currentDevice].userInterfaceIdiom) {
	
		case UIUserInterfaceIdiomPad: {
			return [(Class)NSClassFromString(@"WACompositionViewControllerPad") alloc];
			break;
		}
	
		default:
		case UIUserInterfaceIdiomPhone: {
			return [(Class)NSClassFromString(@"WACompositionViewControllerPhone") alloc];
			break;
		}
		
	}

}

+ (WACompositionViewController *) controllerWithArticle:(NSURL *)anArticleURLOrNil completion:(void(^)(WAArticle *anArticleOrNil, NSManagedObjectContext *moc))aBlock {

	WACompositionViewController *returnedController = [[self alloc] init];
	returnedController.managedObjectContext = [[WADataStore defaultStore] autoUpdatingMOC];
	returnedController.managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
	
	if (anArticleURLOrNil) {
		
		WAArticle *foundArticle = (WAArticle *)[returnedController.managedObjectContext irManagedObjectForURI:anArticleURLOrNil];
		NSAssert1(foundArticle, @"Unable to dereference WAArticle reference at %@", anArticleURLOrNil);
		returnedController.article = foundArticle;
	
	} else {
	
		WAArticle *article = [WAArticle objectInsertingIntoContext:returnedController.managedObjectContext withRemoteDictionary:[NSDictionary dictionary]];
		article.draft = (id)kCFBooleanTrue;
		article.creationDate = [NSDate date];
		
		returnedController.article = article;
		
	}
	
	returnedController.completionBlock = aBlock;
	
	return returnedController;
	
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if (!self)
		return nil;
	
	self.title = NSLocalizedString(@"COMPOSITION_TITLE", @"Title for the composition view");
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(handleCancel:)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ACTION_DONE", @"In iPad composition view") style:UIBarButtonItemStyleDone target:self action:@selector(handleDone:)];
	
	_queue = [[NSOperationQueue alloc] init];
	_queue.maxConcurrentOperationCount = 1;
	
	return self;

}

- (void) setArticle:(WAArticle *)newArticle {

	__weak WACompositionViewController *wSelf = self;
	
	[_article irRemoveObserverBlocksForKeyPath:@"files"];
	
	_article = newArticle;
	
	[_article irObserve:@"files" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
	
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[wSelf handleFilesChangeKind:kind oldValue:fromValue newValue:toValue indices:indices isPrior:isPrior];
		
		});
	
	}];
	
}

- (void) dealloc {

	_textAttributor.delegate = nil;

	[_article irRemoveObserverBlocksForKeyPath:@"files"];
	
	[self.navigationItem.rightBarButtonItem irUnbind:@"enabled"];
	
	[_queue cancelAllOperations];

}

- (void) viewDidUnload {

	self.containerView = nil;
	
	self.contentTextView.delegate = nil;
	self.contentTextView = nil;
	
	self.cancellationActionSheetController = nil;
	
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
	
	self.contentTextView.delegate = self;
	self.contentTextView.backgroundColor = nil;
	self.contentTextView.opaque = NO;
	self.contentTextView.contentInset = (UIEdgeInsets){ 4, 0, 0, 0 };
	self.contentTextView.bounces = YES;
	self.contentTextView.alwaysBounceVertical = YES;
	
	//	Put this last so when the article is initialized things all work
	self.contentTextView.text = self.article.text;
	[self textViewDidChange:self.contentTextView];
	
}


static NSString * const kWACompositionViewWindowInterfaceBoundsNotificationHandler = @"kWACompositionViewWindowInterfaceBoundsNotificationHandler";

- (void) viewWillAppear:(BOOL)animated {

  [super viewWillAppear:animated];
	
	__weak WACompositionViewController *wSelf = self;
  	
	id notificationObject = [[NSNotificationCenter defaultCenter] addObserverForName:IRWindowInterfaceBoundsDidChangeNotification object:self.view.window queue:nil usingBlock:^(NSNotification *aNotification) {
	
		if (!wSelf)
			return;
	
		NSDictionary *userInfo = [aNotification userInfo];
		CGRect newBounds = [[userInfo objectForKey:IRWindowInterfaceChangeNewBoundsKey] CGRectValue];
		
		NSDictionary *keyboardInfo = [[userInfo objectForKey:IRWindowInterfaceChangeUnderlyingKeyboardNotificationKey] userInfo];
		
		UIViewAnimationCurve animationCurve = [[keyboardInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] unsignedIntValue];
		NSTimeInterval animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
		
		UIViewAnimationOptions animationOptions = UIViewAnimationOptionBeginFromCurrentState;
		animationOptions |= ((^ {
			switch (animationCurve) {
				case UIViewAnimationCurveEaseIn: return UIViewAnimationOptionCurveEaseIn;
				case UIViewAnimationCurveEaseOut:return UIViewAnimationOptionCurveEaseOut;
				case UIViewAnimationCurveEaseInOut: return UIViewAnimationOptionCurveEaseInOut;
				case UIViewAnimationCurveLinear: return UIViewAnimationOptionCurveLinear;
				default: return UIViewAnimationOptionCurveLinear;
			}
		})());
		
		if (animationDuration) {
		
			[UIView animateWithDuration:animationDuration delay:0 options:animationOptions animations:^{

				[wSelf adjustContainerViewWithInterfaceBounds:newBounds];
				
			} completion:nil];
		
		} else {

			[wSelf adjustContainerViewWithInterfaceBounds:newBounds];		
		
		}
		
	}];
	
	objc_setAssociatedObject(self, &kWACompositionViewWindowInterfaceBoundsNotificationHandler, notificationObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	[self.navigationItem.rightBarButtonItem irBind:@"enabled" toObject:self.article keyPath:@"hasMeaningfulContent" options:[NSDictionary dictionaryWithObjectsAndKeys:
		(id)kCFBooleanTrue, kIRBindingsAssignOnMainThreadOption,
	nil]];
		
}	

- (void) viewDidAppear:(BOOL)animated {
	
	[super viewDidAppear:animated];

}

- (void) viewWillDisappear:(BOOL)animated {

	[self.navigationItem.rightBarButtonItem irUnbind:@"enabled"];
	
	id notificationObject = objc_getAssociatedObject(self, &kWACompositionViewWindowInterfaceBoundsNotificationHandler);
	[[NSNotificationCenter defaultCenter] removeObserver:notificationObject];
	objc_setAssociatedObject(self, &kWACompositionViewWindowInterfaceBoundsNotificationHandler, nil, OBJC_ASSOCIATION_ASSIGN);
	
	[self.contentTextView resignFirstResponder];
	
	[_textAttributor.queue cancelAllOperations];
	
	[super viewWillDisappear:animated];

}

- (void) adjustContainerViewWithInterfaceBounds:(CGRect)newBounds {

	if (![self isViewLoaded])
		return;
	
	UIWindow *ownWindow = self.view.window;
	if (!ownWindow) {
		if (!CGRectEqualToRect(self.containerView.frame, self.view.bounds))
			self.containerView.frame = self.view.bounds;
		return;
	}
	
	CGRect usableRectInWindow = newBounds;
	CGRect fullViewRectInWindow = [ownWindow convertRect:self.view.bounds fromView:self.view];
	CGRect overlappingRectInWindow = CGRectIntersection(fullViewRectInWindow, usableRectInWindow);
	
	CGRect usableRect = [ownWindow convertRect:overlappingRectInWindow toView:self.view];
	
	if (!CGRectEqualToRect(self.containerView.frame, usableRect))
		self.containerView.frame = usableRect;

}

- (BOOL) associatedImagesMadeForFile:(WAFile *)file {

	return !!file.extraSmallThumbnailFilePath;

}



- (IRTextAttributor *) textAttributor {

	if (_textAttributor)
		return _textAttributor;
	
	_textAttributor = [[IRTextAttributor alloc] init];
	_textAttributor.delegate = self;
	_textAttributor.discoveryBlock = IRTextAttributorDiscoveryBlockMakeWithRegularExpression([NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil]);
	
  _textAttributor.attributionBlock = ^(NSString *attributedString, IRTextAttributorAttributionCallback callback) {
	callback (nil);
  };
  return _textAttributor;

}

- (void) textViewDidChange:(UITextView *)textView {

	NSString *capturedText = textView.text;
	self.article.text = capturedText;
	
	__weak WACompositionViewController *wSelf = self;
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0f * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
	
		if ([textView.text isEqualToString:capturedText])
			wSelf.textAttributor.attributedContent = [[NSMutableAttributedString alloc] initWithString:capturedText];
			
	});
	
}

- (void) textAttributor:(IRTextAttributor *)attributor willUpdateAttributedString:(NSAttributedString *)attributedString withToken:(NSString *)aToken range:(NSRange)tokenRange attribute:(id)newAttribute {

	//	NSLog(@"%s %@ %@ %@ %@ %@", __PRETTY_FUNCTION__, attributor, attributedString, aToken, NSStringFromRange(tokenRange), newAttribute);	

}

- (void) textAttributor:(IRTextAttributor *)attributor didUpdateAttributedString:(NSAttributedString *)attributedString withToken:(NSString *)aToken range:(NSRange)tokenRange attribute:(id)newAttribute {

  // No op
  
}

- (void) handleFilesChangeKind:(NSKeyValueChange)kind oldValue:(id)oldValue newValue:(id)newValue indices:(NSIndexSet *)indices isPrior:(BOOL)isPrior {

	//	No op

}

- (void) handlePreviewsChangeKind:(NSKeyValueChange)kind oldValue:(id)oldValue newValue:(id)newValue indices:(NSIndexSet *)indices isPrior:(BOOL)isPrior {

	//	No op

}

- (void) handleCurrentTextChangedFrom:(NSString *)fromValue to:(NSString *)toValue changeKind:(NSKeyValueChange)changeKind {

	//	No op

}

//	Deleting all the changed stuff and saving is like throwing all the stuff away
//	In that sense just don’t do anything.

- (void) handleDone:(UIBarButtonItem *)sender {

	// disable user interactions
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	self.article.text = self.contentTextView.text;
	if (self.article.modificationDate) {
		// set modification date only when updating articles
		self.article.modificationDate = [NSDate date];
	}
  
  [self.contentTextView resignFirstResponder];

  dispatch_async(dispatch_get_main_queue(), ^ {

	if (self.completionBlock)
	  self.completionBlock(self.article, self.managedObjectContext);
	
	[[UIApplication sharedApplication] endIgnoringInteractionEvents];
  });
		
}	

- (void) handleCancel:(UIBarButtonItem *)sender {

	if (!([self.article hasChanges] && [[self.article changedValues] count]) || ![self.article hasMeaningfulContent]) {
	
		if (self.completionBlock)
			self.completionBlock(nil, self.managedObjectContext);
		
		//	Delete things that are not meaningful if it’s a draft
		
		if (![self.article hasMeaningfulContent])
		if ([self.article.draft isEqualToNumber:(NSNumber *)kCFBooleanTrue])
			[self.article.managedObjectContext deleteObject:self.article];
		
		return;
	
	}
	
	IRActionSheetController *actionSheetController = self.cancellationActionSheetController;
	if ([[actionSheetController managedActionSheet] isVisible])
		return;
	
	NSParameterAssert(actionSheetController && ![actionSheetController.managedActionSheet isVisible]);
	
	[[actionSheetController managedActionSheet] showFromBarButtonItem:sender animated:YES];
	
}

- (IRActionSheetController *) cancellationActionSheetController {

	if (!_cancellationActionSheetController) {
	
		__weak WACompositionViewController *wSelf = self;
	
		IRAction *discardAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_DISCARD", @"Action title for discarding a draft") block:^{
			
			if (wSelf.completionBlock)
				wSelf.completionBlock(nil, self.managedObjectContext);
			
		}];
		
		IRAction *saveAsDraftAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_SAVE_DRAFT", @"Action title for saving a draft") block:^{
		
			wSelf.article.text = wSelf.contentTextView.text;
			wSelf.article.creationDate = [NSDate date];
			
			NSError *savingError = nil;
			if (![wSelf.managedObjectContext save:&savingError])
				NSLog(@"Error saving: %@", savingError);
			
			if (wSelf.completionBlock)
				wSelf.completionBlock(nil, self.managedObjectContext);
		
		}];
			
		_cancellationActionSheetController = [IRActionSheetController actionSheetControllerWithTitle:nil cancelAction:nil destructiveAction:discardAction otherActions:[NSArray arrayWithObjects:
			saveAsDraftAction,
		nil]];
			
		_cancellationActionSheetController.onActionSheetCancel = ^ {
		
			wSelf.cancellationActionSheetController = nil;
		
		};
		
		_cancellationActionSheetController.onActionSheetDidDismiss = ^ (IRAction *invokedAction) {
			
			wSelf.cancellationActionSheetController = nil;
				
		};
	
	}
	
	return _cancellationActionSheetController;
	
}


- (BOOL) shouldAutorotate {

  return YES;

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  
	return YES;
	
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
	[self adjustContainerViewWithInterfaceBounds:((UIWindow *)[[UIApplication sharedApplication].windows objectAtIndex:0]).irInterfaceBounds];

}

@end
