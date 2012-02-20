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

@property (nonatomic, readwrite, retain) UIToolbar *toolbar;

@property (nonatomic, readwrite, assign) CGPoint lastStackViewContentOffset;
@property (nonatomic, readwrite, assign) CGPoint lastWebScrollViewContentOffset;
@property (nonatomic, readwrite, assign) UIGestureRecognizerState lastWebScrollViewPanGestureRecognizerState;
@property (nonatomic, readwrite, assign) CGRect lastWebViewFrame;

@end


@implementation WAArticleViewController_Preview
@synthesize state;
@synthesize webView, summaryWebView, webViewWrapper, previewBadge, previewBadgeWrapper;
@synthesize webViewActivityIndicator, webViewBackBarButtonItem, webViewForwardBarButtonItem, webViewActivityIndicatorBarButtonItem, webViewReloadBarButtonItem;
@synthesize lastStackViewContentOffset, lastWebScrollViewContentOffset, lastWebScrollViewPanGestureRecognizerState, lastWebViewFrame;
@synthesize toolbar;

- (void) dealloc {

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
	
	[toolbar release];
	
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
	[stackElements addObject:self.toolbar];
	
	self.stackView.delaysContentTouches = YES;
	self.stackView.canCancelContentTouches = NO;
	self.stackView.onTouchesShouldCancelInContentView = ^ (UIView *view) {
	
		UIView *wrappedView = [self wrappedView];
	
		if (wrappedView)
		if (view == wrappedView)
			return NO;
		
		return YES;
	
	};
	
	self.stackView.onGestureRecognizerShouldRecognizeSimultaneouslyWithGestureRecognizer = ^ (UIGestureRecognizer *aGR, UIGestureRecognizer *otherGR, BOOL superAnswer) {
	
		return NO;
	
	};
	
#if 0
	
	self.webView.layer.borderColor = [UIColor greenColor].CGColor;
	self.webView.layer.borderWidth = 4;
	
	self.webViewWrapper.layer.borderColor = [UIColor redColor].CGColor;
	self.webViewWrapper.layer.borderWidth = 2;
	
	self.stackView.layer.borderColor = [UIColor blueColor].CGColor;
	self.stackView.layer.borderWidth = 1;
	
	self.webView.scrollView.scrollIndicatorInsets = (UIEdgeInsets){ 0, 0, 0, 8 };

#endif

	if ([self isViewLoaded])
		[self updateWrapperView];

}

- (void) viewDidUnload {

	[super viewDidUnload];

	self.webView = nil;
	self.summaryWebView = nil;
	self.webViewWrapper = nil;
	
	self.webViewActivityIndicator = nil;
	self.webViewBackBarButtonItem = nil;
	self.webViewForwardBarButtonItem = nil;
	self.webViewActivityIndicatorBarButtonItem = nil;
	self.webViewReloadBarButtonItem = nil;

	self.previewBadge = nil;
	self.previewBadgeWrapper = nil;

	self.toolbar = nil;

}

- (UIWebView *) webView {

	if (webView)
		return webView;
	
	webView = [[UIWebView alloc] initWithFrame:CGRectZero];
	
	webView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
	webView.delegate = self;

	UIScrollView *webScrollView = [webView respondsToSelector:@selector(scrollView)] ? webView.scrollView : [[webView.subviews filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
		return [evaluatedObject isKindOfClass:[UIScrollView class]];
	}]] lastObject];
	
	if (webScrollView) {
		
		webScrollView.canCancelContentTouches = NO;
		webScrollView.delaysContentTouches = NO;

		//	Enables some change handling
		//	[self.stackView.panGestureRecognizer addTarget:self action:@selector(handleStackViewPanGesture:)];	
		//	[webScrollView.panGestureRecognizer addTarget:self action:@selector(handleWebScrollViewPanGesture:)];
		
		webScrollView.directionalLockEnabled = NO;
		
	}
		
	[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[self preview].graphElement.url]]];
	
	return webView;

}

