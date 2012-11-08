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

@interface WAEventViewController_Photo () 

@property (nonatomic, strong) UICollectionView *itemsView;

@end

@implementation WAEventViewController_Photo

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
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
	
	WAFile *file = [self.article.files objectAtIndex:indexPath.row];
	[cell.imageView irUnbind:@"image"];
	[cell.imageView irBind:@"image" toObject:file keyPath:@"extraSmallThumbnailImage" options:[NSDictionary dictionaryWithObjectsAndKeys: (id)kCFBooleanTrue, kIRBindingsAssignOnMainThreadOption, nil]];

	return cell;
	
}

#pragma mark - UICollectionViewFlowLayout delegate
- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	return (CGSize){72, 72};
	
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
