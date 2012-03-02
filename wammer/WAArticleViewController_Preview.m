//
//  WAArticleViewController_Preview.m
//  wammer
//
//  Created by Evadne Wu on 1/30/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAArticleViewController_Preview.h"
#import "WADataStore.h"

#import "WAScrollView.h"

#import "WADefines.h"

#import "UIView+IRAdditions.h"
#import "UIScrollView+IRAdditions.h"

#import <UIKit/UIGestureRecognizerSubclass.h>


enum {

	WAArticleViewControllerSummaryState,
	WAArticleViewControllerWebState,
	
	WAArticleViewControllerDefaultState = WAArticleViewControllerSummaryState

}; typedef NSUInteger WAArticleViewControllerState;


@interface WAArticleViewController_Preview () <UIWebViewDelegate, UIGestureRecognizerDelegate>

- (WAPreview *) preview;

@property (nonatomic, readwrite, assign) WAArticleViewControllerState state;

@property (nonatomic, readwrite, retain) UIWebView *webView;
@property (nonatomic, readwrite, retain) UIWebView *summaryWebView;
@property (nonatomic, readwrite, retain) UIView *webViewWrapper;

@property (nonatomic, readwrite, retain) UIActivityIndicatorView *webViewActivityIndicator;
@property (nonatomic, readwrite, retain) IRBarButtonItem *webViewBackBarButtonItem;
@property (nonatomic, readwrite, retain) IRBarButtonItem *webViewForwardBarButtonItem;
@property (nonatomic, readwrite, retain) IRBarButtonItem *webViewActivityIndicatorBarButtonItem;
@property (nonatomic, readwrite, retain) IRBarButtonItem *webViewReloadBarButtonItem;

- (UIView *) wrappedView;
- (void) updateWrapperView;

- (void) updateWebViewBarButtonItems;

@property (nonatomic, readwrite, retain) WAPreviewBadge *previewBadge;
@property (nonatomic, readwrite, retain) UIView *previewBadgeWrapper;

- (void) handleStackViewPanGesture:(UIPanGestureRecognizer *)aPanGestureRecognizer;
- (void) handleWebScrollViewPanGesture:(UIPanGestureRecognizer *)aPanGestureRecognizer;

@property (nonatomic, readwrite, assign) CGPoint lastStackViewContentOffset;
@property (nonatomic, readwrite, assign) CGPoint lastWebScrollViewContentOffset;
@property (nonatomic, readwrite, assign) UIGestureRecognizerState lastWebScrollViewPanGestureRecognizerState;
@property (nonatomic, readwrite, assign) CGRect lastWebViewFrame;

- (NSArray *) previewActionsWithSender:(UIBarButtonItem *)sender;
@property (nonatomic, readwrite, retain) IRActionSheetController *previewActionSheetController;

@end


@implementation WAArticleViewController_Preview
@synthesize state;
@synthesize webView, summaryWebView, webViewWrapper, previewBadge, previewBadgeWrapper;
@synthesize webViewActivityIndicator, webViewBackBarButtonItem, webViewForwardBarButtonItem, webViewActivityIndicatorBarButtonItem, webViewReloadBarButtonItem;
@synthesize lastStackViewContentOffset, lastWebScrollViewContentOffset, lastWebScrollViewPanGestureRecognizerState, lastWebViewFrame;
@synthesize previewActionSheetController;

- (void) dealloc {

	NSURLRequest *blankRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]];
	
	[webView setDelegate:nil];
	[webView loadRequest:blankRequest];
	[webView setDelegate:self];
	
	[summaryWebView setDelegate:nil];
	[summaryWebView loadRequest:blankRequest];
	[summaryWebView setDelegate:self];

	webView.delegate = nil;
	summaryWebView.delegate = nil;
	
	[webView release];
	[summaryWebView release];
	[webViewWrapper release];
	
	[webViewActivityIndicator release];
	[webViewBackBarButtonItem release];
	[webViewForwardBarButtonItem release];
	[webViewActivityIndicatorBarButtonItem release];
	[webViewReloadBarButtonItem release];

	[previewBadge release];
	[previewBadgeWrapper release];
	
	[previewActionSheetController release];
	
	[super dealloc];

}

- (void) didReceiveMemoryWarning {

	if ([self isViewLoaded]) {
	
		if (!summaryWebView.superview)
			self.summaryWebView = nil;
		
		if (!webView.superview)
			self.webView = nil;
	
	}

	[super didReceiveMemoryWarning];
	
}

