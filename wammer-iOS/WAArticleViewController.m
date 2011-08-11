//
//  WAArticleViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/28/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "QuartzCore+IRAdditions.h"
#import "WAArticleViewController.h"
#import "WADataStore.h"
#import "WAImageStackView.h"
#import "WAGalleryViewController.h"
#import "IRRelativeDateFormatter.h"

@interface WAArticleViewController () <UIGestureRecognizerDelegate, WAImageStackViewDelegate>

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) WAArticle *article;

- (void) refreshView;

+ (IRRelativeDateFormatter *) relativeDateFormatter;

@end


@implementation WAArticleViewController
@synthesize managedObjectContext, article;
@synthesize contextInfoContainer, mainContentView, avatarView, relativeCreationDateLabel, userNameLabel, articleDescriptionLabel, deviceDescriptionLabel;
@synthesize onPresentingViewController;

+ (WAArticleViewController *) controllerRepresentingArticle:(NSURL *)articleObjectURL {

	WAArticleViewController *returnedController = [[[self alloc] initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]] autorelease];
	
	returnedController.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
	returnedController.article = (WAArticle *)[returnedController.managedObjectContext irManagedObjectForURI:articleObjectURL];
	
	return returnedController;

}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleManagedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
	
	return self;

}

- (void) handleManagedObjectContextDidSave:(NSNotification *)aNotification {

	NSManagedObjectContext *savedContext = (NSManagedObjectContext *)[aNotification object];
	
	if (savedContext == self.managedObjectContext)
		return;
	
	dispatch_async(dispatch_get_main_queue(), ^ {
	
		[self.managedObjectContext mergeChangesFromContextDidSaveNotification:aNotification];
		[self refreshView];
	
	});

}

- (void) viewDidUnload {

	self.contextInfoContainer = nil;
	self.mainContentView = nil;
	self.avatarView = nil;
	self.relativeCreationDateLabel = nil;
	self.userNameLabel = nil;
	self.articleDescriptionLabel = nil;

	[super viewDidUnload];

}

- (void) dealloc {

	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];

	[managedObjectContext release];
	[article release];
	[onPresentingViewController release];
	
	[contextInfoContainer release];
	[mainContentView release];
	[avatarView release];
	[relativeCreationDateLabel release];
	[userNameLabel release];
	[articleDescriptionLabel release];
	
	[super dealloc];

}

- (void) viewDidLoad {

	[super viewDidLoad];
	[self refreshView];
	
	self.mainContentView.delegate = self;
		
}

- (void) setArticle:(WAArticle *)newArticle {

	if (article == newArticle)
		return;
	
	[self willChangeValueForKey:@"article"];
	[article release];
	article = [newArticle retain];
	[self didChangeValueForKey:@"article"];
	
	if ([self isViewLoaded])
		[self refreshView];

}

- (void) refreshView {

	self.userNameLabel.text = self.article.owner.nickname;
	self.relativeCreationDateLabel.text = [[[self class] relativeDateFormatter] stringFromDate:self.article.timestamp];
	self.articleDescriptionLabel.text = self.article.text;
	self.mainContentView.files = [self.article.fileOrder irMap: ^ (id inObject, int index, BOOL *stop) {
		return [[self.article.files objectsPassingTest: ^ (WAFile *aFile, BOOL *stop) {		
			return [[[aFile objectID] URIRepresentation] isEqual:inObject];
		}] anyObject];
	}];
	self.avatarView.image = self.article.owner.avatar;
	self.deviceDescriptionLabel.text = [NSString stringWithFormat:@"via %@", self.article.creationDeviceName ? self.article.creationDeviceName : @"an unknown device"];
	
	[self.relativeCreationDateLabel sizeToFit];
	self.relativeCreationDateLabel.frame = (CGRect){
		(CGPoint) {
			CGRectGetWidth(self.relativeCreationDateLabel.superview.frame) - CGRectGetWidth(self.relativeCreationDateLabel.frame) - 32,
			self.relativeCreationDateLabel.frame.origin.y
		},
		self.relativeCreationDateLabel.frame.size
	};
	
	self.deviceDescriptionLabel.frame = (CGRect){
		(CGPoint){
			self.relativeCreationDateLabel.frame.origin.x - CGRectGetWidth(self.deviceDescriptionLabel.frame) - 10,
			self.deviceDescriptionLabel.frame.origin.y
		},
		self.deviceDescriptionLabel.frame.size
	};
	
	if (!self.userNameLabel.text)
		self.userNameLabel.text = @"A Certain User";
	
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	for (UIView *aView in self.mainContentView.subviews) {
	
		CGPathRef oldShadowPath = aView.layer.shadowPath;

		if (oldShadowPath) {
			CFRetain(oldShadowPath);
			[aView.layer addAnimation:((^ {
				CABasicAnimation *transition = [CABasicAnimation animationWithKeyPath:@"shadowPath"];
				transition.fromValue = (id)oldShadowPath;
				transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
				transition.duration = duration;
				return transition;
			})()) forKey:@"transition"];
			CFRelease(oldShadowPath);
		}
	
		//	CGFloat oldShadowOpacity = aView.layer.shadowOpacity;
		//	aView.layer.shadowOpacity = 0.0f;
		//	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * duration), dispatch_get_main_queue(), ^ {
		//		aView.layer.shadowOpacity = oldShadowOpacity;
		//	});
		
	}
		
}





- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	return 0;

}

- (void) imageStackView:(WAImageStackView *)aStackView didRecognizePinchZoomGestureWithRepresentedImage:(UIImage *)representedImage contentRect:(CGRect)aRect transform:(CATransform3D)layerTransform {

	//	NSString* (^NSStringFromTransform3D) (CATransform3D) = ^ (CATransform3D xform ) {
	//		return [NSString stringWithFormat:@"[%f %f %f %f; %f %f %f %f; %f %f %f %f; %f %f %f %f]",
	//			xform.m11, xform.m12, xform.m13, xform.m14,
	//			xform.m21, xform.m22, xform.m23, xform.m24,
	//			xform.m31, xform.m32, xform.m33, xform.m34,
	//			xform.m41, xform.m42, xform.m43, xform.m44
	//		];
	//	};

	WAGalleryViewController *galleryViewController = [WAGalleryViewController controllerRepresentingArticleAtURI:[[self.article objectID] URIRepresentation]];
	galleryViewController.modalPresentationStyle = UIModalPresentationFullScreen;
	galleryViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	
	self.onPresentingViewController( ^ (UIViewController *parentViewController) {
		[parentViewController presentModalViewController:galleryViewController animated:YES];
	});

}





+ (IRRelativeDateFormatter *) relativeDateFormatter {

	static IRRelativeDateFormatter *formatter = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{

		formatter = [[IRRelativeDateFormatter alloc] init];
		formatter.approximationMaxTokenCount = 1;
			
	});

	return formatter;

}

@end
