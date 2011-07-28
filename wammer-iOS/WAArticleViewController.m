//
//  WAArticleViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/28/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WAArticleViewController.h"
#import "WADataStore.h"

#import "WAImageStackView.h"

@interface WAArticleViewController ()

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) WAArticle *article;

- (void) refreshView;

@end


@implementation WAArticleViewController
@synthesize managedObjectContext, article;
@synthesize contextInfoContainer, mainContentView, avatarView, relativeCreationDateLabel, userNameLabel, articleDescriptionLabel, commentRevealButton, commentPostButton, commentCloseButton, compositionAccessoryView, compositionContentField, compositionSendButton, commentsView;

+ (WAArticleViewController *) controllerRepresentingArticle:(NSURL *)articleObjectURL {

	WAArticleViewController *returnedController = [[[self alloc] initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]] autorelease];
	
	returnedController.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
	returnedController.article = (WAArticle *)[returnedController.managedObjectContext irManagedObjectForURI:articleObjectURL];
	
	return returnedController;

}

- (void) dealloc {

	[managedObjectContext release];
	[article release];
	[super dealloc];

}

- (void) viewDidLoad {

	[super viewDidLoad];
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
	self.relativeCreationDateLabel.text = [self.article.timestamp description];
	self.articleDescriptionLabel.text = self.article.text;
	self.mainContentView.files = self.article.files;
	
	#if 1
	
		if (![self.mainContentView.files count]) {

			WAFile *tempFile = [WAFile objectInsertingIntoContext:self.managedObjectContext withRemoteDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
				
					@"FOO", @"url",
				
				nil]];
			
			NSLog(@"tempFile %@", tempFile);
		
			self.mainContentView.files = [NSSet setWithObjects:
				tempFile,			
			nil];
			
			self.mainContentView.files = [NSSet setWithObject:@"FOO BAR"];
			
			NSLog(@"self.mainContentView.files %@", self.mainContentView.files);
		
		}
	
	#endif
	
	self.avatarView.image = self.article.owner.avatar;
	[self.commentsView reloadData]; // Eh?
	
}

//- (void) loadView {
//
//	//	Trigger faulting
//	[self.article timestamp];
//
//	UIView *returnedView = [[[UIView alloc] initWithFrame:(CGRect){ 0, 0, 512, 512 }] autorelease];
//	returnedView.backgroundColor = [UIColor whiteColor];
//	
//	UILabel *descriptionLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
//	descriptionLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin;
//	descriptionLabel.textAlignment = UITextAlignmentCenter;
//	descriptionLabel.font = [UIFont boldSystemFontOfSize:18.0f];
//	descriptionLabel.text = [NSString stringWithFormat:@"<%@ %x> page for article", NSStringFromClass([self class]), self];
//	[descriptionLabel sizeToFit];
//	
//	UILabel *contentLabel = [[[UILabel alloc] initWithFrame:(CGRect){ 0, 0, 512, 512 }] autorelease];
//	contentLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin;
//	contentLabel.text = [self.article description];
//	contentLabel.numberOfLines = 0;
//	[contentLabel sizeToFit];
//	
//	CGPoint contentTopCenterOrigin = (CGPoint){ 0.5f * CGRectGetWidth(returnedView.bounds), 256.0f };
//	contentTopCenterOrigin.y -= 0.5f * CGRectGetHeight(descriptionLabel.frame);
//	contentTopCenterOrigin.y -= 0.5f * 24.0f;
//	contentTopCenterOrigin.y -= 0.5f * CGRectGetHeight(contentLabel.frame);
//	
//	descriptionLabel.frame = CGRectIntegral((CGRect){
//		(CGPoint){
//			contentTopCenterOrigin.x - 0.5f * descriptionLabel.frame.size.width,
//			contentTopCenterOrigin.y
//		},
//		descriptionLabel.frame.size
//	});
//	
//	contentLabel.frame = CGRectIntegral((CGRect){
//		(CGPoint){
//			contentTopCenterOrigin.x - 0.5f * contentLabel.frame.size.width,
//			contentTopCenterOrigin.y + descriptionLabel.frame.size.height + 24.0f
//		},
//		contentLabel.frame.size
//	});
//	
//	[returnedView addSubview:descriptionLabel];
//	[returnedView addSubview:contentLabel];
//	
//	self.view = returnedView;
//
//}

@end
