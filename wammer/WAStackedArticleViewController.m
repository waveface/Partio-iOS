//
//  WAStackedArticleViewController.m
//  wammer
//
//  Created by Evadne Wu on 12/22/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAStackedArticleViewController.h"

#import "WADefines.h"
#import "WAArticleTextStackCell.h"
#import "WAArticleTextEmphasisLabel.h"

#import "WAArticleCommentsViewController.h"

#import "WADataStore.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"

#import "WAOverlayBezel.h"

#import "WAArticleTextStackElement.h"

#import "Foundation+IRAdditions.h"
#import "UIKit+IRAdditions.h"


@interface WAStackedArticleViewController () <WAArticleCommentsViewControllerDelegate, WAArticleTextStackElementDelegate>

@property (nonatomic, readwrite, retain) WAArticleTextStackCell *topCell;
@property (nonatomic, readwrite, retain) WAArticleTextStackElement *textStackCell;
@property (nonatomic, readwrite, assign) BOOL foldsTextStackCell;	//	Default is YES

@property (nonatomic, readwrite, retain) WAArticleTextEmphasisLabel *textStackCellLabel;
@property (nonatomic, readwrite, retain) WAArticleCommentsViewController *commentsVC;
@property (nonatomic, readwrite, retain) UIPopoverController *commentsPopover;

@property (nonatomic, readwrite, retain) UIView *wrapperView;

@property (nonatomic, readwrite, retain) UIView *textStackCellFoldingToggleWrapperView;
@property (nonatomic, readwrite, retain) UIButton *textStackCellFoldingToggle;

@property (nonatomic, readwrite, retain) NSArray *headerBarButtonItems;

- (void) adjustWrapperViewBoundsWithWindowInterfaceBounds:(CGRect)newInterfaceBounds animated:(BOOL)animate;

@end


@implementation WAStackedArticleViewController
@synthesize headerView;
@synthesize topCell, textStackCell, foldsTextStackCell, textStackCellLabel, commentsVC, commentsPopover, stackView, wrapperView, onViewDidLoad, onPullTop, footerCell;
@synthesize textStackCellFoldingToggleWrapperView, textStackCellFoldingToggle;
@synthesize headerBarButtonItems;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (!self)
		return nil;
	
	__block __typeof__(self) nrSelf = self;
	
	IRBarButtonItem *articleDateItem = [IRBarButtonItem itemWithCustomView:((^ {
					
		__block IRLabel *label = [[[IRLabel alloc] initWithFrame:(CGRect){ (CGPoint){ 36, 32 }, (CGSize){ 256 , 24 } }] autorelease];
		label.opaque = NO;
		label.backgroundColor = nil;
		
		[label irBind:@"attributedText" toObject:nrSelf keyPath:@"article" options:[NSDictionary dictionaryWithObjectsAndKeys:
		
			[[ ^ (id inOldValue, id inNewValue, NSString *changeKind) {
			
				NSString *relDate = [[IRRelativeDateFormatter sharedFormatter] stringFromDate:nrSelf.article.timestamp];
				NSString *device = nrSelf.article.creationDeviceName;

				return [label attributedStringForString:(
					
					[NSString stringWithFormat:@"%@ (%@)", relDate, device]
					
				) font:[UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f] color:[UIColor colorWithWhite:0.5 alpha:1]];
			
			} copy] autorelease], kIRBindingsValueTransformerBlock,
		
		nil]];
		
		[nrSelf irPerformOnDeallocation:^{
		
			[label irUnbind:@"attributedText"];
			
		}];
		
		return label;
		
	})())];
	
	__block IRBarButtonItem *commentsItem = ((^ {
	
		IRBarButtonItem *commentsItem = [[[IRBarButtonItem alloc] initWithTitle:@"Comments" style:UIBarButtonItemStyleBordered target:nil action:nil] autorelease];
	
		switch ([UIDevice currentDevice].userInterfaceIdiom) {
		
			case UIUserInterfaceIdiomPad: {
				
				[commentsItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
					[UIColor colorWithWhite:.5 alpha:1], UITextAttributeTextColor,
					[UIColor clearColor], UITextAttributeTextShadowColor,
					[NSValue valueWithUIOffset:UIOffsetZero], UITextAttributeTextShadowOffset,
				nil] forState:UIControlStateNormal];
				
				[commentsItem setBackgroundImage:[[UIImage imageNamed:@"WAGrayTranslucentBarButton"] resizableImageWithCapInsets:(UIEdgeInsets){ 4, 4, 5, 4 }] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
				
				[commentsItem setBackgroundImage:[[UIImage imageNamed:@"WAGrayTranslucentBarButtonPressed"] resizableImageWithCapInsets:(UIEdgeInsets){ 4, 4, 5, 4 }] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
				
				break;
				
			}
			
			case UIUserInterfaceIdiomPhone: {
			
				break;
			
			}
		
		}
		
		commentsItem.block = ^ {
		
			[nrSelf presentCommentsViewController:[[nrSelf newArticleCommentsController] autorelease] sender:commentsItem];
			
		};
		
		[commentsItem irBind:@"title" toObject:self keyPath:@"article.comments.@count" options:[NSDictionary dictionaryWithObjectsAndKeys:
		
			[[ ^ (id inOldValue, id inNewValue, NSString *changeKind) {
			
				NSUInteger numberOfComments = [inNewValue isKindOfClass:[NSNumber class]] ? [(NSNumber *)inNewValue unsignedIntegerValue] : 0;
				
				return [NSString stringWithFormat:(numberOfComments == 0) ?
					NSLocalizedString(@"COMMENTS_COUNT_ZERO_FORMAT_STRING", @"“%@ Comment” or “No Comment”") :
						(numberOfComments == 1) ?
							NSLocalizedString(@"COMMENTS_COUNT_ONE_FORMAT_STRING", @"“%@ Comment”") :
								NSLocalizedString(@"COMMENTS_COUNT_MANY_FORMAT_STRING", @"“%@ Comments”"), inNewValue];
			
			} copy] autorelease], kIRBindingsValueTransformerBlock,
		
		nil]];
		
		[self irPerformOnDeallocation:^{
		
			[commentsItem irUnbind:@"title"];
			
		}];
		
		return commentsItem;
	
	})());
	
	switch ([UIDevice currentDevice].userInterfaceIdiom) {
		
		case UIUserInterfaceIdiomPad: {
			
			self.headerBarButtonItems = [NSArray arrayWithObjects:
				articleDateItem,
				[IRBarButtonItem itemWithSystemItem:UIBarButtonSystemItemFlexibleSpace wiredAction:nil],
				commentsItem,
			nil];
			
			break;
			
		}
		
		case UIUserInterfaceIdiomPhone: {
			
			self.headerBarButtonItems = [NSArray arrayWithObjects:articleDateItem, nil];
			self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:commentsItem, nil];
			
			break;
			
		}
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWindowInterfaceBoundsDidChange:) name:IRWindowInterfaceBoundsDidChangeNotification object:nil];
	
	self.foldsTextStackCell = YES;
		
	return self;

}

