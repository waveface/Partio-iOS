//
//  WAArticleViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/28/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAArticleViewController.h"

#import "QuartzCore+IRAdditions.h"
#import "WADataStore.h"

#import "WAArticleViewController+Subclasses.h"
#import "WAArticleViewController+Inspection.h"

#import "WAArticleView.h"
#import "WAArticleView+ReuseSupport.h"

#import "WADefines.h"

#import "IRObjectQueue.h"


static NSString * const kObjectQueue = @"+[WAArticleViewController objectQueue]";


@interface WAArticleViewController () <UIGestureRecognizerDelegate>

+ (NSString *) literalForStyle:(WAArticleStyle)style;
+ (IRObjectQueue *) objectQueue;

@property (nonatomic, readwrite, retain) WAArticle *article;
@property (nonatomic, readwrite, assign) WAArticleStyle style;
@property (nonatomic, retain) WAArticleView *view;

@end


@implementation WAArticleViewController
@dynamic view;
@synthesize style, article, hostingViewController, delegate;

+ (NSString *) literalForStyle:(WAArticleStyle)style {

	static NSMutableDictionary *lut;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		lut = [NSMutableDictionary dictionary];
	});
	
	id key = [NSValue valueWithBytes:&style objCType:@encode(__typeof__(style))];
	id obj = [lut objectForKey:key];
	if (obj)
		return obj;

	obj = [[NSArray arrayWithObjects:
	
		NSStringFromClass([self class]),
		
		(style & WAFullScreenArticleStyle) ?
			@"FullScreen" :
		(style & WACellArticleStyle) ?
			@"Cell" : @"Default",
		
		(style & WAPlaintextArticleStyle) ?
			@"Plaintext" :
		(style & WAPhotosArticleStyle) ?
			@"Photo" :
		(style & WAPreviewArticleStyle) ?
			@"Preview" :
		(style & WADocumentArticleStyle) ?
			@"Document" : @"Default",		
	
	nil] componentsJoinedByString:@"_"];
	
	[lut setObject:obj forKey:key];
	
	return obj;

}

+ (IRObjectQueue *) objectQueue {

	IRObjectQueue *oq = objc_getAssociatedObject([self class], &kObjectQueue);
	if (!oq) {
		oq = [IRObjectQueue new];
		objc_setAssociatedObject([self class], &kObjectQueue, oq, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	
	return oq;

}

+ (WAArticleViewController *) controllerForArticle:(WAArticle *)article style:(WAArticleStyle)style {

	NSCParameterAssert(article);

	NSString *literal = [self literalForStyle:style];
	Class class = NSClassFromString(literal);
	if (!class)
		class = [self class];
	
	WAArticleViewController *articleVC = [[class alloc] initWithNibName:[self literalForStyle:style] bundle:nil];
	articleVC.article = article;
	articleVC.style = style;
	
	return articleVC;

}

+ (NSSet *) keyPathsForValuesAffectingArticle {

	return [NSSet setWithObjects:
	
		@"representedObjectURI",
	
	nil];

}

- (void) loadView {

	if (self.style & WACellArticleStyle) {

		NSString *reuseID = self.nibName;
		WAArticleView *view = (WAArticleView *)[[[self class] objectQueue] dequeueObjectWithIdentifier:reuseID];
		
		if ([view isKindOfClass:[WAArticleView class]]) {
		
			self.view = view;
		
		} else {
		
			[super loadView];
			self.view.reuseIdentifier = reuseID;
			
		}
	
	} else {
	
		[super loadView];
	
	}

}

- (void) viewDidLoad {

	[super viewDidLoad];
	
	UITapGestureRecognizer *globalTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGlobalTap:)];
	UIPinchGestureRecognizer *globalPinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleGlobalPinch:)];
	UILongPressGestureRecognizer *globalInspectRecognizer = [self newInspectionGestureRecognizer];
	
	globalTapRecognizer.delegate = self;
	globalPinchRecognizer.delegate = self;
	globalInspectRecognizer.delegate = self;
	
	[self.view addGestureRecognizer:globalTapRecognizer];
	[self.view addGestureRecognizer:globalPinchRecognizer];
	[self.view addGestureRecognizer:globalInspectRecognizer];
	
	[self reloadData];
	
	[self.delegate articleViewControllerDidLoadView:self];
	
	if (style & WACellArticleStyle) {
	
		UIView *borderView = [[UIView alloc] initWithFrame:CGRectInset(self.view.bounds, -8, -8)];
		borderView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		borderView.userInteractionEnabled = NO;
		borderView.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1].CGColor;
		borderView.layer.borderWidth = 1.0f;
		
		[self.view addSubview:borderView];
		[self.view bringSubviewToFront:borderView];
	
	}
	
}

