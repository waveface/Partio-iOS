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

@interface WAArticleViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) WAArticle *article;

- (void) refreshView;

@end


@implementation WAArticleViewController
@synthesize managedObjectContext, article;
@synthesize contextInfoContainer, mainContentView, avatarView, relativeCreationDateLabel, userNameLabel, articleDescriptionLabel;

+ (WAArticleViewController *) controllerRepresentingArticle:(NSURL *)articleObjectURL {

	WAArticleViewController *returnedController = [[[self alloc] initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]] autorelease];
	
	returnedController.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
	returnedController.article = (WAArticle *)[returnedController.managedObjectContext irManagedObjectForURI:articleObjectURL];
	
	return returnedController;

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

	[managedObjectContext release];
	[article release];
	
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
	self.avatarView.image = self.article.owner.avatar;
	
	if (!self.userNameLabel.text)
		self.userNameLabel.text = @"A Certain User";
	
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
	for (UIView *aView in self.mainContentView.subviews) {
		CGFloat oldShadowOpacity = aView.layer.shadowOpacity;
		aView.layer.shadowOpacity = 0.0f;
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * duration), dispatch_get_main_queue(), ^ {
			aView.layer.shadowOpacity = oldShadowOpacity;
		});
	}
	
}





- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	return 0;

}

@end
