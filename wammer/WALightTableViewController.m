//
//  WALightTableViewController.m
//  wammer
//
//  Created by jamie on 12/10/25.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WALightTableViewController.h"
#import "WALightTableViewCell.h"
#import "WAArticle.h"
#import "WADataStore.h"

@interface WALightTableViewController ()

@end

@implementation WALightTableViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	// Do any additional setup after loading the view.
	self.navigationController.toolbarHidden = NO;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - Collection view data source
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
									cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"LightTableCell";
	WALightTableViewCell *cell = [collectionView
																dequeueReusableCellWithReuseIdentifier:CellIdentifier
																forIndexPath:indexPath];
	
	if(cell){
		WAFile *file = (WAFile *)[self.fetchedResultsController objectAtIndexPath:indexPath];
		cell.image.image = file.thumbnailImage;
	}
	return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
		 numberOfItemsInSection:(NSInteger)section {
	return [[self.fetchedResultsController fetchedObjects] count];
}

#pragma mark - Collection view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	
}

#pragma mark - IBActions

- (void)handleCancel:(UIBarButtonItem *)barButtonItem{
	[_delegate lightTableViewDidDismiss:self];
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController {
	if (_fetchedResultsController)
		return _fetchedResultsController;
	
	NSFetchRequest *fetchForFiles = [[WADataStore defaultStore] newFetchRequestForFilesInArticle:self.article];
	_fetchedResultsController = [[NSFetchedResultsController alloc]
															 initWithFetchRequest:fetchForFiles
															 managedObjectContext:self.article.managedObjectContext
															 sectionNameKeyPath:nil
															 cacheName:nil];
	_fetchedResultsController.delegate = self;
	
	NSError *fetchError;
	if (![_fetchedResultsController performFetch:&fetchError]){
		NSLog(@"Fetch Error: %@", fetchError);
	}
	
	return _fetchedResultsController;
}

@end
