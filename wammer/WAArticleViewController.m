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


@interface WAArticleViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, readwrite, retain) NSURL *representedObjectURI;
@property (nonatomic, readwrite, assign) WAArticleViewControllerPresentationStyle presentationStyle;
@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) WAArticle *article;

@property (nonatomic, retain) WAArticleView *view;

@end


NSString * NSStringFromWAArticleViewControllerPresentationStyle (WAArticleViewControllerPresentationStyle aStyle) {

	return ((NSString *[]){
		
		[WAFullFramePlaintextArticleStyle] = @"Plaintext",
		[WAFullFrameImageStackArticleStyle] = @"Default",
		[WAFullFramePreviewArticleStyle] = @"Preview",
		[WADiscretePlaintextArticleStyle] = @"Discrete_Plaintext",
		[WADiscreteSingleImageArticleStyle] = @"Discrete_Default",
		[WADiscretePreviewArticleStyle] = @"Discrete_Preview"
		
	}[aStyle]);

}

WAArticleViewControllerPresentationStyle WAArticleViewControllerPresentationStyleFromString (NSString *aString) {

	NSNumber *answer = [[NSDictionary dictionaryWithObjectsAndKeys:
		
		[NSNumber numberWithInt:WAFullFramePlaintextArticleStyle], @"Plaintext",
		[NSNumber numberWithInt:WAFullFrameImageStackArticleStyle], @"Default",
		[NSNumber numberWithInt:WAFullFramePreviewArticleStyle], @"Preview",
		[NSNumber numberWithInt:WADiscretePlaintextArticleStyle], @"Discrete_Plaintext",
		[NSNumber numberWithInt:WADiscreteSingleImageArticleStyle], @"Discrete_Default",
		[NSNumber numberWithInt:WADiscretePreviewArticleStyle], @"Discrete_Preview",
		
	nil] objectForKey:aString];
	
	if (!answer)
		return WAUnknownArticleStyle;
	
	return [answer intValue];

}

WAArticleViewControllerPresentationStyle WAFullFrameArticleStyleFromDiscreteStyle (WAArticleViewControllerPresentationStyle aStyle) {

	return ((WAArticleViewControllerPresentationStyle[]){
		[WADiscretePlaintextArticleStyle] = WAFullFramePlaintextArticleStyle,
		[WADiscreteSingleImageArticleStyle] = WAFullFrameImageStackArticleStyle,
		[WADiscretePreviewArticleStyle] = WAFullFramePreviewArticleStyle,
		[WADiscreteDocumentArticleStyle] = WAFullFrameDocumentArticleStyle
	})[aStyle];

}

WAArticleViewControllerPresentationStyle WADiscreteArticleStyleFromFullFrameStyle (WAArticleViewControllerPresentationStyle aStyle) {

	return ((WAArticleViewControllerPresentationStyle[]){
		[WAFullFramePlaintextArticleStyle] = WADiscretePlaintextArticleStyle,
		[WAFullFrameImageStackArticleStyle] = WADiscreteSingleImageArticleStyle,
		[WAFullFramePreviewArticleStyle] = WADiscretePreviewArticleStyle,
		[WAFullFrameDocumentArticleStyle] = WADiscreteDocumentArticleStyle
	})[aStyle];

}


@implementation WAArticleViewController

@dynamic view;

@synthesize representedObjectURI, presentationStyle;
@synthesize managedObjectContext, article;
@synthesize onViewDidLoad, onViewTap, onViewPinch;
@synthesize hostingViewController, delegate;

+ (WAArticleViewControllerPresentationStyle) suggestedDiscreteStyleForArticle:(WAArticle *)anArticle {

	if (!anArticle)
		return WADiscretePlaintextArticleStyle;
		
	for (WAPreview *aPreview in anArticle.previews)
		if (aPreview.text || aPreview.url || aPreview.graphElement.text || aPreview.graphElement.title)
			return WADiscretePreviewArticleStyle;
			
	for (WAFile *aFile in anArticle.files)
		if (aFile.resourceURL || aFile.thumbnailURL || [aFile.remoteResourceType isEqualToString:@"image"])
			return WADiscreteSingleImageArticleStyle;
	
	return WADiscretePlaintextArticleStyle;

}