- (WAPreview *) preview {

	return (WAPreview *)[self.article.previews anyObject];

}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (!self)
		return nil;
	
	self.state = WAArticleViewControllerSummaryState;
	
	return self;

}

- (void) viewDidLoad {

	[super viewDidLoad];
	
	__block __typeof__(self) nrSelf = self;
	
	WAPreview *anyPreview = [self preview];
	
	if (!anyPreview)
		return;
		
	NSMutableArray *stackElements = [self.stackView mutableStackElements];
	
	//	self.previewBadge.preview = anyPreview;
	//	self.previewBadge.link = nil;
	//	
	//	[stackElements insertObject:self.previewBadgeWrapper atIndex:(
	//		[stackElements containsObject:(id)self.textStackCell] ? [stackElements indexOfObject:(id)self.textStackCell] : [stackElements count]
	//	)];
			
	[stackElements addObject:self.webViewWrapper];
	//	[stackElements addObject:self.toolbar];
	

	self.stackView.delaysContentTouches = YES;
	self.stackView.canCancelContentTouches = YES;

	self.stackView.delaysContentTouches = NO;
	self.stackView.canCancelContentTouches = YES;
	self.stackView.onTouchesShouldCancelInContentView = ^ (UIView *view) {
	
		UIView *wrappedView = [nrSelf wrappedView];
	
		if (wrappedView)
		if ((view == wrappedView) || [view isDescendantOfView:wrappedView])
			return NO;
		
		return YES;
	
	};
	
	self.stackView.onGestureRecognizerShouldRecognizeSimultaneouslyWithGestureRecognizer = ^ (UIGestureRecognizer *aGR, UIGestureRecognizer *otherGR, BOOL superAnswer) {
	
		return NO;
	
	};
	
	switch ([UIDevice currentDevice].userInterfaceIdiom) {

		case UIUserInterfaceIdiomPad: {
		
			self.stackView.onDidLayoutSubviews = ^ {
				
				[self.headerView.superview bringSubviewToFront:self.headerView];
				
				self.headerView.center = (CGPoint){
					self.headerView.center.x,
					MAX(0, self.stackView.contentOffset.y) + 0.5 * CGRectGetHeight(self.headerView.bounds)
				};
				
			};
			
			break;
			
		}
		
		case UIUserInterfaceIdiomPhone: {
		
			break;
		
		}
	
	}
	
	if ([self isViewLoaded])
		[self updateWrapperView];

}

- (void) viewDidUnload {

	[super viewDidUnload];
	
	self.webView.delegate = nil;
	self.webView = nil;
	
	self.summaryWebView.delegate = nil;
	self.summaryWebView = nil;
	
	self.webViewWrapper = nil;
	
	self.webViewActivityIndicator = nil;
	self.webViewBackBarButtonItem = nil;
	self.webViewForwardBarButtonItem = nil;
	self.webViewActivityIndicatorBarButtonItem = nil;
	self.webViewReloadBarButtonItem = nil;

	self.previewBadge = nil;
	self.previewBadgeWrapper = nil;
	
	self.previewActionSheetController = nil;

	//	self.toolbar = nil;

}

- (void) viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];
	
	[self.navigationController setToolbarHidden:NO animated:animated];

}

- (void) viewWillDisappear:(BOOL)animated {

	[super viewWillDisappear:animated];
	
	[self.navigationController setToolbarHidden:YES animated:animated];

}

- (UIWebView *) webView {

	if (webView)
		return webView;
	
	webView = [[UIWebView alloc] initWithFrame:CGRectZero];
	
	webView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
	webView.delegate = self;
	webView.scrollView.directionalLockEnabled = NO;
	webView.scrollView.bounces = NO;
	webView.scrollView.alwaysBounceVertical = NO;
	webView.scrollView.alwaysBounceHorizontal = NO;
		
	[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[self preview].graphElement.url]]];
	
	return webView;

}

