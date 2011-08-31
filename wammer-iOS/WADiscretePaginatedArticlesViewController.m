//
//  WADiscretePaginatedArticlesViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/31/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WADiscretePaginatedArticlesViewController.h"

@implementation WADiscretePaginatedArticlesViewController

- (void) loadView {

	self.view = [[[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame] autorelease];
	self.view.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
	
}

-	(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return YES;
}

- (void) reloadViewContents {
	
	NSLog(@"Now it’s time to reload stuff — fetched %@", self.fetchedResultsController.fetchedObjects);

}

@end