+ (WAArticleViewControllerPresentationStyle) suggestedStyleForArticle:(WAArticle *)anArticle {

	return [self suggestedDiscreteStyleForArticle:anArticle];

}

+ (Class) classForPresentationStyle:(WAArticleViewControllerPresentationStyle)style nibName:(NSString **)outNibName bundle:(NSBundle **)outBundle {

	NSString *preferredClassName = [NSStringFromClass([self class]) stringByAppendingFormat:@"_%@", NSStringFromWAArticleViewControllerPresentationStyle(style)];
	NSString *loadedNibName = preferredClassName;
	
	Class loadedClass = NSClassFromString(preferredClassName);
	if (!loadedClass)
		loadedClass = [self class];
	
	NSBundle *usedBundle = [NSBundle bundleForClass:[self class]];
	if (![UINib nibWithNibName:loadedNibName bundle:usedBundle])
		loadedNibName = NSStringFromClass([self class]);
  
  if (![UINib nibWithNibName:loadedNibName bundle:usedBundle])
    loadedNibName = nil;
	
	if (outNibName)
		*outNibName = loadedNibName;
	
	if (outBundle)
		*outBundle = usedBundle;
	
	return loadedClass;

}

+ (WAArticleViewController *) controllerForArticle:(NSURL *)articleObjectURL usingPresentationStyle:(WAArticleViewControllerPresentationStyle)aStyle {

	NSString *loadedNibName = nil;
	NSBundle *usedBundle = nil;
	Class loadedClass = [self classForPresentationStyle:aStyle nibName:&loadedNibName bundle:&usedBundle];
	
	WAArticleViewController *returnedController = [[loadedClass alloc] initWithNibName:loadedNibName bundle:usedBundle];
	
	returnedController.presentationStyle = aStyle;
	returnedController.representedObjectURI = articleObjectURL;
	
	return returnedController;

}

+ (WAArticleViewController *) controllerForArticle:(WAArticle *)article context:(NSManagedObjectContext *)context presentationStyle:(WAArticleViewControllerPresentationStyle)aStyle {

	NSString *loadedNibName = nil;
	NSBundle *usedBundle = nil;
	Class loadedClass = [self classForPresentationStyle:aStyle nibName:&loadedNibName bundle:&usedBundle];
	
	WAArticleViewController *returnedController = [[loadedClass alloc] initWithNibName:loadedNibName bundle:usedBundle];
	
	returnedController.presentationStyle = aStyle;
	returnedController.article = article;
	returnedController.managedObjectContext = context;
	returnedController.representedObjectURI = [[article objectID] URIRepresentation];
	
	return returnedController;

}

- (NSManagedObjectContext *) managedObjectContext {

	if (!managedObjectContext)
		self.managedObjectContext = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
	
	return managedObjectContext;

}

+ (NSSet *) keyPathsForValuesAffectingArticle {

	return [NSSet setWithObjects:
	
		@"representedObjectURI",
	
	nil];

}

- (WAArticle *) article {

	if (!article && self.representedObjectURI)
		article = (WAArticle *)[self.managedObjectContext irManagedObjectForURI:self.representedObjectURI];
	
	return article;

}

- (void) viewDidUnload {

	self.managedObjectContext = nil;
	self.article = nil;
	self.inspectionActionSheetController = nil;
	self.coverPhotoSwitchPopoverController = nil;
	
	[super viewDidUnload];

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
	
	if (self.onViewDidLoad)
		self.onViewDidLoad(self, self.view);
	
}

- (void) reloadData {

	if ([self isViewLoaded]) {
	
		NSString *templateName = @"WFPreviewTemplate_Discrete_Plaintext";
		
		if (self.delegate)
			templateName = [self.delegate presentationTemplateNameForArticleViewController:self];
	
		self.view.presentationTemplateName = templateName;
			
		[self.view configureWithArticle:self.article];
	
	}

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

	if (self.onViewTap)
		self.onViewTap();

}

- (void) handleGlobalPinch:(UIPinchGestureRecognizer *)pinchRecognizer {

	if (self.onViewPinch)
		self.onViewPinch(pinchRecognizer.state, pinchRecognizer.scale, pinchRecognizer.velocity);

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

@end
