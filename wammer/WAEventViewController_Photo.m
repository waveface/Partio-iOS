//
//  WAEventViewController_Photo.m
//  wammer
//
//  Created by Shen Steven on 11/5/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAEventViewController_Photo.h"
#import "WAEventPhotoViewCell.h"
#import "WAFile+LazyImages.h"
#import "WAGalleryViewController.h"
#import "IRBindings.h"
#import "WAAppearance.h"
#import "WAEventActionsViewController.h"

@interface WAEventViewController_Photo () 

@property (nonatomic, strong) UICollectionView *itemsView;

@end

@implementation WAEventViewController_Photo {
	NSMutableArray *morePhotoBtnImages ;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
			

    }
    return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	morePhotoBtnImages = [NSMutableArray arrayWithArray:@[@"add-DB", @"add-G", @"add-LB", @"add-O", @"add-Red"]];

	__weak WAEventViewController *wSelf = self;
	
	self.navigationItem.rightBarButtonItem = WABarButtonItem([UIImage imageNamed:@"action"], nil, ^{
		WAEventActionsViewController *editingModeVC = [WAEventActionsViewController new];
		editingModeVC.article = wSelf.article;

		WANavigationController *navVC = [[WANavigationController alloc] initWithRootViewController:editingModeVC];
		if (isPad()) {
			
			navVC.modalPresentationStyle = UIModalPresentationCurrentContext;
			navVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

		} else
			navVC.modalPresentationStyle = UIModalPresentationPageSheet;

		[wSelf presentViewController:navVC animated:YES completion:nil];
	});
	
	[self.itemsView registerClass:[WAEventPhotoViewCell class] forCellWithReuseIdentifier:@"EventPhotoCell"];
	
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CollectionView datasource

- (UICollectionViewCell*) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

	WAEventPhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"EventPhotoCell" forIndexPath:indexPath];
	
	if (self.article.files.count) {
	
		WAFile *file = [self.article.files objectAtIndex:indexPath.row];

		[cell.imageView irUnbind:@"image"];

		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		
			[cell.imageView irBind:@"image" toObject:file keyPath:@"extraSmallThumbnailImage" options:[NSDictionary dictionaryWithObjectsAndKeys: (id)kCFBooleanTrue, kIRBindingsAssignOnMainThreadOption, nil]];

		});
		
	} else {
		
		int index = arc4random() % morePhotoBtnImages.count;

		cell.contentView.frame = CGRectInset(cell.contentView.frame, 5, 5);
		cell.imageView.frame = CGRectInset(cell.contentView.frame, 20, 20);
		cell.imageView.backgroundColor = [UIColor clearColor];
		cell.imageView.image = [UIImage imageNamed:morePhotoBtnImages[index]];
		cell.contentView.backgroundColor = [UIColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:1];
		cell.backgroundColor = [UIColor whiteColor]; // create a white frame outside the image
		
		[morePhotoBtnImages removeObjectAtIndex:index];
		
	}

	return cell;
	
}

#pragma mark - UICollectionViewFlowLayout delegate
- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	return (CGSize){100, 100};
	
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
	
	return 3.0f;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {

	return 5.0f;
	
}

#pragma mark - CollectionView delegate
- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

	__weak WAGalleryViewController *galleryVC = nil;
	
	if (!self.article.files.count) {
		//TODO: popup UI to add some photos
		return;
	}
	
	WAFile *file = [self.article.files objectAtIndex:indexPath.row];
	
	galleryVC = [WAGalleryViewController
							 controllerRepresentingArticleAtURI:[[self.article objectID] URIRepresentation]
							 context:[NSDictionary dictionaryWithObjectsAndKeys: [[file objectID] URIRepresentation], kWAGalleryViewControllerContextPreferredFileObjectURI, nil]];
	
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
				
				[galleryVC dismissViewControllerAnimated:NO completion:nil];
				
			};
			
			[self presentViewController:galleryVC animated:NO completion:nil];
			
			break;
			
		}
			
	}

	
}


@end
