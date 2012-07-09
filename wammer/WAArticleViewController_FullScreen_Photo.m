//
//  WAArticleViewController_FullScreen_Photo.m
//  wammer
//
//  Created by Evadne Wu on 12/22/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "WAArticleViewController_FullScreen_Photo.h"
#import "AQGridView.h"

#import "WAArticleViewController+Subclasses.h"
#import "WACompositionViewPhotoCell.h"

#import "WAGalleryViewController.h"

#import "WAArticle.h"

#import "WAAppearance.h"


@interface WAArticleViewController_FullScreen_Photo () <AQGridViewDelegate, AQGridViewDataSource, NSFetchedResultsControllerDelegate>

@property (nonatomic, readwrite, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite, retain) AQGridView *gridView;

- (WAFile *) itemAtIndex:(NSUInteger)index;
- (NSUInteger) indexOfItem:(WAFile *)aFile;

@property (nonatomic, readwrite, assign) BOOL requiresGalleryReload;

@end


@implementation WAArticleViewController_FullScreen_Photo
@synthesize fetchedResultsController;
@synthesize gridView = _gridView;
@synthesize requiresGalleryReload;

- (void) dealloc {

	fetchedResultsController.delegate = nil;
	_gridView.delegate = nil;

}

- (void) viewDidLoad {

	[super viewDidLoad];
	
	self.gridView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.gridView.clipsToBounds = NO;
	
	NSMutableArray *allStackElements = [self.stackView mutableStackElements];

	UIView *footerCell = self.footerCell;
	if ([allStackElements containsObject:footerCell]) {
		[allStackElements removeObject:footerCell];
	}
	
	UIView *gridViewWrapper = [[UIView alloc] initWithFrame:self.gridView.bounds];
	gridViewWrapper.clipsToBounds = YES;
	
	[gridViewWrapper addSubview:self.gridView];
	
	UIView *gridBackgroundView = WAStandardArticleStackCellCenterBackgroundView();
	gridBackgroundView.frame = gridViewWrapper.bounds;
	gridBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[gridViewWrapper addSubview:gridBackgroundView];
	[gridViewWrapper sendSubviewToBack:gridBackgroundView];
	
	gridViewWrapper.clipsToBounds = NO;
	self.gridView.clipsToBounds = NO;
	
	[allStackElements addObject:gridViewWrapper];
	
	[self.stackView layoutSubviews];
	[self.gridView reloadData];
	
}

- (void) viewDidUnload {
	
	self.gridView = nil;
	
	[super viewDidUnload];

}

- (void) viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];
	
	[self.stackView layoutSubviews];
	[self.gridView reloadData];
	
	self.gridView.contentOffset = (CGPoint){
		-1 * self.gridView.contentInset.left,
		-1 * self.gridView.contentInset.top
	};
	
}

- (NSFetchedResultsController *) fetchedResultsController {

	if (fetchedResultsController)
		return fetchedResultsController;
		
	NSFetchRequest *fetchRequest = [[WADataStore defaultStore] newFetchRequestForFilesInArticle:self.article];
	
	fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.article.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	fetchedResultsController.delegate = self;
	
	NSError *fetchError = nil;
	if (![fetchedResultsController performFetch:&fetchError])
		NSLog(@"Error fetching: %@", fetchError);
	
	return fetchedResultsController;

}

- (AQGridView *) gridView {

	if (!_gridView) {
	
		_gridView = [[AQGridView alloc] initWithFrame:(CGRect){ CGPointZero, (CGSize){ 320, 128 }}];
		_gridView.delegate = self;
		_gridView.dataSource = self;
		
		_gridView.bounces = YES;
		_gridView.alwaysBounceVertical = YES;
		_gridView.alwaysBounceHorizontal = NO;
		
		_gridView.contentInset = (UIEdgeInsets){ 4.0f, 0.0f, 0.0f, 0.0f };
	
	}
	
	return _gridView;

}

- (NSUInteger) numberOfItemsInGridView:(AQGridView *)gridView {

	return [[self.fetchedResultsController fetchedObjects] count];

}

- (AQGridViewCell *) gridView:(AQGridView *)aGV cellForItemAtIndex:(NSUInteger) index {

	WAFile *representedFile = [self itemAtIndex:index];

	NSString * const identifier = @"Cell";
	WACompositionViewPhotoCell *dequeuedCell = (WACompositionViewPhotoCell *)[aGV dequeueReusableCellWithIdentifier:identifier];
	
	if (dequeuedCell) {
	
		dequeuedCell.representedFile = representedFile;
	
	} else {
	
		dequeuedCell = [WACompositionViewPhotoCell cellRepresentingFile:representedFile reuseIdentifier:identifier];
		
		dequeuedCell.style = WACompositionViewPhotoCellBorderedPlainStyle;
		dequeuedCell.canRemove = NO;
		
	}
	
	CGSize cellSize = [self portraitGridCellSizeForGridView:_gridView];
	cellSize.width -= 8;
	cellSize.height -= 8;
	
	dequeuedCell.frame = (CGRect){ CGPointZero, cellSize };

	return dequeuedCell;
	
}