- (UIWebView *) summaryWebView {

	if (summaryWebView)
		return summaryWebView;
	
	summaryWebView = [[UIWebView alloc] initWithFrame:CGRectZero];
	
	summaryWebView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
	summaryWebView.delegate = self;
	summaryWebView.scrollView.directionalLockEnabled = NO;
	summaryWebView.scrollView.bounces = NO;
	summaryWebView.scrollView.alwaysBounceVertical = NO;
	summaryWebView.scrollView.alwaysBounceHorizontal = NO;
	
	NSString *tidyString = [summaryWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:
	
		@"(function tidy (string) { var element = document.createElement('DIV'); element.innerHTML = string; return element.innerHTML; })(unescape(\"%@\"));",
		[self.article.summary stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
		
	]];
	
	NSString *summaryTemplatePath = [[NSBundle mainBundle] pathForResource:@"WFPreviewTemplate" ofType:@"html"];
	NSString *summaryTemplateDirectoryPath = [summaryTemplatePath stringByDeletingLastPathComponent];

	#if DEBUG
	
		NSFileManager * const fileManager = [NSFileManager defaultManager];
		
		BOOL fileIsDirectory = NO;
		NSParameterAssert([fileManager fileExistsAtPath:summaryTemplatePath isDirectory:&fileIsDirectory] && !fileIsDirectory);
		NSParameterAssert([fileManager fileExistsAtPath:summaryTemplateDirectoryPath isDirectory:&fileIsDirectory] && fileIsDirectory);				
	
	#endif
	
	WAPreview *preview = [self.article.previews anyObject];
	NSString *usedTitle = preview.graphElement.title;
	NSString *usedProviderName = [preview.graphElement providerCaption];
	
	NSString *usedSummary = (tidyString ? tidyString : self.article.summary);
	NSString *templatedSummary = [[[[NSString stringWithContentsOfFile:summaryTemplatePath usedEncoding:NULL error:nil] stringByReplacingOccurrencesOfString:@"$BODY" withString:usedSummary] stringByReplacingOccurrencesOfString:@"$TITLE" withString:usedTitle] stringByReplacingOccurrencesOfString:@"$SOURCE" withString:usedProviderName];
	
	NSURL *summaryTemplateBaseURL = nil;
	
	if (templatedSummary)
		summaryTemplateBaseURL = [NSURL fileURLWithPath:summaryTemplateDirectoryPath];
	
	[summaryWebView loadHTMLString:(templatedSummary ? templatedSummary : usedSummary) baseURL:summaryTemplateBaseURL];
	
	return summaryWebView;

}

- (IRBarButtonItem *) webViewBackBarButtonItem {

	if (webViewBackBarButtonItem)
		return webViewBackBarButtonItem;
	
	__block __typeof__(self) nrSelf = self;
	
	UIColor *glyphColor = [UIColor colorWithWhite:0.3 alpha:1];
				
	UIImage *leftImage = WABarButtonImageWithOptions(@"UIButtonBarArrowLeft", glyphColor, kWADefaultBarButtonTitleShadow);
	UIImage *leftLandscapePhoneImage = WABarButtonImageWithOptions(@"UIButtonBarArrowLeftLandscape", glyphColor, kWADefaultBarButtonTitleShadow);
		
	webViewBackBarButtonItem = [[IRBarButtonItem itemWithCustomImage:leftImage landscapePhoneImage:leftLandscapePhoneImage highlightedImage:nil highlightedLandscapePhoneImage:nil] retain];
	
	webViewBackBarButtonItem.block = ^ {
	
		UIWebView *currentWebView = (UIWebView *)[nrSelf wrappedView];
		
		if (![currentWebView isKindOfClass:[UIWebView class]])
			return;
		
		[currentWebView goBack];
	
	};
	
	return webViewBackBarButtonItem;

}

- (IRBarButtonItem *) webViewForwardBarButtonItem {

	if (webViewForwardBarButtonItem)
		return webViewForwardBarButtonItem;
	
	__block __typeof__(self) nrSelf = self;
		
	UIColor *glyphColor = [UIColor colorWithWhite:0.3 alpha:1];
	
	UIImage *rightImage = WABarButtonImageWithOptions(@"UIButtonBarArrowRight", glyphColor, kWADefaultBarButtonTitleShadow);
	UIImage *rightLandscapePhoneImage = WABarButtonImageWithOptions(@"UIButtonBarArrowRightLandscape", glyphColor, kWADefaultBarButtonTitleShadow);
		
	webViewForwardBarButtonItem = [[IRBarButtonItem itemWithCustomImage:rightImage landscapePhoneImage:rightLandscapePhoneImage highlightedImage:nil highlightedLandscapePhoneImage:nil] retain];
	
	webViewForwardBarButtonItem.block = ^ {
	
		UIWebView *currentWebView = (UIWebView *)[nrSelf wrappedView];
		
		if (![currentWebView isKindOfClass:[UIWebView class]])
			return;
		
		[currentWebView goForward];
	
	};
	
	return webViewForwardBarButtonItem;

}

- (UIActivityIndicatorView *) webViewActivityIndicator {

	if (webViewActivityIndicator)
		return webViewActivityIndicator;
	
	webViewActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[webViewActivityIndicator startAnimating];
	
	return webViewActivityIndicator;

}