- (UIWebView *) summaryWebView {

	if (summaryWebView)
		return summaryWebView;
	
	summaryWebView = [[UIWebView alloc] initWithFrame:CGRectZero];
	
	summaryWebView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
	summaryWebView.delegate = self;
	
	summaryWebView.scrollView.canCancelContentTouches = NO;
	summaryWebView.scrollView.delaysContentTouches = NO;
	summaryWebView.scrollView.directionalLockEnabled = NO;
	
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
	
	NSString *usedSummary = (tidyString ? tidyString : self.article.summary);
	NSString *templatedSummary = [[[NSString stringWithContentsOfFile:summaryTemplatePath usedEncoding:NULL error:nil] stringByReplacingOccurrencesOfString:@"$TITLE" withString:@"Preview"] stringByReplacingOccurrencesOfString:@"$BODY" withString:usedSummary];
	
	NSURL *summaryTemplateBaseURL = nil;
	
	if (templatedSummary)
		summaryTemplateBaseURL = [NSURL fileURLWithPath:summaryTemplateDirectoryPath];
	
	[summaryWebView loadHTMLString:(templatedSummary ? templatedSummary : usedSummary) baseURL:summaryTemplateBaseURL];
	
	return summaryWebView;

}

- (IRBarButtonItem *) webViewBackBarButtonItem {

	if (webViewBackBarButtonItem)
		return webViewBackBarButtonItem;
		
	UIImage *leftImage = WABarButtonImageWithOptions(@"UIButtonBarArrowLeft", kWADefaultBarButtonTitleColor, kWADefaultBarButtonTitleShadow);
	UIImage *leftLandscapePhoneImage = WABarButtonImageWithOptions(@"UIButtonBarArrowLeftLandscape", kWADefaultBarButtonTitleColor, kWADefaultBarButtonTitleShadow);
		
	webViewBackBarButtonItem = [[IRBarButtonItem itemWithCustomImage:leftImage landscapePhoneImage:leftLandscapePhoneImage highlightedImage:nil highlightedLandscapePhoneImage:nil] retain];
	
	webViewBackBarButtonItem.block = ^ {
	
		UIWebView *currentWebView = (UIWebView *)[self wrappedView];
		
		if (![currentWebView isKindOfClass:[UIWebView class]])
			return;
		
		[currentWebView goBack];
	
	};
	
	return webViewBackBarButtonItem;

}

