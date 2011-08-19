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
@synthesize contextInfoContainer, imageStackView, textEmphasisView, avatarView, relativeCreationDateLabel, userNameLabel, articleDescriptionLabel, deviceDescriptionLabel;
@synthesize onPresentingViewController;

+ (WAArticleViewController *) controllerRepresentingArticle:(NSURL *)articleObjectURL {

	NSManagedObjectContext *usedContext = [[WADataStore defaultStore] disposableMOC];
	WAArticle *usedArticle = (WAArticle *)[usedContext irManagedObjectForURI:articleObjectURL];

	NSString *loadedNibName = [NSStringFromClass([self class]) stringByAppendingFormat:@"-%@", ([usedArticle.files count] ? @"Default" : @"Plaintext")];
	
	WAArticleViewController *returnedController = [[[self alloc] initWithNibName:loadedNibName bundle:[NSBundle bundleForClass:[self class]]] autorelease];
	
	returnedController.managedObjectContext = usedContext;
	returnedController.article = usedArticle;
	
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
		
		if ([self isViewLoaded])
			[self refreshView];
		
		[self.managedObjectContext refreshObject:self.article mergeChanges:YES];
	
	});

}

- (void) viewDidUnload {

	self.contextInfoContainer = nil;
	self.imageStackView = nil;
	self.textEmphasisView = nil;
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
	[imageStackView release];
	[textEmphasisView release];
	[avatarView release];
	[relativeCreationDateLabel release];
	[userNameLabel release];
	[articleDescriptionLabel release];
	
	[super dealloc];

}

- (void) viewDidLoad {

	[super viewDidLoad];
	
	self.avatarView.layer.cornerRadius = 4.0f;
	self.avatarView.layer.masksToBounds = YES;
	
	UIView *avatarContainingView = [[[UIView alloc] initWithFrame:self.avatarView.frame] autorelease];
	avatarContainingView.autoresizingMask = self.avatarView.autoresizingMask;
	self.avatarView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[self.avatarView.superview insertSubview:avatarContainingView belowSubview:self.avatarView];
	[avatarContainingView addSubview:self.avatarView];
	self.avatarView.center = (CGPoint){ CGRectGetMidX(self.avatarView.superview.bounds), CGRectGetMidY(self.avatarView.superview.bounds) };
	avatarContainingView.layer.shadowPath = [UIBezierPath bezierPathWithRect:avatarContainingView.bounds].CGPath;
	avatarContainingView.layer.shadowOpacity = 0.5f;
	avatarContainingView.layer.shadowOffset = (CGSize){ 0, 1 };
	avatarContainingView.layer.shadowRadius = 2.0f;
	
	self.imageStackView.delegate = self;
	
	self.textEmphasisView.frame = (CGRect){ 0, 0, 540, 128 };
	self.textEmphasisView.label.font = [UIFont systemFontOfSize:20.0f];
	self.textEmphasisView.backgroundView = [[[UIView alloc] initWithFrame:self.textEmphasisView.bounds] autorelease];
	self.textEmphasisView.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	
	UIImageView *bubbleView = [[[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"WASpeechBubble"] stretchableImageWithLeftCapWidth:120 topCapHeight:32]] autorelease];
	bubbleView.frame = UIEdgeInsetsInsetRect(self.textEmphasisView.backgroundView.bounds, (UIEdgeInsets){ -28, -32, -32, -32 });
	bubbleView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[self.textEmphasisView.backgroundView addSubview:bubbleView];
	
	((WAView *)self.view).onLayoutSubviews = ^ {
	
		if (self.textEmphasisView && !self.textEmphasisView.hidden) {		
		
			CGRect usableRect = UIEdgeInsetsInsetRect(self.view.bounds, (UIEdgeInsets){ 32, 0, 32, 0 });
		
			[self.textEmphasisView sizeToFit];
			self.textEmphasisView.frame = (CGRect){
				self.textEmphasisView.frame.origin,
				(CGSize) {
					MAX(540, self.textEmphasisView.frame.size.width),
					MIN(480, MAX(144 - 32 - 32, self.textEmphasisView.frame.size.height))
				}
			};
			self.textEmphasisView.center = (CGPoint){
				CGRectGetMidX(usableRect),
				CGRectGetMidY(usableRect)
			};
			self.textEmphasisView.frame = CGRectIntegral(self.textEmphasisView.frame);
			
			self.contextInfoContainer.frame = (CGRect){
				self.contextInfoContainer.frame.origin,
				(CGSize){
					CGRectGetWidth(self.textEmphasisView.frame),
					CGRectGetHeight(self.contextInfoContainer.frame)
				}
			};
			
			self.contextInfoContainer.center = (CGPoint){
				CGRectGetMidX(usableRect),
				CGRectGetMidY(usableRect) + 0.5f * CGRectGetHeight(self.textEmphasisView.frame) + CGRectGetHeight(self.contextInfoContainer.frame) + 10.0f
			};
			
			
			CGRect actualContentRect = CGRectUnion(self.textEmphasisView.frame, self.contextInfoContainer.frame);
			CGFloat delta = roundf(0.5f * (CGRectGetHeight(usableRect) - CGRectGetHeight(actualContentRect))) - CGRectGetMinY(self.textEmphasisView.frame);
			self.textEmphasisView.frame = CGRectOffset(self.textEmphasisView.frame, usableRect.origin.x, usableRect.origin.y + delta);
			self.contextInfoContainer.frame = CGRectOffset(self.contextInfoContainer.frame, usableRect.origin.x, usableRect.origin.y + delta);
			
			[self.relativeCreationDateLabel sizeToFit];
			
			self.deviceDescriptionLabel.frame = (CGRect){
				(CGPoint){
					CGRectGetMaxX(self.relativeCreationDateLabel.frame) + 10,
					self.deviceDescriptionLabel.frame.origin.y
				},
				self.deviceDescriptionLabel.frame.size
			};
						
		} else {
		
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
		
		}
		
	};
	
	[self refreshView];
		
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
	self.imageStackView.files = [self.article.fileOrder irMap: ^ (id inObject, int index, BOOL *stop) {
		return [[self.article.files objectsPassingTest: ^ (WAFile *aFile, BOOL *stop) {		
			return [[[aFile objectID] URIRepresentation] isEqual:inObject];
		}] anyObject];
	}];
	self.avatarView.image = self.article.owner.avatar;
	self.deviceDescriptionLabel.text = [NSString stringWithFormat:@"via %@", self.article.creationDeviceName ? self.article.creationDeviceName : @"an unknown device"];
	
	self.textEmphasisView.label.text = self.article.text;
	self.textEmphasisView.hidden = ([self.article.files count] != 0);
	
	if (!self.userNameLabel.text)
		self.userNameLabel.text = @"A Certain User";
	
	[self.view setNeedsLayout];
	
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	for (UIView *aView in self.imageStackView.subviews) {
	
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