- (void) dealloc {

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[commentsPopover dismissPopoverAnimated:NO];

	[headerView release];
	[topCell release];
	[textStackCell release];
	[commentsVC release];
	[commentsPopover release];
	[stackView release];
	[wrapperView release];
	[onViewDidLoad release];
	[onPullTop release];
	[footerCell release];
	
	[textStackCellFoldingToggleWrapperView release];
	[textStackCellFoldingToggle release];
	
	[super dealloc];

}

- (WAArticleTextStackElement *) textStackCell {

	if (textStackCell)
		return textStackCell;
		
	textStackCell = [[WAArticleTextStackElement cellFromNib] retain];
	
	[textStackCell.textStackCellLabel irBind:@"text" toObject:self.article keyPath:@"text" options:[NSDictionary dictionaryWithObjectsAndKeys:
		(id)kCFBooleanTrue, kIRBindingsAssignOnMainThreadOption,
	nil]];
	
	textStackCell.delegate = self;

	return textStackCell;

}

- (void) textStackElement:(WAArticleTextStackElement *)element didRequestContentSizeToggle:(id)sender {

	self.foldsTextStackCell = !self.foldsTextStackCell;
	[self.stackView setNeedsLayout];
	
	CGSize oldContentSize = self.stackView.contentSize;
	
	[UIView animateWithDuration:0.3 animations:^{
		
		[self.stackView layoutSubviews];
		
		CGSize newContentSize = self.stackView.contentSize;
		
		if (oldContentSize.height > newContentSize.height)
			[self.stackView setContentOffset:CGPointZero];
		
	}];

}