- (void) viewWillUnload {

	[super viewWillUnload];

	for (UIGestureRecognizer *aGR in [self.view.gestureRecognizers copy])
		[self.view removeGestureRecognizer:aGR];
	
	if (self.style & WACellArticleStyle) {
	
		[[[self class] objectQueue] addObject:self.view];
	
	}

}

- (void) viewDidUnload {

	self.inspectionActionSheetController = nil;
	self.coverPhotoSwitchPopoverController = nil;
	
	[super viewDidUnload];

}

- (void) reloadData {

	NSCParameterAssert(self.article);

	if ([self isViewLoaded]) {
	
		NSString *templateName = @"WFPreviewTemplate_Discrete_Plaintext";
		
		if (self.delegate)
			templateName = [self.delegate presentationTemplateNameForArticleViewController:self];
	
		self.view.presentationTemplateName = templateName;
			
		[self.view configureWithArticle:self.article];
	
	}

}

- (void) viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];
	
	void (^postEvent)(NSString *, NSString *) = ^ (NSString *title, NSString *category) {
		WAPostAppEvent(title, [NSDictionary dictionaryWithObjectsAndKeys:
			category, @"category",
			@"consume", @"action",
		nil]);
	};
	
	(style == WAPlaintextArticleStyle) ?
		postEvent(@"View Text Post", @"text") :
	(style == WAPhotosArticleStyle) ?
		postEvent(@"View Photo Post", @"photo") :
	(style == WAPreviewArticleStyle) ?
		postEvent(@"View Preview Post", @"link") :
	(style == WADocumentArticleStyle) ?
		postEvent(@"View Document Post", @"document") :
	nil;

}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {

	if ([touch.view isKindOfClass:[UIControl class]])
		return NO;
	
	__weak WAArticleViewController *wSelf = self;
	
	__block BOOL (^wrappedIn)(UIView *, Class) = [^ (UIView *aView, Class aClass) {
	
		if ([aView isKindOfClass:aClass])
			return YES;
		
		if (!aView.superview)
			return NO;
		
		if (aView == wSelf.view)
			return NO;
		
		return wrappedIn(aView.superview, aClass);
		
	} copy];
	
	BOOL wrappedInScrollView = wrappedIn(touch.view, [UIScrollView class]);
	wrappedIn = nil;
	
	return !wrappedInScrollView;

}

- (void) handleGlobalTap:(UITapGestureRecognizer *)tapRecognizer {

	[self.delegate articleViewController:self didReceiveTap:tapRecognizer];

}

- (void) handleGlobalPinch:(UIPinchGestureRecognizer *)pinchRecognizer {

	[self.delegate articleViewController:self didReceivePinch:pinchRecognizer];

}

- (void) setArticle:(WAArticle *)newArticle {

	if (article == newArticle)
		return;
	
	article = newArticle;
	
	if ([self isViewLoaded])
		[self.view configureWithArticle:article];

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {

	return YES;

}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
	[self reloadData];

}

- (void) viewDidDisappear:(BOOL)animated {

	[super viewDidDisappear:animated];
//	[self didReceiveMemoryWarning];
	
	for (UIGestureRecognizer *aGR in [self.view.gestureRecognizers copy])
		[self.view removeGestureRecognizer:aGR];
	
	if (self.style & WACellArticleStyle) {
	
		[[[self class] objectQueue] addObject:self.view];
	
	}
	
	self.view = nil;
	
}

@end
