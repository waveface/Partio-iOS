//
//  WATutorialViewController.m
//  wammer
//
//  Created by Evadne Wu on 7/13/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WATutorialViewController.h"

@interface WATutorialViewController () <IRPaginatedViewDelegate>

@property (nonatomic, readwrite, assign) WATutorialInstantiationOption option;
@property (nonatomic, readwrite, copy) WATutorialViewControllerCallback callback;

@property (nonatomic, readonly, strong) NSArray *pages;
- (NSArray *) copyPages;

@end


@implementation WATutorialViewController
@synthesize paginatedView = _paginatedView;
@synthesize pageWelcomeToStream = _pageWelcomeToStream;
@synthesize pageReliveYourMoments = _pageReliveYourMoments;
@synthesize pageInstallStation = _pageInstallStation;
@synthesize pageToggleFacebook = _pageToggleFacebook;
@synthesize pageStartStream = _pageStartStream;
@synthesize goButton = _goButton;
@synthesize option = _option;
@synthesize callback = _callback;
@synthesize pages = _pages;

+ (WATutorialViewController *) controllerWithOption:(WATutorialInstantiationOption)option completion:(WATutorialViewControllerCallback)block {

	WATutorialViewController *tutorialVC = [WATutorialViewController new];
	tutorialVC.option = option;
	tutorialVC.callback = block;
	
	return tutorialVC;

}

- (void) viewDidLoad {

	[super viewDidLoad];
	
	NSCParameterAssert(self.paginatedView);
	NSCParameterAssert(self.pageWelcomeToStream);
	NSCParameterAssert(self.pageReliveYourMoments);
	NSCParameterAssert(self.pageInstallStation);
	NSCParameterAssert(self.pageToggleFacebook);
	NSCParameterAssert(self.pageStartStream);
	
	_pages = [self copyPages];
	[self.paginatedView reloadViews];
	
	UIImage * (^stretch)(UIImage *) = ^ (UIImage *image) {
	
		return [image stretchableImageWithLeftCapWidth:5.0f topCapHeight:0.0f];
	
	};

	void (^heckle)(UIButton *, UIControlState) = ^ (UIButton *button, UIControlState state) {
	
		[button setBackgroundImage:stretch([button backgroundImageForState:state]) forState:state];

	};
	
	void (^heckleAll)(UIButton *) = ^ (UIButton * button) {
	
		heckle(button, UIControlStateNormal);
		heckle(button, UIControlStateHighlighted);
		heckle(button, UIControlStateSelected);
		heckle(button, UIControlStateDisabled);
		heckle(button, UIControlStateReserved);
		heckle(button, UIControlStateApplication);
	
	};
	
	heckleAll(self.goButton);

}

- (NSUInteger) numberOfViewsInPaginatedView:(IRPaginatedView *)paginatedView {

	return [self.pages count];

}

- (UIView *) viewForPaginatedView:(IRPaginatedView *)paginatedView atIndex:(NSUInteger)index {

	return [self.pages objectAtIndex:index];

}

- (UIViewController *) viewControllerForSubviewAtIndex:(NSUInteger)index inPaginatedView:(IRPaginatedView *)paginatedView {

	return nil;

}

- (void) paginatedView:(IRPaginatedView *)paginatedView willShowView:(UIView *)aView atIndex:(NSUInteger)index {

	//	?

}

- (void) paginatedView:(IRPaginatedView *)paginatedView didShowView:(UIView *)aView atIndex:(NSUInteger)index {

	//	?

}

- (NSArray *) copyPages {

	NSMutableArray *array = [NSMutableArray array];
	
	[array addObject:self.pageWelcomeToStream];
	[array addObject:self.pageReliveYourMoments];
	[array addObject:self.pageInstallStation];
	
	if (self.option & WATutorialInstantiationOptionShowFacebookIntegrationToggle)
		[array addObject:self.pageToggleFacebook];
	
	[array addObject:self.pageStartStream];
	
	return array;

}

- (IBAction) handleGo:(id)sender {

	if (self.callback)
		self.callback(YES, nil);
		
}

@end
