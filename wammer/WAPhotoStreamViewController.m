//
//  WAPhotoStreamViewController.m
//  wammer
//
//  Created by jamie on 12/11/6.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAPhotoStreamViewController.h"

static NSString *kPhotoStreamCellID = @"PhotoStreamCell";

@interface WAPhotoStreamViewController (){
	NSArray *colorPalette;
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
	
	[self.collectionView registerClass:[UICollectionViewCell class]
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
	//	[slidingMenuButton setBackgroundImage:[UIImage imageNamed:@"menuHL"] forState:UIControlStateHighlighted];
	[slidingMenuButton setShowsTouchWhenHighlighted:YES];
	[slidingMenuButton addTarget:self.delegate action:@selector(toggleLeftView) forControlEvents:UIControlEventTouchUpInside];
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:slidingMenuButton];
	
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark Collection delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return 300;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kPhotoStreamCellID forIndexPath:indexPath];
	
	if (cell) {
		cell.backgroundColor = colorPalette[rand()%[colorPalette count]];
	}
	
	return cell;
}


@end