- (UIView *) textStackCellFoldingToggleWrapperView {

	if (textStackCellFoldingToggleWrapperView)
		return textStackCellFoldingToggleWrapperView;
		
	textStackCellFoldingToggleWrapperView = [[WAView alloc] initWithFrame:(CGRect){ CGPointZero, (CGSize){ 320, 0 }}];
	[textStackCellFoldingToggleWrapperView addSubview:self.textStackCellFoldingToggle];
	
	__block __typeof__(textStackCellFoldingToggleWrapperView) nrWrapper = textStackCellFoldingToggleWrapperView;
	__block __typeof__(self.textStackCellFoldingToggle) nrToggle = self.textStackCellFoldingToggle;
	
	[(WAView *)textStackCellFoldingToggleWrapperView setOnHitTestWithEvent: ^ (CGPoint point, UIEvent *event, UIView *superAnswer) {
		return [nrToggle hitTest:[nrToggle convertPoint:point fromView:nrWrapper] withEvent:event];
	}];

	self.textStackCellFoldingToggle.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin;	
	self.textStackCellFoldingToggle.frame = CGRectOffset(IRGravitize(textStackCellFoldingToggleWrapperView.bounds, self.textStackCellFoldingToggle.bounds.size, kCAGravityTopRight), -8, 24);
	
	return textStackCellFoldingToggleWrapperView;

}

- (UIButton *) textStackCellFoldingToggle {

	if (textStackCellFoldingToggle)
		return textStackCellFoldingToggle;
		
	textStackCellFoldingToggle = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
	[textStackCellFoldingToggle addTarget:self action:@selector(handleTextStackCellFoldingToggleTap:) forControlEvents:UIControlEventTouchUpInside];
	
	[self.textStackCellFoldingToggle setContentEdgeInsets:(UIEdgeInsets){ 0, 16, 0, 16 }];
	[self.textStackCellFoldingToggle setTitleEdgeInsets:(UIEdgeInsets){ -2, -4, 2, 4 }];
	[self.textStackCellFoldingToggle setImageEdgeInsets:(UIEdgeInsets){ -2, -4, 2, 4 }];
	[self.textStackCellFoldingToggle setTitleColor:[UIColor colorWithWhite:0.5 alpha:1] forState:UIControlStateNormal];
	//	[self.textStackCellFoldingToggle setTitleColor:[UIColor colorWithWhite:1 alpha:1] forState:UIControlStateHighlighted];
	[self.textStackCellFoldingToggle setAdjustsImageWhenHighlighted:NO];
	[self.textStackCellFoldingToggle.titleLabel setFont:[UIFont boldSystemFontOfSize:14.0]];
	
	UIImage *normalImage = [[UIImage imageNamed:@"WAArticleStackElementDropdownTag"] resizableImageWithCapInsets:(UIEdgeInsets){ 0, 8, 8, 8 }];
	UIImage *pressedImage = [[UIImage imageNamed:@"WAArticleStackElementDropdownTagPressed"] resizableImageWithCapInsets:(UIEdgeInsets){ 0, 8, 8, 8 }];
	UIImage *disabledImage = [[UIImage imageNamed:@"WAArticleStackElementDropdownTagDisabled"] resizableImageWithCapInsets:(UIEdgeInsets){ 0, 8, 8, 8 }];
	
	[self.textStackCellFoldingToggle setBackgroundImage:normalImage forState:UIControlStateNormal];
	[self.textStackCellFoldingToggle setBackgroundImage:pressedImage forState:UIControlStateHighlighted];
	[self.textStackCellFoldingToggle setBackgroundImage:disabledImage forState:UIControlStateDisabled];
	
	[self configureTextStackCellFoldingToggle];
	
	return textStackCellFoldingToggle;

}

- (void) configureTextStackCellFoldingToggle {

	if (self.foldsTextStackCell) {

		[self.textStackCellFoldingToggle setTitle:@"More" forState:UIControlStateNormal];
		[self.textStackCellFoldingToggle setImage:[[UIImage imageNamed:@"WADownDoubleArrowGlyph"] irSolidImageWithFillColor:[UIColor colorWithWhite:0.5 alpha:1] shadow:nil] forState:UIControlStateNormal];
		//	[self.textStackCellFoldingToggle setImage:[[UIImage imageNamed:@"WADownDoubleArrowGlyph"] irSolidImageWithFillColor:[UIColor colorWithWhite:1 alpha:1] shadow:nil] forState:UIControlStateHighlighted];
	
	} else {
	
		[self.textStackCellFoldingToggle setTitle:@"Less" forState:UIControlStateNormal];
		[self.textStackCellFoldingToggle setImage:[[UIImage imageNamed:@"WAUpDoubleArrowGlyph"] irSolidImageWithFillColor:[UIColor colorWithWhite:0.5 alpha:1] shadow:nil] forState:UIControlStateNormal];
		//	[self.textStackCellFoldingToggle setImage:[[UIImage imageNamed:@"WAUpDoubleArrowGlyph"] irSolidImageWithFillColor:[UIColor colorWithWhite:1 alpha:1] shadow:nil] forState:UIControlStateHighlighted];
	
	}
	
	CGSize fittingSize = [self.textStackCellFoldingToggle sizeThatFits:self.textStackCellFoldingToggle.bounds.size];
	fittingSize.height = MAX(44, fittingSize.height);
	
	self.textStackCellFoldingToggle.bounds = (CGRect){ CGPointZero, fittingSize };
	[self.textStackCellFoldingToggle.superview layoutSubviews];

}

