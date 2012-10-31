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
@class WALightTableViewController;

@protocol WALightTableViewDelegate <NSObject>

- (void)lightTableViewDidDismiss: (WALightTableViewController *) lightTableView;

@end

@interface WALightTableViewController : UICollectionViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic, assign) id <WALightTableViewDelegate> delegate;
@property (strong, nonatomic) WAArticle *article;

@property (strong, nonatomic) IBOutlet UICollectionViewFlowLayout *flowLayout;

- (IBAction) handleCancel:(UIBarButtonItem*) sender	;
- (IBAction)handleAddToCollection:(UIBarButtonItem *)sender;
- (IBAction)handleShareToAnything:(UIBarButtonItem *)sender;

@end
