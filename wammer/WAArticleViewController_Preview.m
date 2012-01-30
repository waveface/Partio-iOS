//
//  WAArticleViewController_Preview.m
//  wammer
//
//  Created by Evadne Wu on 1/30/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAArticleViewController_Preview.h"
#import "WADataStore.h"

@implementation WAArticleViewController_Preview

- (void) viewDidLoad {

	[super viewDidLoad];
	
	WAPreview *anyPreview = (WAPreview *)[self.article.previews anyObject];
	
	if (anyPreview) {
	
		UIWebView *webView = [[[UIWebView alloc] initWithFrame:(CGRect){
			CGPointZero,
			(CGSize){ 320, 320 }
		}] autorelease];
		[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:anyPreview.graphElement.url]]];
		
		[[self.stackView mutableStackElements] addObject:webView];
		
	}

}

- (CGSize) sizeThatFitsElement:(UIView *)anElement inStackView:(WAStackView *)aStackView {

	if ([anElement isKindOfClass:[UIWebView class]])
		return (CGSize){ CGRectGetWidth(aStackView.bounds), 320 };
	
	if ([self irHasDifferentSuperInstanceMethodForSelector:_cmd])
		return [super sizeThatFitsElement:anElement inStackView:aStackView];
	
	return CGSizeZero;	

}

- (BOOL) stackView:(WAStackView *)aStackView shouldStretchElement:(UIView *)anElement {

	if ([anElement isKindOfClass:[UIWebView class]])
		return YES;
	
	if ([self irHasDifferentSuperInstanceMethodForSelector:_cmd])
		return [super stackView:aStackView shouldStretchElement:anElement];
	
	return NO;

}

@end
