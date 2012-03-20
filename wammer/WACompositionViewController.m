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
#import "WANavigationBar.h"
#import "WANavigationController.h"
#import "WAViewController.h"
#import "WAPreviewBadge.h"


@interface WACompositionViewController () <UITextViewDelegate, IRTextAttributorDelegate>

@property (nonatomic, readwrite, copy) void (^completionBlock)(NSURL *returnedURI);
@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) WAArticle *article;

@property (nonatomic, readwrite, retain) IRTextAttributor *textAttributor;

@end


@implementation WACompositionViewController

@synthesize managedObjectContext, article;
@synthesize containerView;
@synthesize contentTextView;
@synthesize completionBlock;
@synthesize usesTransparentBackground;
@synthesize textAttributor;

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

+ (WACompositionViewController *) controllerWithArticle:(NSURL *)anArticleURLOrNil completion:(void(^)(NSURL *anArticleURLOrNil))aBlock {

	WACompositionViewController *returnedController = [[self alloc] init];
	returnedController.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
	returnedController.managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
	
	if (anArticleURLOrNil)
		returnedController.article = (WAArticle *)[returnedController.managedObjectContext irManagedObjectForURI:anArticleURLOrNil];
	
	if (!returnedController.article) {
		returnedController.article = [WAArticle objectInsertingIntoContext:returnedController.managedObjectContext withRemoteDictionary:[NSDictionary dictionary]];
		returnedController.article.draft = [NSNumber numberWithBool:YES];
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
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(handleDone:)];
	
	return self;

}

- (void) setArticle:(WAArticle *)newArticle {

	__block __typeof__(self) nrSelf = self;

	[self willChangeValueForKey:@"article"];
	
	[article irRemoveObserverBlocksForKeyPath:@"fileOrder"];
	[article irRemoveObserverBlocksForKeyPath:@"previews"];
	
	article = newArticle;
	
	[article irAddObserverBlock:^(id inOldValue, id inNewValue, NSKeyValueChange changeKind) {
		[nrSelf handleCurrentArticleFilesChangedFrom:inOldValue to:inNewValue changeKind:changeKind];
	} forKeyPath:@"fileOrder" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];	
	
	[article irAddObserverBlock:^(id inOldValue, id inNewValue, NSKeyValueChange changeKind) {
		[nrSelf handleCurrentArticlePreviewsChangedFrom:inOldValue to:inNewValue changeKind:changeKind];
	} forKeyPath:@"previews" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
	
	[self didChangeValueForKey:@"article"];

}

- (void) dealloc {

	[article irRemoveObserverBlocksForKeyPath:@"fileOrder"];
	[article irRemoveObserverBlocksForKeyPath:@"previews"];
	
	[self.navigationItem.rightBarButtonItem irUnbind:@"enabled"];

}

- (void) viewDidUnload {

	self.containerView = nil;
	
	self.contentTextView.delegate = nil;
	self.contentTextView = nil;
	
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
  	
	id notificationObject = [[NSNotificationCenter defaultCenter] addObserverForName:IRWindowInterfaceBoundsDidChangeNotification object:self.view.window queue:nil usingBlock:^(NSNotification *aNotification) {
	
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
				default: return 0;
			}
		})());
		
		if (animationDuration) {
		
			[UIView animateWithDuration:animationDuration delay:0 options:animationOptions animations:^{

				[self adjustContainerViewWithInterfaceBounds:newBounds];
				
			} completion:nil];
		
		} else {

			[self adjustContainerViewWithInterfaceBounds:newBounds];		
		
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





- (IRTextAttributor *) textAttributor {

	if (textAttributor)
		return textAttributor;
	
	__block __typeof__(self) nrSelf = self;
	
	textAttributor = [[IRTextAttributor alloc] init];
	textAttributor.delegate = self;
	textAttributor.discoveryBlock = IRTextAttributorDiscoveryBlockMakeWithRegularExpression([NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil]);
	
	textAttributor.attributionBlock = ^ (NSString *attributedString, IRTextAttributorAttributionCallback callback) {
	
		if (!attributedString) {
			callback(nil);
			return;
		}
	
		NSURL *url = [NSURL URLWithString:attributedString];
		if (!url) {
			callback(nil);
			return;
		}
		
		if ([[nrSelf.article.previews objectsPassingTest: ^ (WAPreview *aPreview, BOOL *stop) {
			
			return [aPreview.url isEqualToString:attributedString];
			
		}] count]) {
		
			//	Already got something and attached, skip
			
			callback(nil);
			return;
		
		}
		
		[[WARemoteInterface sharedInterface] retrievePreviewForURL:url onSuccess:^(NSDictionary *aPreviewRep) {
		
			callback(aPreviewRep);
			
		} onFailure: ^ (NSError *error) {
			
			callback(nil);			
			
		}];
	
	};
	
	return textAttributor;

}

- (void) textViewDidChange:(UITextView *)textView {

	NSString *capturedText = textView.text;
	self.article.text = capturedText;
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0f * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
	
		if ([textView.text isEqualToString:capturedText])
			self.textAttributor.attributedContent = [[NSMutableAttributedString alloc] initWithString:capturedText];
			
	});
	
}

