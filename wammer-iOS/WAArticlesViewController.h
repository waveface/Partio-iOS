//
//  WAArticlesViewController.h
//  wammer-iOS
//
//  Created by Evadne Wu on 8/31/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

//	The WAArticlesViewController is now refactored as a shared superclass used by both the root view controller for the iPhone and the iPad — it only works with Core Data, and provides persistence layer support for different view controllers to use.  It does not manage any view hierarchy on its own.

#import "WAApplicationRootViewControllerDelegate.h"

@interface WAArticlesViewController : UIViewController <WAApplicationRootViewController, NSFetchedResultsControllerDelegate>

@property (nonatomic, readonly, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readonly, retain) NSManagedObjectContext *managedObjectContext;

- (void) refreshData;
- (void) reloadViewContents;

- (NSURL *) representedObjectURIForInterfaceItem:(UIView *)aView;
- (UIView *) interfaceItemForRepresentedObjectURI:(NSURL *)anURI createIfNecessary:(BOOL)createsOffsecreenItemIfNecessary;	//	 Might return nil if the item is not there


//	Overriding points for introducing additional user interface notifications
- (void) remoteDataLoadingWillBegin;
- (void) remoteDataLoadingDidEnd;
- (void) remoteDataLoadingDidFailWithError:(NSError *)anError;

@end
