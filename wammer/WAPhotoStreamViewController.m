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
	NSMutableArray *photos;
	NSArray *daysOfPhotos;
	NSDate *onDate;
}

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation WAPhotoStreamViewController

- (id)initWithDate:(NSDate *)aDate {
	self = [super init];
	if (self) {
		onDate = aDate;
	}
	return self;
}

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
	[UIColor colorWithRed:224/255.0 green:96/255.0 blue:76/255.0 alpha:1.0],
	[UIColor colorWithRed:118/255.0 green:170/255.0 blue:204/255.0 alpha:1.0],
	[UIColor colorWithRed:1.000 green:0.651 blue:0.000 alpha:1.000],
	[UIColor colorWithRed:0.486 green:0.612 blue:0.208 alpha:1.000],
	[UIColor colorWithRed:0.176 green:0.278 blue:0.475 alpha:1.000]
	];
	
	UIImage *menuImage = [UIImage imageNamed:@"menu"];
	UIButton *slidingMenuButton = [UIButton buttonWithType:UIButtonTypeCustom];
	slidingMenuButton.frame = (CGRect) {CGPointZero, menuImage.size};
	[slidingMenuButton setBackgroundImage:menuImage forState:UIControlStateNormal];
	[slidingMenuButton setShowsTouchWhenHighlighted:YES];
	[slidingMenuButton addTarget:self.delegate action:@selector(toggleLeftView) forControlEvents:UIControlEventTouchUpInside];
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:slidingMenuButton];

	NSPredicate *theDay = [NSCompoundPredicate andPredicateWithSubpredicates:@[
												 [NSPredicate predicateWithFormat:@"files.@count > 0"],
												 [NSPredicate predicateWithFormat:@"creationDate = %@", onDate]
												 ]];
	NSArray *eventsOnTheDate = [WAArticle MR_findAllWithPredicate:theDay];
	photos = [[NSMutableArray alloc] init];
	for (WAArticle *event in eventsOnTheDate) {
    [photos addObjectsFromArray:[event.files array]];
	}
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
	
	static int remaining_width = 2;
	int width = rand()%remaining_width+1;
	remaining_width -= width;
	if (remaining_width == 0)
		remaining_width = 2;
	int height_factor = 1;//rand()%2+1;
	
	return (CGSize){156*width+6*(width-1),156*height_factor+8*(height_factor-1)};
}

@end