- (IRBarButtonItem *) webViewActivityIndicatorBarButtonItem {

	if (webViewActivityIndicatorBarButtonItem)
		return webViewActivityIndicatorBarButtonItem;
	
	webViewActivityIndicatorBarButtonItem = [[IRBarButtonItem itemWithCustomView:self.webViewActivityIndicator] retain];
	
	return webViewActivityIndicatorBarButtonItem;

}

- (BOOL) webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {

	return YES;

}

- (void) webViewDidStartLoad:(UIWebView *)aWebView {

	[self updateWebViewBarButtonItems];

}

- (void) webViewDidFinishLoad:(UIWebView *)aWebView {

	[self updateWebViewBarButtonItems];

}

- (void) webView:(UIWebView *)aWebView didFailLoadWithError:(NSError *)error {

	[self updateWebViewBarButtonItems];

}

- (void) updateWebViewBarButtonItems {

	if (![self isViewLoaded])
		return;
		
	UIWebView *currentWebView = (UIWebView *)[self wrappedView];
	if (![currentWebView isKindOfClass:[UIWebView class]])
		return;
	
	self.webViewReloadBarButtonItem.enabled = !currentWebView.loading;
	self.webViewActivityIndicator.alpha = currentWebView.loading ? 1 : 0;
	
	self.webViewBackBarButtonItem.enabled = currentWebView.canGoBack;
	self.webViewForwardBarButtonItem.enabled = currentWebView.canGoForward;

}

- (UIView *) wrappedView {

	switch (self.state) {
	
		case WAArticleViewControllerSummaryState:
			return self.summaryWebView;
		
		case WAArticleViewControllerWebState:
			return self.webView;
	
	};
	
	return nil;

}

- (UIView *) webViewWrapper {

	if (webViewWrapper)
		return webViewWrapper;
	
	webViewWrapper = [[[WAView alloc] initWithFrame:CGRectZero] autorelease];
	webViewWrapper.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;

	IRGradientView *topShadow = [[[IRGradientView alloc] initWithFrame:IRGravitize(webViewWrapper.bounds, (CGSize){
		CGRectGetWidth(webViewWrapper.bounds),
		3
	}, kCAGravityTop)] autorelease];
	topShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
	[topShadow setLinearGradientFromColor:[UIColor colorWithWhite:0 alpha:0.125] anchor:irTop toColor:[UIColor colorWithWhite:0 alpha:0] anchor:irBottom];
	[webViewWrapper addSubview:topShadow];
	
	__block __typeof__(self) nrSelf = self;
	__block WAView * nrWebViewWrapper = (WAView *)webViewWrapper;
	
	nrWebViewWrapper.onPointInsideWithEvent = ^ (CGPoint aPoint, UIEvent *anEvent, BOOL superAnswer) {
	
		UIView *wrappedView = [nrSelf wrappedView];
		
		if (!wrappedView)
			return superAnswer;
	
		NSCParameterAssert([wrappedView isDescendantOfView:nrWebViewWrapper]);
		
		BOOL customAnswer = CGRectContainsPoint([nrWebViewWrapper convertRect:wrappedView.bounds fromView:wrappedView], aPoint);
		return customAnswer;
	
	};
	
	nrWebViewWrapper.onHitTestWithEvent = ^ (CGPoint aPoint, UIEvent *anEvent, UIView *superAnswer) {
	
		if (![nrWebViewWrapper pointInside:aPoint withEvent:anEvent])
			return superAnswer;
		
		UIView *wrappedView = [nrSelf wrappedView];
		if (!wrappedView)
			return superAnswer;
		
		return [wrappedView hitTest:[wrappedView convertPoint:aPoint fromView:nrWebViewWrapper] withEvent:anEvent];
	
	};

	[self updateWrapperView];
	
	return webViewWrapper;
	
}

- (WAPreviewBadge *) previewBadge {

	if (previewBadge)
		return previewBadge;
	
	previewBadge = [[WAPreviewBadge alloc] initWithFrame:CGRectZero];
	previewBadge.backgroundView = nil;
	previewBadge.titleFont = [UIFont boldSystemFontOfSize:24.0f];
	previewBadge.titleColor = [UIColor colorWithWhite:0.35 alpha:1];
	previewBadge.textFont = [UIFont systemFontOfSize:18.0f];
	previewBadge.textColor = [UIColor colorWithWhite:0.4 alpha:1];
	previewBadge.userInteractionEnabled = NO;
	
	return previewBadge;

}

