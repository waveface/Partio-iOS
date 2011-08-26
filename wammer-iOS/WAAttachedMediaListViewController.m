//
//  WAAttachedMediaListViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/26/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WAAttachedMediaListViewController.h"


@interface WAAttachedMediaListViewController ()

@property (nonatomic, readwrite, copy) void(^callback)(NSURL *objectURI);

@end


@implementation WAAttachedMediaListViewController
@synthesize callback;

+ (WAAttachedMediaListViewController *) controllerWithArticleURI:(NSURL *)anArticleURI completion:(void(^)(NSURL *objectURI))aBlock {

	return [[[self alloc] initWithArticleURI:anArticleURI completion:aBlock] autorelease];

}

- (id) init {

	return [self initWithArticleURI:nil completion:nil];

}

- (WAAttachedMediaListViewController *) initWithArticleURI:(NSURL *)anArticleURI completion:(void (^)(NSURL *))aBlock {

	self = [super init];
	if (!self)
		return nil;
	
	__block __typeof__(self) nrSelf = self;
		
	self.navigationItem.rightBarButtonItem = [IRBarButtonItem itemWithSystemItem:UIBarButtonSystemItemDone wiredAction:^(IRBarButtonItem *senderItem) {
		
		if (nrSelf.callback)
			nrSelf.callback(nil);
		
	}];
	
	self.callback = aBlock;
	
	self.title = @"Attachments";
	
	return self;

}

- (void) dealloc {

	[callback release];
	[super dealloc];

}





- (void) loadView {

	self.view = [[[UIView alloc] initWithFrame:[UIApplication sharedApplication].keyWindow.rootViewController.view.bounds] autorelease]; // dummy size for autoresizing
	
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPhotoQueueBackground"]];

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

@end
