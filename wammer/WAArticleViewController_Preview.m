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


@interface WAArticleViewController_Preview () <UIWebViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, readwrite, retain) UIWebView *webView;
@property (nonatomic, readwrite, retain) UIView *webViewWrapper;

@end


@implementation WAArticleViewController_Preview
@synthesize webView, webViewWrapper;

- (void) viewDidLoad {

	[super viewDidLoad];
	
	WAPreview *anyPreview = (WAPreview *)[self.article.previews anyObject];
	
	if (anyPreview) {
		[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:anyPreview.graphElement.url]]];
		[[self.stackView mutableStackElements] addObject:self.webViewWrapper];
	}

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
		
		self.stackView.delaysContentTouches = YES;
		self.stackView.canCancelContentTouches = NO;
		
		webScrollView.canCancelContentTouches = NO;
		webScrollView.delaysContentTouches = NO;
		
		[webScrollView.subviews enumerateObjectsUsingBlock: ^ (UIView *aSubview, NSUInteger idx, BOOL *stop) {
			
			if ([aSubview isKindOfClass:[UIImageView class]])
				[aSubview removeFromSuperview];
				
			//	I think this will break stuff, but it did not
			
		}];
		
		self.stackView.onTouchesShouldCancelInContentView = ^ (UIView *view) {
		
			if (view == webView)
				return NO;
			
			return YES;
		
		};
		
	}
		
	return webView;

}

- (UIView *) webViewWrapper {

	if (webViewWrapper)
		return webViewWrapper;
		
	webViewWrapper = [[UIView alloc] initWithFrame:self.webView.bounds];

	self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	webViewWrapper.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[webViewWrapper addSubview:self.webView];

	IRGradientView *topShadow = [[IRGradientView alloc] initWithFrame:IRGravitize(webViewWrapper.bounds, (CGSize){
		CGRectGetWidth(webViewWrapper.bounds),
		3
	}, kCAGravityTop)];
	topShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
	[topShadow setLinearGradientFromColor:[UIColor colorWithWhite:0 alpha:0.125] anchor:irTop toColor:[UIColor colorWithWhite:0 alpha:0] anchor:irBottom];
	[webViewWrapper addSubview:topShadow];
	
	return webViewWrapper;
	
}

- (CGSize) sizeThatFitsElement:(UIView *)anElement inStackView:(WAStackView *)aStackView {

	if ([self.webView isDescendantOfView:anElement])
		return (CGSize){ CGRectGetWidth(aStackView.bounds), 320 };
	
	if ([self irHasDifferentSuperInstanceMethodForSelector:_cmd])
		return [super sizeThatFitsElement:anElement inStackView:aStackView];
	
	return CGSizeZero;	

}

- (BOOL) stackView:(WAStackView *)aStackView shouldStretchElement:(UIView *)anElement {

	if ([self.webView isDescendantOfView:anElement])
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

@end