- (CGSize) portraitGridCellSizeForGridView:(AQGridView *)aGV {

	switch ([UIDevice currentDevice].userInterfaceIdiom) {
	
		case UIUserInterfaceIdiomPad: {

			CGRect gvBounds = aGV.bounds;
			CGFloat gvWidth = CGRectGetWidth(gvBounds), gvHeight = CGRectGetHeight(gvBounds);
			
			NSUInteger numberOfItems = [self.article.files count];
			if (numberOfItems > 4) {
			
				CGFloat edgeLength = floorf(gvWidth / 3);
				return (CGSize){ edgeLength, edgeLength };
				
			} else if (numberOfItems > 1) {
				
				CGFloat edgeLength = floorf(gvWidth / 2);
				return (CGSize){ edgeLength, edgeLength };
				
			} else {
				
				CGFloat edgeLength = MIN(gvWidth, gvHeight);
				return (CGSize){ edgeLength, edgeLength };
				
			}
			
			break;
		
		}
		
		case UIUserInterfaceIdiomPhone: {
		
			return (CGSize){ 106, 106 };
		
			break;
		
		}
	
	}
	
}

- (WAFile *) itemAtIndex:(NSUInteger)index {

	return [self.article.files objectAtIndex:index];
	
}

- (NSUInteger) indexOfItem:(WAFile *)aFile {

	return [self.article.files indexOfObject:aFile];

}

- (void) controllerWillChangeContent:(NSFetchedResultsController *)controller {

	if (![self isViewLoaded])
		return;

	requiresGalleryReload = NO;

}

- (void) controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {

	NSParameterAssert(NO);

}

- (void) controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {

	if (![self isViewLoaded])
		return;
	
	if (requiresGalleryReload)
		return;

	if (![anObject isKindOfClass:[WAFile class]]) {
		requiresGalleryReload = YES;
		return;
	}
	
	NSUInteger ownIndex = [self indexOfItem:(WAFile *)anObject];
	if (ownIndex == NSNotFound) {
		requiresGalleryReload = YES;
		return;
	}
	
	WACompositionViewPhotoCell *currentCell = (WACompositionViewPhotoCell *)[_gridView cellForItemAtIndex:ownIndex];
	if (![currentCell isKindOfClass:[WACompositionViewPhotoCell class]])
		return;	//	It will just show new stuff the next time it shows up
	
}

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller {

	if (![self isViewLoaded])
		return;
	
	if (requiresGalleryReload)
		[_gridView reloadData];

}

- (void) gridView:(AQGridView *)aGV didSelectItemAtIndex:(NSUInteger)index {

	__weak WAGalleryViewController *galleryVC = nil;
	
	galleryVC = [WAGalleryViewController controllerRepresentingArticleAtURI:[[self.article objectID] URIRepresentation] context:[NSDictionary dictionaryWithObjectsAndKeys:
	
		[[[self itemAtIndex:index] objectID] URIRepresentation], kWAGalleryViewControllerContextPreferredFileObjectURI,
	
	nil]];
	
	switch ([UIDevice currentDevice].userInterfaceIdiom) {
	
		case UIUserInterfaceIdiomPhone: {
		
			galleryVC.onDismiss = ^ {
				
				[galleryVC.navigationController popViewControllerAnimated:YES];
				
			};
			
			[self.navigationController pushViewController:galleryVC animated:YES];

			break;
		
		}
		
		case UIUserInterfaceIdiomPad: {
		
			galleryVC.onDismiss = ^ {
				
				[galleryVC dismissModalViewControllerAnimated:NO];
				
			};
			
			[self presentModalViewController:galleryVC animated:NO];

			break;
		
		}
	
	}
	
	[aGV deselectItemAtIndex:index animated:NO];

}

- (BOOL) stackView:(IRStackView *)aStackView shouldStretchElement:(UIView *)anElement {

	if ((anElement == _gridView) || [_gridView isDescendantOfView:anElement])
		return YES;
	
	return [super stackView:aStackView shouldStretchElement:anElement];

}

- (CGSize) sizeThatFitsElement:(UIView *)anElement inStackView:(IRStackView *)aStackView {

	if ((anElement == _gridView) || [_gridView isDescendantOfView:anElement]) {
	
		switch ([UIDevice currentDevice].userInterfaceIdiom) {
	
			case UIUserInterfaceIdiomPad: {
			
				return (CGSize){
					CGRectGetWidth(aStackView.bounds),
					1.0f
				};
			
			}
		
			case UIUserInterfaceIdiomPhone: {
		
				return (CGSize){
					CGRectGetWidth(aStackView.bounds),
					(MIN(_gridView.numberOfRows, 2) * _gridView.gridCellSize.height) + _gridView.contentInset.top + _gridView.contentInset.bottom
				};
			
			}
			
		}
		
	}
	
	return [super sizeThatFitsElement:anElement inStackView:aStackView];

}

- (UIView *) scrollableStackElementWrapper {

	return self.gridView.superview;

}

- (UIScrollView *) scrollableStackElement {

	return self.gridView;

}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
		
	[self.gridView reloadData];
	[self.gridView layoutSubviews];

}

- (BOOL) enablesTextStackElementFolding {

	return YES;

}

@end