- (void) textAttributor:(IRTextAttributor *)attributor willUpdateAttributedString:(NSAttributedString *)attributedString withToken:(NSString *)aToken range:(NSRange)tokenRange attribute:(id)newAttribute {

	//	NSLog(@"%s %@ %@ %@ %@ %@", __PRETTY_FUNCTION__, attributor, attributedString, aToken, NSStringFromRange(tokenRange), newAttribute);	

}

- (void) textAttributor:(IRTextAttributor *)attributor didUpdateAttributedString:(NSAttributedString *)attributedString withToken:(NSString *)aToken range:(NSRange)tokenRange attribute:(id)newAttribute {

	NSMutableArray *potentialLinkAttributes = [NSMutableArray array];

	[attributedString enumerateAttribute:IRTextAttributorTagAttributeName inRange:(NSRange){ 0, [attributedString length] } options:0 usingBlock: ^ (id value, NSRange range, BOOL *stop) {
		
		if (value)
			[potentialLinkAttributes addObject:value];
		
	}];
	
	NSArray *mappedPreviewEntities = [potentialLinkAttributes irMap: ^ (id anAttribute, NSUInteger index, BOOL *stop) {
	
		if (![anAttribute isKindOfClass:[NSDictionary class]])
			return (id)nil;
		
		return (id)[NSDictionary dictionaryWithObjectsAndKeys:
			anAttribute, @"og",
			[anAttribute valueForKeyPath:@"url"], @"id",
		nil];
		
	}];

	NSArray *allMatchingPreviews = [WAPreview insertOrUpdateObjectsUsingContext:self.managedObjectContext withRemoteResponse:mappedPreviewEntities usingMapping:nil options:IRManagedObjectOptionIndividualOperations];
	if (![allMatchingPreviews count])
		return;
	
	WAPreview *stitchedPreview = [allMatchingPreviews objectAtIndex:0];
	NSError *error = nil;
	NSAssert1([self.managedObjectContext save:&error], @"Error Saving: %@", error);
	
	//	If there’s already an attachment, do nothing
	
	if ([self.article.files count])
		stitchedPreview = nil;
	
	//	If the article holds a preview already, don’t change it

	if ([self.article.previews count])
		return;

	//	Don’t delete them, just leave them for later to cleanup
	//	for (WAPreview *aPreview in allMatchingPreviews)
	//		if (stitchedPreview ? (aPreview != stitchedPreview) : YES)
	//			[aPreview.managedObjectContext deleteObject:aPreview];
	
	self.article.previews = stitchedPreview ? [NSSet setWithObject:stitchedPreview] : [NSSet set];

}