- (UIView *) previewBadgeWrapper {

	if (previewBadgeWrapper)
		return previewBadgeWrapper;
	
	previewBadgeWrapper = [[[UIView alloc] initWithFrame:(CGRect){
		CGPointZero,
		(CGSize){
			384,
			384
		}
	}] autorelease];
	UIView *backgroundView = WAStandardArticleStackCellCenterBackgroundView();
	backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	backgroundView.frame = previewBadgeWrapper.bounds;
	[previewBadgeWrapper addSubview:backgroundView];
	
	self.previewBadge.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.previewBadge.frame = CGRectInset(previewBadgeWrapper.bounds, 16, 0);
	[previewBadgeWrapper addSubview:self.previewBadge];
	
	return previewBadgeWrapper;

}

- (NSArray *) toolbarItems {

	if ([[super toolbarItems] count])
		return [super toolbarItems];
	
	__block __typeof__(self) nrSelf = self;
	
	self.toolbarItems = ((^ {
	
		NSMutableArray *returnedArray = [NSMutableArray array];
		
		[returnedArray addObject:[IRBarButtonItem itemWithCustomView:((^ {
		
			UISegmentedControl *segmentedControl = [[[UISegmentedControl alloc] initWithItems:nil] autorelease];
			segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
			[segmentedControl addTarget:nrSelf action:@selector(handleSegmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
			
			[segmentedControl insertSegmentWithTitle:@"Summary" atIndex:0 animated:NO];
			[segmentedControl insertSegmentWithTitle:@"Web" atIndex:1 animated:NO];
			
			[segmentedControl setSelectedSegmentIndex:0];
			[segmentedControl sendActionsForControlEvents:UIControlEventValueChanged];
			
			return segmentedControl;
		
		})())]];
		
		BOOL const isPhone = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone;

		[returnedArray addObject:[IRBarButtonItem itemWithSystemItem:UIBarButtonSystemItemFlexibleSpace wiredAction:nil]];
		
		if (isPhone) {
			
			[returnedArray addObject:nrSelf.webViewBackBarButtonItem];
			[returnedArray addObject:nrSelf.webViewForwardBarButtonItem];
			[returnedArray addObject:nrSelf.webViewActivityIndicatorBarButtonItem];

		} else {
			
			[returnedArray addObject:nrSelf.webViewBackBarButtonItem];
			[returnedArray addObject:[IRBarButtonItem itemWithCustomView:[[[UIView alloc] initWithFrame:(CGRect){ 0, 0, 10, 44}] autorelease]]];
			[returnedArray addObject:nrSelf.webViewActivityIndicatorBarButtonItem];
			[returnedArray addObject:[IRBarButtonItem itemWithCustomView:[[[UIView alloc] initWithFrame:(CGRect){ 0, 0, 10, 44}] autorelease]]];
			[returnedArray addObject:nrSelf.webViewForwardBarButtonItem];
			
		}
		
		[returnedArray addObject:[IRBarButtonItem itemWithSystemItem:UIBarButtonSystemItemFlexibleSpace wiredAction:nil]];
		
		[returnedArray addObject:[IRBarButtonItem itemWithSystemItem:UIBarButtonSystemItemAction wiredAction:^(IRBarButtonItem *senderItem) {
		
			IRActionSheet *actionSheet = nrSelf.previewActionSheetController.managedActionSheet;
			
			if (![actionSheet isVisible]) {
			
				nrSelf.previewActionSheetController.otherActions = [self previewActionsWithSender:senderItem];
				[nrSelf.previewActionSheetController.managedActionSheet showFromBarButtonItem:senderItem animated:YES];
				
			}
		
		}]];
		
		return returnedArray;
	
	})());
		
	return self.toolbarItems;

}

- (IRActionSheetController *) previewActionSheetController {

	if (previewActionSheetController)
		return previewActionSheetController;
	
	previewActionSheetController = [[IRActionSheetController actionSheetControllerWithTitle:nil cancelAction:nil destructiveAction:nil otherActions:nil] retain];
	
	return previewActionSheetController;

}

- (NSArray *) previewActionsWithSender:(UIBarButtonItem *)sender {
	
	__block __typeof__(self) nrSelf = self;

	NSMutableArray *returnedActions = [NSMutableArray arrayWithObjects:
	
		[IRAction actionWithTitle:NSLocalizedString(@"ACTION_OPEN_IN_SAFARI", nil) block:^{

			[[UIApplication sharedApplication] openURL:[nrSelf externallyVisibleURL]];
			
		}],
	
	nil];
	
	if ([UIPrintInteractionController isPrintingAvailable]) {
	
		[returnedActions addObject:[IRAction actionWithTitle:NSLocalizedString(@"ACTION_PRINT", nil) block:^{
			
			UIPrintInteractionController *printIC = [UIPrintInteractionController sharedPrintController];
			printIC.printFormatter = [[nrSelf wrappedView] viewPrintFormatter];
			
			UIPrintInteractionCompletionHandler completionHandler = ^ (UIPrintInteractionController *controller, BOOL completed, NSError *error) {
			
			};
			
			switch ([UIDevice currentDevice].userInterfaceIdiom) {
				case UIUserInterfaceIdiomPad: {
					[printIC presentFromBarButtonItem:sender animated:YES completionHandler:completionHandler];
					break;
				}
				case UIUserInterfaceIdiomPhone: {
					[printIC presentAnimated:YES completionHandler:completionHandler];
					break;
				}
			}
		
		}]];
	
	}
	
	return returnedActions;

}

- (NSURL *) externallyVisibleURL {

	if ([self wrappedView] == webView)
		return [NSURL URLWithString:[webView stringByEvaluatingJavaScriptFromString:@"document.location.href"]];

	return [NSURL URLWithString:self.preview.graphElement.url];

}

- (void) setState:(WAArticleViewControllerState)newState {

	BOOL didChange = (state != newState);
	
	if (didChange) {
		[self willChangeValueForKey:@"state"];
		state = newState;
		[self didChangeValueForKey:@"state"];
	}
	
	if ([self isViewLoaded])
		[self updateWrapperView];

}

- (void) updateWrapperView {

	UIView * const wrapperView = self.webViewWrapper;
	UIView * const contentView = [self wrappedView];
	
	if ([contentView isDescendantOfView:wrapperView])
		return;
	
	for (UIView *aSubview in [[wrapperView.subviews copy] autorelease])
	if (aSubview == summaryWebView || aSubview == webView)
		[aSubview removeFromSuperview];
	
	contentView.frame = wrapperView.bounds;
	contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	
	[wrapperView addSubview:contentView];
	[wrapperView sendSubviewToBack:contentView];
	
	[self updateWebViewBarButtonItems];

}

- (void) handleSegmentedControlValueChanged:(UISegmentedControl *)sender {

	WAArticleViewControllerState wantedState = self.state;
	
	switch (sender.selectedSegmentIndex) {
		
		case 0: {
			wantedState = WAArticleViewControllerSummaryState;
			break;
		}
		
		case 1: {
			wantedState = WAArticleViewControllerWebState;
			break;
		}
		
		default: {
			break;
		}
	
	}
	
	self.state = wantedState;

}

- (CGSize) sizeThatFitsElement:(UIView *)anElement inStackView:(WAStackView *)aStackView {

	CGFloat minHeaderSpacing = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad ? 44 : 0;

	if ([[self wrappedView] isDescendantOfView:anElement])
		return (CGSize){ CGRectGetWidth(aStackView.bounds), CGRectGetHeight(aStackView.bounds) - minHeaderSpacing };	//	Stretchable
	
	if ((self.previewBadge == anElement) || [self.previewBadge isDescendantOfView:anElement]) {
	
		UIView *furthestWrapper = [self.previewBadge irAncestorInView:anElement.superview];
		
		CGSize sizeDelta = (CGSize){
			CGRectGetWidth(furthestWrapper.bounds) - CGRectGetWidth(self.previewBadge.bounds),
			CGRectGetHeight(furthestWrapper.bounds) - CGRectGetHeight(self.previewBadge.bounds),
		};
		
		CGSize previewSize = [self.previewBadge sizeThatFits:(CGSize){
			CGRectGetWidth(aStackView.bounds) - sizeDelta.width,
			48 - sizeDelta.height
		}];
		
		return (CGSize){
			//	previewSize.width + sizeDelta.width,
			CGRectGetWidth(aStackView.bounds),
			previewSize.height + sizeDelta.height
		};
		
	}
	
//	if ((self.toolbar == anElement) || [self.toolbar isDescendantOfView:anElement])
//		return (CGSize){ CGRectGetWidth(aStackView.bounds), 44 };

	if ([self irHasDifferentSuperInstanceMethodForSelector:_cmd])
		return [super sizeThatFitsElement:anElement inStackView:aStackView];
	
	return CGSizeZero;	

}

- (BOOL) stackView:(WAStackView *)aStackView shouldStretchElement:(UIView *)anElement {

	if ([[self wrappedView] isDescendantOfView:anElement])
		return YES;
	
	if ([self irHasDifferentSuperInstanceMethodForSelector:_cmd])
		return [super stackView:aStackView shouldStretchElement:anElement];
	
	return NO;

}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];

}

