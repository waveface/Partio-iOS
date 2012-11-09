//
//  WAEventViewController.h
//  wammer
//
//  Created by Shen Steven on 11/5/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "WAArticle.h"
#import "WAEventHeaderView.h"

@interface WAEventViewController : UIViewController <NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong, readonly) WAEventHeaderView *headerView;

@property (nonatomic, strong) WAArticle *article;
@property (nonatomic, strong, readonly) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong, readonly) UICollectionView *itemsView;

+ (WAEventViewController *) controllerForArticle:(WAArticle *)article;
+ (NSAttributedString *) attributedDescriptionStringForEvent:(WAArticle*)event;
+ (NSAttributedString *) attributedStringForTags:(NSArray*)tags;

@end