- (void) handleCurrentArticleFilesChangedFrom:(NSArray *)fromValue to:(NSArray *)toValue changeKind:(NSKeyValueChange)changeKind {

	//	No op

}

- (void) handleCurrentArticlePreviewsChangedFrom:(id)fromValue to:(id)toValue changeKind:(NSKeyValueChange)changeKind {
	
	//	No op

}

- (void) handleCurrentTextChangedFrom:(NSString *)fromValue to:(NSString *)toValue changeKind:(NSKeyValueChange)changeKind {

	NSLog(@"%s %@ %@ %i", __PRETTY_FUNCTION__, fromValue, toValue, changeKind);

}

//	Deleting all the changed stuff and saving is like throwing all the stuff away
//	In that sense just don’t do anything.

- (void) handleDone:(UIBarButtonItem *)sender {

	//	TBD save a draft
	
	self.article.text = self.contentTextView.text;
  self.article.timestamp = [NSDate date];
	
	NSError *savingError = nil;
	if (![self.managedObjectContext save:&savingError])
		NSLog(@"Error saving: %@", savingError);
	
	if (self.completionBlock)
		self.completionBlock([[self.article objectID] URIRepresentation]);
		
	if([self.article.previews count])
		WAPostAppEvent(@"Create Preview", [NSDictionary dictionaryWithObjectsAndKeys:@"link",@"category",@"create", @"action", nil]);
	else if([self.article.files count])
		WAPostAppEvent(@"Create Photo", [NSDictionary dictionaryWithObjectsAndKeys:@"photo",@"category",@"create", @"action", nil]);
	else 
		WAPostAppEvent(@"Create Text", [NSDictionary dictionaryWithObjectsAndKeys:@"text",@"category",@"create", @"action", nil]);
		
}	

- (void) handleCancel:(UIBarButtonItem *)sender {

	if (![self.article hasChanges] || ![self.article hasMeaningfulContent]) {
	
		if (self.completionBlock)
			self.completionBlock(nil);
		
		//	Delete things that are not meaningful
		
		if (![self.article hasMeaningfulContent])
			[self.article.managedObjectContext deleteObject:self.article];
		
		return;
	
	}
	
	IRActionSheetController *actionSheetController = objc_getAssociatedObject(sender, _cmd);
	if ([[actionSheetController managedActionSheet] isVisible])
		return;
	
	if (!actionSheetController) {
	
		IRAction *discardAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_DISCARD", @"Action title for discarding a draft") block:^{
			
			if (self.completionBlock)
				self.completionBlock(nil);
			
		}];
		
		IRAction *saveAsDraftAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_SAVE_DRAFT", @"Action title for saving a draft") block:^{
		
			self.article.text = self.contentTextView.text;
			self.article.timestamp = [NSDate date];
			
			NSError *savingError = nil;
			if (![self.managedObjectContext save:&savingError])
				NSLog(@"Error saving: %@", savingError);
			
			if (self.completionBlock)
				self.completionBlock(nil);
		
		}];
			
		actionSheetController = [IRActionSheetController actionSheetControllerWithTitle:nil cancelAction:nil destructiveAction:discardAction otherActions:[NSArray arrayWithObjects:
			saveAsDraftAction,
		nil]];
			
		objc_setAssociatedObject(sender, _cmd, actionSheetController, OBJC_ASSOCIATION_ASSIGN);
		
		actionSheetController.onActionSheetCancel = ^ {
			objc_setAssociatedObject(sender, _cmd, nil, OBJC_ASSOCIATION_ASSIGN);
		};
		
		actionSheetController.onActionSheetDidDismiss = ^ (IRAction *invokedAction) {
			objc_setAssociatedObject(sender, _cmd, nil, OBJC_ASSOCIATION_ASSIGN);
		};
	
	}
	
	NSParameterAssert(actionSheetController && ![actionSheetController.managedActionSheet isVisible]);
	
	[[actionSheetController managedActionSheet] showFromBarButtonItem:sender animated:YES];
	
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  
	return YES;
	
}


@end
