//
//  WALightTableViewController.h
//  wammer
//
//  Created by jamie on 12/10/25.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@class WAArticle;

@interface WALightTableViewController : UICollectionViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) WAArticle *article;
@property	(strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction) handleCancel:(UIBarButtonItem*) barButtonItem	;

@end