- (void) scrollViewWillBeginDragging:(UIScrollView *)scrollView {

//	[self.stackView beginPostponingStackElementLayout];

	if ([self irHasDifferentSuperClassMethodForSelector:_cmd])
		[super scrollViewWillBeginDragging:scrollView];
	
//	for (UIView *aView in scrollView.subviews)
//		if ([aView isKindOfClass:[UIWebView class]])
//			aView.userInteractionEnabled = NO;
	
	self.lastStackViewContentOffset = self.stackView.contentOffset;
	self.lastWebScrollViewContentOffset = self.webView.scrollView.contentOffset;

}

- (void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {

	if ([self irHasDifferentSuperClassMethodForSelector:_cmd])
		[super scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
	
	if (!decelerate) {
	
//		[self.stackView endPostponingStackElementLayout];
		
//		for (UIView *aView in scrollView.subviews)
//			if ([aView isKindOfClass:[UIWebView class]])
//				aView.userInteractionEnabled = YES;
			
	}
	
}


- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView {

	if ([self irHasDifferentSuperClassMethodForSelector:_cmd])
		[super scrollViewDidEndDecelerating:scrollView];
	
//	[self.stackView endPostponingStackElementLayout];
	
//	for (UIView *aView in scrollView.subviews)
//		if ([aView isKindOfClass:[UIWebView class]])
//			aView.userInteractionEnabled = YES;
	
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {

	if ([self irHasDifferentSuperInstanceMethodForSelector:_cmd])
		[super scrollViewDidScroll:scrollView];

	if (scrollView != self.stackView)
		return;
	
	self.lastWebScrollViewContentOffset = self.webView.scrollView.contentOffset;
		
	UIView *wbWrapper = self.webViewWrapper;
	UIView *wrappedView = [self wrappedView];
	
	CGRect newWebViewFrame = (CGRect){
		CGPointZero,
		(CGSize){
			CGRectGetWidth(wbWrapper.bounds),
			CGRectGetHeight(wbWrapper.bounds) + MAX(0, self.stackView.contentOffset.y + CGRectGetHeight(self.stackView.bounds) - self.stackView.contentSize.height)
		}
	};
		
	if (!CGRectEqualToRect(wrappedView.frame, newWebViewFrame))
		wrappedView.frame = newWebViewFrame;

}

- (void) scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(CGPoint *)targetContentOffset {

	if (scrollView == self.stackView) {

		CGPoint desiredTargetOffset = *targetContentOffset;
		desiredTargetOffset.y = MIN(desiredTargetOffset.y, self.stackView.contentSize.height - CGRectGetHeight(self.stackView.bounds));
		*targetContentOffset = desiredTargetOffset;
	
	}

}

- (void) handleStackViewPanGesture:(UIPanGestureRecognizer *)aPanGestureRecognizer {

	//	NSLog(@"%s %@ %x", __PRETTY_FUNCTION__, aPanGestureRecognizer, aPanGestureRecognizer.state);

}

- (void) handleWebScrollViewPanGesture:(UIPanGestureRecognizer *)aPanGestureRecognizer {

	switch (aPanGestureRecognizer.state) {
	
		case UIGestureRecognizerStateBegan: {
		
			CGPoint currentOffset = self.webView.scrollView.contentOffset;
			CGPoint currentTranslation = [aPanGestureRecognizer translationInView:self.webView.scrollView];
			
			self.lastWebScrollViewContentOffset = (CGPoint){
				currentOffset.x + currentTranslation.x,
				currentOffset.y + currentTranslation.y
			};
			
			self.lastStackViewContentOffset = self.stackView.contentOffset;
			self.lastWebViewFrame = self.webView.frame;
			
			//	NSLog(@"began. scroll view %@, stack view %@, last web view frame %@", NSStringFromCGPoint(lastWebScrollViewContentOffset), NSStringFromCGPoint(lastStackViewContentOffset), NSStringFromCGRect(self.lastWebViewFrame));
			
			break;
		
		}
		
		case UIGestureRecognizerStateChanged: {
				
			self.stackView.delegate = nil;
		
			CGFloat const minStackOffsetY = 0;
			CGFloat const maxStackOffsetY = 224;
			
			UIScrollView *stackV = self.stackView;
			UIScrollView *webSV = webView.scrollView;
			UIView *webV = webView;
			
			CGPoint translationInStackView = [aPanGestureRecognizer translationInView:stackV];
			CGFloat usableDeltaY = -1 * translationInStackView.y;
			
			CGPoint newStackOffset = lastStackViewContentOffset;
			newStackOffset.y += usableDeltaY;
			newStackOffset.y = MAX(minStackOffsetY, MIN(maxStackOffsetY, newStackOffset.y));
			
			CGFloat cappedDeltaY = newStackOffset.y - lastStackViewContentOffset.y;
			
			CGPoint newWebScrollViewOffset = self.lastWebScrollViewContentOffset;
			newWebScrollViewOffset.x = webSV.contentOffset.x;
			newWebScrollViewOffset.y += (usableDeltaY - cappedDeltaY);
			
			if (newWebScrollViewOffset.y > 0)
			if (usableDeltaY < 0) {
			
				CGFloat stolenDeltaY = MAX(-1 * newWebScrollViewOffset.y, usableDeltaY);
			
				newStackOffset.y -= stolenDeltaY;
				newWebScrollViewOffset.y += stolenDeltaY;
				
				cappedDeltaY -= stolenDeltaY;
			
			}
			
			
			CGRect newWebViewFrame = lastWebViewFrame;
			newWebViewFrame.size.height += cappedDeltaY;
			
			//	NSLog(@"usable delt %f, capped %f, newStackOffset %@, lastWebScrollViewContentOffset %@, lastWebViewFrame %@,  newWebScrollViewOffset %@, newWebViewFrame%@", usableDeltaY, cappedDeltaY, NSStringFromCGPoint(newStackOffset), NSStringFromCGPoint(lastWebScrollViewContentOffset), NSStringFromCGRect(lastWebViewFrame), NSStringFromCGPoint(newWebScrollViewOffset), NSStringFromCGRect(newWebViewFrame));
			
			[stackV setContentOffset:newStackOffset animated:NO];
			stackV.contentInset = (UIEdgeInsets){ 0, 0, newStackOffset.y, 0 };
			[webSV setContentOffset:newWebScrollViewOffset animated:NO];
			webV.frame = newWebViewFrame;
			
			self.stackView.delegate = self;
			
			break;
		
		}
		
		case UIGestureRecognizerStateCancelled:
		case UIGestureRecognizerStateEnded:
		case UIGestureRecognizerStateFailed: {
		
			//	NSLog(@"finished %x", aPanGestureRecognizer.state);
			
			CGPoint velocityInStackView = [aPanGestureRecognizer velocityInView:self.stackView];
			//	NSLog(@"velocity %@", NSStringFromCGPoint(velocityInStackView));
			
			//	self.stackView.delegate = nil;
			
			CGPoint oldContentOffset = self.stackView.contentOffset;
			self.stackView.contentInset = (UIEdgeInsets){ 0, 0, MAX(0, oldContentOffset.y), 0};
			[self.stackView setContentOffset:oldContentOffset animated:NO];

			[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseIn animations:^{
				
				if ((self.stackView.contentOffset.y > 0) && (self.stackView.contentOffset.y < 224)) {
				
						if (velocityInStackView.y > 0) {

							[self.stackView setContentOffset:(CGPoint){ 0, 0 } animated:NO];
						
						} else {
						
							[self.stackView setContentOffset:(CGPoint){ 0, 224 } animated:NO];
							
						}
				
				} else if ((velocityInStackView.y > 512) && self.webView.scrollView.contentOffset.y == 0) {
				
						[self.stackView setContentOffset:(CGPoint){ 0, 0 } animated:NO];
				
				}
					
			} completion: ^ (BOOL finished) {
					
			}];
		
			break;
		
		}
		
		default: {
		
			break;
		
		}
	
	}
	
	self.lastWebScrollViewPanGestureRecognizerState = aPanGestureRecognizer.state;

}

- (void) setLastWebScrollViewContentOffset:(CGPoint)newLastWebScrollViewContentOffset {

	if (CGPointEqualToPoint(lastWebScrollViewContentOffset, newLastWebScrollViewContentOffset))
		return;
	
	//	NSLog(@"%s %@ -> %@, %@", __PRETTY_FUNCTION__, NSStringFromCGPoint(lastWebScrollViewContentOffset) , NSStringFromCGPoint(newLastWebScrollViewContentOffset), [NSThread callStackSymbols]);
	
	lastWebScrollViewContentOffset = newLastWebScrollViewContentOffset;

}

@end