- (IRBarButtonItem *) webViewForwardBarButtonItem {

	if (webViewForwardBarButtonItem)
		return webViewForwardBarButtonItem;
		
	UIImage *rightImage = WABarButtonImageWithOptions(@"UIButtonBarArrowRight", kWADefaultBarButtonTitleColor, kWADefaultBarButtonTitleShadow);
	UIImage *rightLandscapePhoneImage = WABarButtonImageWithOptions(@"UIButtonBarArrowRightLandscape", kWADefaultBarButtonTitleColor, kWADefaultBarButtonTitleShadow);
		
	webViewForwardBarButtonItem = [[IRBarButtonItem itemWithCustomImage:rightImage landscapePhoneImage:rightLandscapePhoneImage highlightedImage:nil highlightedLandscapePhoneImage:nil] retain];
	
	webViewForwardBarButtonItem.block = ^ {
	
		UIWebView *currentWebView = (UIWebView *)[self wrappedView];
		
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
	
	webViewActivityIndicatorBarButtonItem = [IRBarButtonItem itemWithCustomView:self.webViewActivityIndicator];
	
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
	
	((WAView *)webViewWrapper).onPointInsideWithEvent = ^ (CGPoint aPoint, UIEvent *anEvent, BOOL superAnswer) {
	
		UIView *wrappedView = [nrSelf wrappedView];
		
		if (!wrappedView)
			return superAnswer;
	
		NSParameterAssert([wrappedView isDescendantOfView:webViewWrapper]);
		
		BOOL customAnswer = CGRectContainsPoint(
				[webViewWrapper convertRect:wrappedView.bounds fromView:wrappedView],
				aPoint
		);
		
		return customAnswer;
	
	};
	
	((WAView *)webViewWrapper).onHitTestWithEvent = ^ (CGPoint aPoint, UIEvent *anEvent, UIView *superAnswer) {
	
		if (![webViewWrapper pointInside:aPoint withEvent:anEvent])
			return superAnswer;
		
		UIView *wrappedView = [nrSelf wrappedView];
		if (!wrappedView)
			return superAnswer;
		
		return [wrappedView hitTest:[wrappedView convertPoint:aPoint fromView:webViewWrapper] withEvent:anEvent];
	
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

- (UIToolbar *) toolbar {

	if (toolbar)
		return toolbar;
	
	toolbar = [[UIToolbar alloc] initWithFrame:CGRectZero];
	
	toolbar.items = [NSArray arrayWithObjects:
			
		[IRBarButtonItem itemWithCustomView:((^ {
		
			UISegmentedControl *segmentedControl = [[[UISegmentedControl alloc] initWithItems:nil] autorelease];
			segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
			[segmentedControl addTarget:self action:@selector(handleSegmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
			
			[segmentedControl insertSegmentWithTitle:@"Summary" atIndex:0 animated:NO];
			[segmentedControl insertSegmentWithTitle:@"Web" atIndex:1 animated:NO];
			
			[segmentedControl setSelectedSegmentIndex:0];
			[segmentedControl sendActionsForControlEvents:UIControlEventValueChanged];
			
			return segmentedControl;
		
		})())],
		
		[IRBarButtonItem itemWithSystemItem:UIBarButtonSystemItemFlexibleSpace wiredAction:nil],
		
		self.webViewBackBarButtonItem,
		
		[IRBarButtonItem itemWithCustomView:[[[UIView alloc] initWithFrame:(CGRect){ 0, 0, 44, 44 }] autorelease]],
				
		self.webViewActivityIndicatorBarButtonItem,
		//	self.webViewReloadBarButtonItem,
		
		[IRBarButtonItem itemWithCustomView:[[[UIView alloc] initWithFrame:(CGRect){ 0, 0, 44, 44 }] autorelease]],
				
		self.webViewForwardBarButtonItem,

		[IRBarButtonItem itemWithSystemItem:UIBarButtonSystemItemFlexibleSpace wiredAction:nil],
		
		[IRBarButtonItem itemWithTitle:@"Open in Safari" action: ^ {
		
			NSURL * const previewURL = [NSURL URLWithString:self.preview.graphElement.url];
			NSURL * const currentWebURL = [NSURL URLWithString:[webView stringByEvaluatingJavaScriptFromString:@"document.location.href"]];
		
			[[UIApplication sharedApplication] openURL:currentWebURL ? currentWebURL : previewURL];
		
		}],
		
	nil];
	
	return toolbar;

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

	if ([[self wrappedView] isDescendantOfView:anElement])
		return (CGSize){ CGRectGetWidth(aStackView.bounds), 1 };	//	Stretchable
	
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
	
	if ((self.toolbar == anElement) || [self.toolbar isDescendantOfView:anElement])
		return (CGSize){ CGRectGetWidth(aStackView.bounds), 44 };

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

- (void) scrollViewWillBeginDragging:(UIScrollView *)scrollView {

	[self.stackView beginPostponingStackElementLayout];

	if ([self irHasDifferentSuperClassMethodForSelector:_cmd])
		[super scrollViewWillBeginDragging:scrollView];
	
	for (UIView *aView in scrollView.subviews)
		if ([aView isKindOfClass:[UIWebView class]])
			aView.userInteractionEnabled = NO;
	
	self.lastStackViewContentOffset = self.stackView.contentOffset;
	self.lastWebScrollViewContentOffset = self.webView.scrollView.contentOffset;

}

- (void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {

	if ([self irHasDifferentSuperClassMethodForSelector:_cmd])
		[super scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
	
	if (!decelerate) {
	
		[self.stackView endPostponingStackElementLayout];
		
		for (UIView *aView in scrollView.subviews)
			if ([aView isKindOfClass:[UIWebView class]])
				aView.userInteractionEnabled = YES;
			
	}
	
}


- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView {

	if ([self irHasDifferentSuperClassMethodForSelector:_cmd])
		[super scrollViewDidEndDecelerating:scrollView];
	
	[self.stackView endPostponingStackElementLayout];
	
	for (UIView *aView in scrollView.subviews)
		if ([aView isKindOfClass:[UIWebView class]])
			aView.userInteractionEnabled = YES;
	
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {

	return;

	if (scrollView != self.stackView)
		return;
	
	self.lastWebScrollViewContentOffset = self.webView.scrollView.contentOffset;
	
	CGRect newWebViewFrame = (CGRect){
		CGPointZero,
		(CGSize){
			self.webViewWrapper.bounds.size.width,
			self.webViewWrapper.bounds.size.height + self.stackView.contentOffset.y
		}
	};
	
	if (!CGRectEqualToRect(self.webView.frame, newWebViewFrame)) {
		//	[self.webView.scrollView flashScrollIndicators];
		self.webView.frame = newWebViewFrame;
	}

//	CGPoint stackViewContentOffset = self.stackView.contentOffset;
	
//	if (stackViewContentOffset.y > 0) {
//	
//		[self.webView.scrollView setContentOffset:(CGPoint){
//			self.lastWebScrollViewContentOffset.x,
//			self.lastWebScrollViewContentOffset.y
//		} animated:NO];
//	
//	}

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
