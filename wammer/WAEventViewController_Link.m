//
//  WAEventViewController_Links.m
//  wammer
//
//  Created by Shen Steven on 11/5/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAEventViewController_Link.h"
#import "WAEventLinkViewCell.h"
#import "WAFile.h"

@interface WAEventViewController_Link ()

@end

@implementation WAEventViewController_Link

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

	[self.itemsView registerNib:[UINib nibWithNibName:@"WAEventLinkViewCell" bundle:nil] forCellWithReuseIdentifier:@"WAEventLinkViewCell"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CollectionView datasource

- (UICollectionViewCell*) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	WAEventLinkViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"WAEventLinkViewCell" forIndexPath:indexPath];
	
	WAFile *file = [self.article.files objectAtIndex:indexPath.row];
	[cell.imageView irUnbind:@"image"];
	[cell.imageView irBind:@"image" toObject:file keyPath:@"extraSmallThumbnailImage" options:[NSDictionary dictionaryWithObjectsAndKeys: (id)kCFBooleanTrue, kIRBindingsAssignOnMainThreadOption, nil]];
	
	cell.webTitle.text = file.webTitle;
	cell.webURL.text = file.webURL;
	
	return cell;
	
}


#pragma mark - UICollectionViewFlowLayout delegate
- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {

	UIEdgeInsets sectionInsets = [(UICollectionViewFlowLayout*)collectionViewLayout sectionInset];
	return (CGSize){CGRectGetWidth(collectionView.frame) - sectionInsets.left - sectionInsets.right, 130};
	
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
	
	return 8.0f;

}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
	
	return 8.0f;
	
}

#pragma mark - CollectionView delegate
- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
}

@end
