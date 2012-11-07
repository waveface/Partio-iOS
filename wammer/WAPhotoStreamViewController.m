//
//  WAPhotoStreamViewController.m
//  wammer
//
//  Created by jamie on 12/11/6.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAPhotoStreamViewController.h"
#import "CoreData+MagicalRecord.h"
#import "WAFile.h"
#import "WADataStore.h"
#import "WAPhotoStreamViewCell.h"

@interface WAPhotoStreamViewController (){
	NSArray *colorPalette;
	NSArray *photos;
	NSArray *daysOfPhotos;
}

@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation WAPhotoStreamViewController

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
	// Do any additional setup after loading the view from its nib.
	
	[self.collectionView registerClass:[WAPhotoStreamViewCell class]
					forCellWithReuseIdentifier:kPhotoStreamCellID];
	
	colorPalette = @[
	[UIColor colorWithRed:5/255.0 green:242/255.0 blue:242/255.0 alpha:1.0],
	[UIColor colorWithRed:4/255.0 green:191/255.0 blue:191/255.0 alpha:1.0],
	[UIColor colorWithRed:238/255.0 green:241/255.0 blue:217/255.0 alpha:1.0],
	[UIColor colorWithRed:166/255.0 green:2/255.0 blue:1/255.0 alpha:1.0],
	[UIColor colorWithRed:126/255.0 green:16/255.0 blue:14/255.0 alpha:1.0]
	];
	
	UIImage *menuImage = [UIImage imageNamed:@"menu"];
	UIButton *slidingMenuButton = [UIButton buttonWithType:UIButtonTypeCustom];
	slidingMenuButton.frame = (CGRect) {CGPointZero, menuImage.size};
	[slidingMenuButton setBackgroundImage:menuImage forState:UIControlStateNormal];
	[slidingMenuButton setShowsTouchWhenHighlighted:YES];
	[slidingMenuButton addTarget:self.delegate action:@selector(toggleLeftView) forControlEvents:UIControlEventTouchUpInside];
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:slidingMenuButton];

	photos = [WAFile MR_findAllSortedBy:@"identifier" ascending:YES];
	
}

- (void)viewWillAppear:(BOOL)animated {
}


- (void)viewWillDisappear:(BOOL)animated {
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark Collection delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return [photos count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	WAPhotoStreamViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kPhotoStreamCellID forIndexPath:indexPath];
	
	if (cell) {
		cell.backgroundColor = colorPalette[rand()%[colorPalette count]];
		WAFile *photo = (WAFile *)photos[indexPath.row];
		cell.imageView.image = photo.thumbnailImage;
	}
	
	return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	static int remaining_width = 4;
	int width = rand()%remaining_width+1;
	remaining_width -= width;
	if (remaining_width == 0)
		remaining_width = 4;
	int height_factor = 1;//rand()%2+1;
	return (CGSize){75*width+6*(width-1),75*height_factor+8*(height_factor-1)};
}

#pragma mark Swipe gesture

@end