- (void) handleTextStackCellFoldingToggleTap:(id)sender {

	self.foldsTextStackCell = !self.foldsTextStackCell;

	[self configureTextStackCellFoldingToggle];	
	
	BOOL hecklesContentOffset = self.foldsTextStackCell;
	
	CGFloat oldContentHeightLeft = self.stackView.contentSize.height - self.stackView.contentOffset.y;
	
	[self.stackView layoutSubviews];
	
	if (hecklesContentOffset) {

		[self.stackView setContentOffset:(CGPoint){
			self.stackView.contentOffset.x,
			MAX(0, self.stackView.contentSize.height - oldContentHeightLeft)
		} animated:NO];
	
	}
	
	if (self.foldsTextStackCell)
		[self.stackView setContentOffset:CGPointZero animated:YES];

}

- (WAArticleCommentsViewController *) newArticleCommentsController {

	return [self.commentsVC retain];

}

- (void) presentCommentsViewController:(WAArticleCommentsViewController *)controller sender:(id)sender {

	switch ([UIDevice currentDevice].userInterfaceIdiom) {
	
		case UIUserInterfaceIdiomPad: {
		
			NSParameterAssert(self.commentsPopover);
		
			if ([self.commentsPopover isPopoverVisible]) {
				
				//	Toggle
				
				[self.commentsPopover dismissPopoverAnimated:NO];
				
				return;
				
			}
			
			if ([sender isKindOfClass:[UIBarButtonItem class]]) {
			
				[self.commentsPopover presentPopoverFromBarButtonItem:((UIBarButtonItem *)sender) permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
			
			} else if ([sender isKindOfClass:[UIView class]]) {
			
				[self.commentsPopover presentPopoverFromRect:((UIView *)sender).bounds inView:((UIView *)sender) permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
			
			}
		
			break;
		
		}
		
		case UIUserInterfaceIdiomPhone: {
		
			[self.navigationController pushViewController:controller animated:YES];
		
			break;
		
		}
	
	}

}

- (UIPopoverController *) commentsPopover {

	if (commentsPopover)
		return commentsPopover;
	
	commentsPopover = [[UIPopoverController alloc] initWithContentViewController:
		self.commentsVC
		//	[[[UINavigationController alloc] initWithRootViewController:self.commentsVC
	];
	
	__block UIViewController *nrContentVC = commentsPopover.contentViewController;
	
	__block id nrHelper = [nrContentVC irAddObserverBlock:^(id inOldValue, id inNewValue, NSKeyValueChange changeKind) {
		
		//	NSLog(@"%@ %@ %x", inOldValue, inNewValue, changeKind);
		
	} forKeyPath:@"contentSizeForViewInPopover" options:NSKeyValueObservingOptionNew context:nil];
	
	[nrContentVC irPerformOnDeallocation:^{
	
		[nrContentVC irRemoveObservingsHelper:nrHelper];
		
	}];
	
	self.commentsVC.adjustsContainerViewOnInterfaceBoundsChange = NO;

	return commentsPopover;

}

- (WAArticleCommentsViewController *) commentsVC {

	if (commentsVC)
		return commentsVC;
	
	commentsVC = [[WAArticleCommentsViewController controllerRepresentingArticle:[[self.article objectID] URIRepresentation]] retain];
	commentsVC.delegate = self;
	
	//	__block __typeof__(commentsVC) nrCommentsVC = commentsVC;

	//	commentsVC.onViewDidLoad = ^ {
	//		
	//		nrCommentsVC.view.clipsToBounds = YES;
	//		nrCommentsVC.view.layer.shadowOpacity = 0;
	//		
	//		nrCommentsVC.commentsRevealingActionContainerView.hidden = YES;
	//		nrCommentsVC.commentsView.backgroundColor = nil;
	//		nrCommentsVC.commentsView.bounces = NO;
	//		nrCommentsVC.commentsView.opaque = NO;
	//		nrCommentsVC.commentsView.frame = CGRectInset(nrCommentsVC.commentsView.frame, 64, 0);
	//		
	//		nrCommentsVC.compositionAccessoryView.frame = CGRectInset(nrCommentsVC.compositionAccessoryView.frame, 64, 0);
	//		
	//		WAView *compositionBackgroundView = nrCommentsVC.compositionAccessoryBackgroundView;
	//		for (UIView *aSubview in compositionBackgroundView.subviews)
	//			[aSubview removeFromSuperview];
	//		
	//		compositionBackgroundView.backgroundColor = [UIColor whiteColor];
	//		
	//		UIView *backgroundView = WAStandardArticleStackCellCenterBackgroundView();
	//		backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	//		
	//		UIView *backgroundWrapperView = [[[UIView alloc] initWithFrame:nrCommentsVC.commentsView.bounds] autorelease];
	//		backgroundWrapperView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	//		backgroundView.frame = CGRectInset(backgroundWrapperView.bounds, -64, 0);
	//		[backgroundWrapperView addSubview:backgroundView];
	//				
	//		nrCommentsVC.commentsView.backgroundView = backgroundWrapperView;
	//		nrCommentsVC.commentsView.backgroundColor = nil;
	//		nrCommentsVC.commentsView.opaque = NO;
	//		nrCommentsVC.commentsView.clipsToBounds = NO;
	//		
	//		[backgroundView.superview sendSubviewToBack:backgroundView]; 
	//		
	//	};
	
	return commentsVC;
	
}

- (BOOL) stackView:(WAStackView *)aStackView shouldStretchElement:(UIView *)anElement {

//	if ([commentsVC isViewLoaded])
//	if (anElement == commentsVC.view)
//		return YES;
//	
	return NO;

}

- (CGSize) sizeThatFitsElement:(UIView *)anElement inStackView:(WAStackView *)aStackView {

	CGSize elementAnswer = [anElement sizeThatFits:(CGSize){
		CGRectGetWidth(aStackView.bounds),
		0
	}];
	
	CGFloat preferredHeight = roundf(elementAnswer.height);
	
	if ((anElement == self.commentsVC.view) || [self.commentsVC.view isDescendantOfView:anElement])
		preferredHeight = MAX(144, preferredHeight);
	
	if (foldsTextStackCell)
	if ((anElement == self.textStackCell) || [self.textStackCell isDescendantOfView:anElement])
		preferredHeight = MIN(144, preferredHeight);
	
	return (CGSize){
		CGRectGetWidth(aStackView.bounds),
		preferredHeight
	};

}

- (void) articleCommentsViewController:(WAArticleCommentsViewController *)controller wantsState:(WAArticleCommentsViewControllerState)aState onFulfillment:(void (^)(void))aCompletionBlock {

	//	Immediate fulfillment. :D
	
	if (aCompletionBlock)
		aCompletionBlock();

}

- (BOOL) articleCommentsViewController:(WAArticleCommentsViewController *)controller canSendComment:(NSString *)commentText {

	return !![[commentText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length];

}

- (void) articleCommentsViewController:(WAArticleCommentsViewController *)controller didFinishComposingComment:(NSString *)commentText {

	__block WAOverlayBezel *nrBezel = [[WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle] retain];
	[nrBezel showWithAnimation:WAOverlayBezelAnimationFade];
	
	[[WADataStore defaultStore] addComment:commentText onArticle:[[self.article objectID] URIRepresentation] onSuccess:^{
		
		dispatch_async(dispatch_get_main_queue(), ^{
		
			[nrBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
			[nrBezel autorelease];
			
		});
		
	} onFailure:^{
	
		dispatch_async(dispatch_get_main_queue(), ^{
		
			[nrBezel dismissWithAnimation:WAOverlayBezelAnimationNone];		
			[nrBezel autorelease];
			
			nrBezel = [[WAOverlayBezel bezelWithStyle:WAErrorBezelStyle] retain];
			[nrBezel showWithAnimation:WAOverlayBezelAnimationNone];
			
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
				
				[nrBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
				[nrBezel autorelease];
				
			});
			
		});
		
	}];
	

}

- (void) articleCommentsViewControllerDidBeginComposition:(WAArticleCommentsViewController *)controller {

	//	Scroll to critical area
	
	[self.stackView layoutSubviews];
	[controller.view layoutSubviews];
	CGRect criticalRect = [self.stackView convertRect:[controller rectForComposition] fromView:controller.view];
	[self.stackView scrollRectToVisible:criticalRect animated:NO];
	
}

- (void) articleCommentsViewControllerDidFinishComposition:(WAArticleCommentsViewController *)controller {

	[self.stackView layoutSubviews];

}

- (void) articleCommentsViewController:(WAArticleCommentsViewController *)controller didChangeContentSize:(CGSize)newSize {

	[self.stackView setNeedsLayout];
	
	if ([self isViewLoaded] && self.view.window) {

		UIViewAnimationOptions animationOptions = UIViewAnimationOptionBeginFromCurrentState;	
		[UIView animateWithDuration:0.3 delay:0 options:animationOptions animations:^{		
		
			[self.stackView layoutSubviews];
			
		} completion:^(BOOL finished) {
			
			[self.stackView setNeedsLayout];
			
		}];
	
	}

}

- (void) adjustWrapperViewBoundsWithWindowInterfaceBounds:(CGRect)newInterfaceBounds animated:(BOOL)animate {

	if (!self.view.window)
		return;

	CGRect ownRectInWindow = [self.view.window convertRect:self.view.bounds fromView:self.view];
	CGRect intersection = CGRectIntersection(ownRectInWindow, newInterfaceBounds);
	
	if (CGRectEqualToRect(CGRectNull, intersection) || CGRectIsInfinite(intersection))
		return;
	
	intersection = [self.view.window convertRect:intersection toView:self.wrapperView.superview];
	
	UIViewAnimationOptions animationOptions = UIViewAnimationOptionBeginFromCurrentState;
	
	[UIView animateWithDuration:(animate ? 0.3 : 0) delay:0 options:animationOptions animations:^{
		
		self.wrapperView.frame = intersection;
		[self.stackView layoutSubviews];
		
	} completion:^(BOOL finished) {
		
		//	NSLog(@"STACK VIEW now %@, super view %@", self.stackView, self.stackView.superview);
		
	}];

}

- (void) viewDidLoad {

	[super viewDidLoad];
	
	__block __typeof__(self) nrSelf = self;
	
	self.wrapperView = [[[UIView alloc] initWithFrame:self.stackView.frame] autorelease];
	[self.stackView.superview addSubview:self.wrapperView];
	[self.wrapperView addSubview:self.stackView];
	self.stackView.frame = self.wrapperView.bounds;
	self.wrapperView.frame = self.view.bounds;
	self.wrapperView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.stackView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;

	self.stackView.bounces = YES;
	self.stackView.alwaysBounceHorizontal = NO;	
	self.stackView.alwaysBounceVertical = YES;
	self.stackView.showsHorizontalScrollIndicator = NO;	
	self.stackView.showsVerticalScrollIndicator = NO;
	
	if (headerView) {
	
		NSMutableArray *stackElements = [self.stackView mutableStackElements];
	
		if ([stackElements containsObject:headerView])
			return;
		
		[stackElements insertObject:headerView atIndex:0];
		
		UIView *enclosingView = [[[UIView alloc] initWithFrame:(CGRect){ 0, 0, CGRectGetWidth(headerView.bounds), 0 }] autorelease];
		UIView *topBackgroundView = WAStandardArticleStackCellTopBackgroundView();
		[enclosingView addSubview:topBackgroundView];
		topBackgroundView.frame = IRGravitize(enclosingView.bounds, headerView.bounds.size, kCAGravityBottom);
		topBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
		
		[stackElements insertObject:enclosingView atIndex:1];
	
	} else {
	
		switch ([UIDevice currentDevice].userInterfaceIdiom) {
		
			case UIUserInterfaceIdiomPad: {
			
				WAArticleTextStackCell *topTextStackCell = [WAArticleTextStackCell cellFromNib];
				topTextStackCell.backgroundView = WAStandardArticleStackCellTopBackgroundView();
				topTextStackCell.frame = (CGRect){ CGPointZero, (CGSize){ CGRectGetWidth(topCell.bounds), 48 }};
				
				self.headerView = topTextStackCell;
				
				break;
			
			}
			
			case UIUserInterfaceIdiomPhone: {
			
				WAArticleTextStackCell *topTextStackCell = [WAArticleTextStackCell cellFromNib];
				topTextStackCell.backgroundView = WAStandardArticleStackCellTopBackgroundView();
				topTextStackCell.frame = (CGRect){ CGPointZero, (CGSize){ CGRectGetWidth(topCell.bounds), 24 }};
				
				self.headerView = topTextStackCell;
				
				break;
			
			}
		
		}
		
	}
		
	BOOL hasText = [self.article.text length];
	BOOL showsComments = NO;
	
	if (hasText) {
		
		[self.stackView addStackElementsObject:self.textStackCell];
		
		CGFloat currentTextStackCellHeight = [self sizeThatFitsElement:self.textStackCell inStackView:self.stackView].height;
		CGFloat idealTextStackCellHeight = [self.textStackCell sizeThatFits:(CGSize){ CGRectGetWidth(self.stackView.bounds), 0 }].height;
		
		if (self.foldsTextStackCell && (idealTextStackCellHeight > currentTextStackCellHeight))
			[self.stackView addStackElementsObject:self.textStackCellFoldingToggleWrapperView];
		
	}
	
	if (showsComments) {
		if (hasText) {
			WAArticleTextStackCell *commentsSeparatorCell = [WAArticleTextStackCell cellFromNib];
			commentsSeparatorCell.backgroundView = WAStandardArticleStackCellCenterBackgroundView();
			commentsSeparatorCell.frame = (CGRect){ CGPointZero, (CGSize){ CGRectGetWidth(commentsSeparatorCell.bounds), 24 }};
			[self.stackView addStackElementsObject:commentsSeparatorCell];
		}
		[self.stackView addStackElementsObject:self.commentsVC.view];
	}

	WAArticleTextStackCell *contentsSeparatorCell = [WAArticleTextStackCell cellFromNib];
	contentsSeparatorCell.backgroundView = WAStandardArticleStackCellCenterBackgroundView();
	contentsSeparatorCell.frame = (CGRect){ CGPointZero, (CGSize){ CGRectGetWidth(contentsSeparatorCell.bounds), 24 }};
	[self.stackView addStackElementsObject:contentsSeparatorCell];
	
#if 0
	
	self.wrapperView.layer.borderColor = [UIColor redColor].CGColor;
	self.wrapperView.layer.borderWidth = 1;
	
	self.stackView.layer.borderColor = [UIColor greenColor].CGColor;
	self.stackView.layer.borderWidth = 2;
	
	self.commentsVC.view.layer.borderColor = [UIColor blueColor].CGColor;
	self.commentsVC.view.layer.borderWidth = 2.0;
	
#endif

	[self.stackView addStackElementsObject:self.footerCell];
	
	self.stackView.backgroundColor = nil;
	self.wrapperView.backgroundColor = nil;

	self.stackView.onDidLayoutSubviews = ^ {
		
		[nrSelf.textStackCellFoldingToggleWrapperView.superview bringSubviewToFront:nrSelf.textStackCellFoldingToggleWrapperView];
		
		switch ([UIDevice currentDevice].userInterfaceIdiom) {
		
			case UIUserInterfaceIdiomPad: {
			
				[nrSelf.headerView.superview bringSubviewToFront:nrSelf.headerView];
				
				nrSelf.headerView.center = (CGPoint){
					nrSelf.headerView.center.x,
					MAX(0, nrSelf.stackView.contentOffset.y) + 0.5 * CGRectGetHeight(nrSelf.headerView.bounds)
				};
				
				break;
			
			}
			
			case UIUserInterfaceIdiomPhone: {
			
				break;
			
			}
		
		}
		
	};

	if (self.onViewDidLoad)
		self.onViewDidLoad(self, self.view);
	
}

- (void) setHeaderView:(UIView *)newHeaderView {

	if (headerView == newHeaderView)
		return;
	
	NSMutableArray *allStackElements = [self.stackView mutableStackElements];
	
	if ([allStackElements containsObject:headerView]) {
		[headerView removeFromSuperview];
		[allStackElements removeObject:headerView];
	}
	
	[headerView release];
	headerView = [newHeaderView retain];
	
	if (![allStackElements containsObject:headerView]) {
		[allStackElements insertObject:headerView atIndex:0];
	}
	
	[self.stackView setNeedsLayout];

}

- (UIView *) footerCell {

	if (footerCell)
		return footerCell;
	
	WAArticleTextStackCell *footerShadow = [WAArticleTextStackCell cellFromNib];
	footerShadow.backgroundView = WAStandardArticleStackCellBottomBackgroundView();
	footerShadow.frame = (CGRect){ CGPointZero, (CGSize){ CGRectGetWidth(footerShadow.bounds), 1024 }};
	
	footerCell = [[UIView alloc] initWithFrame:(CGRect){
		CGPointZero,
		(CGSize){
			CGRectGetWidth(footerShadow.bounds),
			0
		}
	}];
	
	footerShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
	[footerCell addSubview:footerShadow];
	
	return footerCell;

}

- (void) viewDidUnload {

	self.stackView = nil;
	self.commentsVC = nil;
	self.commentsPopover = nil;
	
	self.textStackCellFoldingToggleWrapperView = nil;
	self.textStackCellFoldingToggle = nil;
	
	[super viewDidUnload];
	
}

- (void) viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];
	[self.commentsVC viewWillAppear:animated];
	
	//	dispatch_async(dispatch_get_main_queue(), ^{
	
		[self.stackView layoutSubviews];
		
	//	});

}

- (void) viewDidAppear:(BOOL)animated {

	[super viewDidAppear:animated];
	[self.commentsVC viewDidAppear:animated];
	
}

- (void) viewWillDisappear:(BOOL)animated {

	[super viewWillDisappear:animated];
	[self.commentsVC viewWillDisappear:animated];

}

- (void) viewDidDisappear:(BOOL)animated {

	[super viewDidDisappear:animated];
	[self.commentsVC viewDidDisappear:animated];
	
}

- (void) handleWindowInterfaceBoundsDidChange:(NSNotification *)notification {

	if (![self isViewLoaded])
		return;
	
	if ([notification object] != self.view.window)
		return;
	
	[self adjustWrapperViewBoundsWithWindowInterfaceBounds:self.view.window.irInterfaceBounds animated:([[[[[notification userInfo] objectForKey:IRWindowInterfaceChangeUnderlyingKeyboardNotificationKey] userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue] > 0)];

}

- (void) handlePreferredInterfaceRect:(CGRect)aRect {

	CGRect intersection = CGRectIntersection(aRect, self.stackView.superview.bounds);
	self.stackView.frame = intersection;
	self.stackView.contentInset = (UIEdgeInsets){
		CGRectGetMinY(intersection) - CGRectGetMinY(aRect),
		0,
		0,
		0
	};
	
}

- (BOOL) isPointInsideInterfaceRect:(CGPoint)aPoint { 

	CGRect stackViewFrame = [self.view convertRect:self.stackView.bounds fromView:self.stackView];
	
	if (self.stackView.contentOffset.y > CGRectGetMinY(stackViewFrame))
		return YES;
	
	return CGRectContainsPoint(stackViewFrame, aPoint);

}

#if 0

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
	self.stackView.backgroundColor = [UIColor whiteColor];

}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {

	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

	self.stackView.backgroundColor = nil;

}

- (void) scrollViewWillBeginDragging:(UIScrollView *)scrollView {

	if (scrollView == self.stackView) {
	
		[self.stackView beginPostponingStackElementLayout];
	
	}

}

- (void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {

	if (scrollView == self.stackView) {
	
		if (!decelerate)
			[self.stackView endPostponingStackElementLayout];
		
	}
	
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView {

	if (scrollView == self.stackView) {
	
		[self.stackView endPostponingStackElementLayout];
	
	}
	
}


#endif

- (void) scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {

	if (scrollView == self.stackView) {

		NSParameterAssert(scrollView == self.stackView);
		
		CGPoint contentOffset = self.stackView.contentOffset;
		CGFloat cap = -200.0f;
		
		if (contentOffset.y < cap) {
			if (self.onPullTop)
				self.onPullTop(self.stackView);
		}
	
	}
	
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {

	if (scrollView == self.stackView) {
	
		WAStackView *sv = self.stackView;
		CGPoint oldSVOffset = sv.contentOffset;
		CGPoint newSVOffset = (CGPoint){
			oldSVOffset.x,
			MIN(sv.contentSize.height - CGRectGetHeight(sv.bounds), oldSVOffset.y)
		};
			
		if (!CGPointEqualToPoint(oldSVOffset, newSVOffset))
			[sv setContentOffset:newSVOffset animated:NO];
		
	}
	
}

- (void) scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(CGPoint *)targetContentOffset {

	if (scrollView == self.stackView) {

		CGPoint desiredTargetOffset = *targetContentOffset;
		desiredTargetOffset.y = MIN(desiredTargetOffset.y, self.stackView.contentSize.height - CGRectGetHeight(self.stackView.bounds));
		*targetContentOffset = desiredTargetOffset;
	
	}

}

- (UIView *) scrollableStackElementWrapper {

	return nil;

}

- (UIScrollView *) scrollableStackElement {

	return nil;

}

@end
