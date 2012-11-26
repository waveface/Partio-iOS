//
//  WAEventActionsViewController.m
//  wammer
//
//  Created by Shen Steven on 11/25/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Social/Social.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "WAEventActionsViewController.h"
#import "WAAppearance.h"
#import "WAEventViewController.h"
#import "WAEventPhotoViewCell.h"
#import "WAFile.h"
#import "WAFile+LazyImages.h"
#import "WAUser.h"
#import "WADataStore.h"

@interface WAEventActionsViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) UICollectionView *itemsView;
@property (nonatomic, strong) NSMutableIndexSet *selectedPhotos;

@end

@implementation WAEventActionsViewController 

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
			self.selectedPhotos = [NSMutableIndexSet new];
    }
    return self;
}

void (^displayAlert)(NSString *, NSString *) = ^(NSString *title, NSString *msg) {
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	
};

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	CGRect rect = (CGRect){ CGPointZero, self.view.frame.size };
	
	UICollectionViewFlowLayout *flowlayout = [[UICollectionViewFlowLayout alloc] init];
	flowlayout.scrollDirection = UICollectionViewScrollDirectionVertical;
	flowlayout.sectionInset = UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f);
	self.itemsView = [[UICollectionView alloc] initWithFrame:rect
																			collectionViewLayout:flowlayout];
	self.itemsView.backgroundColor = [UIColor colorWithWhite:0.260 alpha:1.000];
	self.itemsView.bounces = YES;
	self.itemsView.alwaysBounceVertical = YES;
	self.itemsView.alwaysBounceHorizontal = NO;
	self.itemsView.allowsSelection = YES;
	self.itemsView.allowsMultipleSelection = YES;
	self.itemsView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	
	self.itemsView.dataSource = self;
	self.itemsView.delegate = self;
	
	[self.itemsView registerClass:[WAEventPhotoViewCell class] forCellWithReuseIdentifier:@"EventPhotoCell"];

	[self.view addSubview:self.itemsView];

	__weak WAEventActionsViewController *wSelf = self;
	
	// Social network service posts
	void (^composeForSL)(NSString *) = ^(NSString *SLname) {
		if (![SLComposeViewController isAvailableForServiceType:SLname]) {
			displayAlert(nil, [NSString stringWithFormat:@"You didn't login your %@ account", SLname]);
			return;
		}
		
		SLComposeViewController *composeVC = [SLComposeViewController composeViewControllerForServiceType:SLname];
		[composeVC setInitialText:[WAEventViewController attributedDescriptionStringForEvent:wSelf.article].string];
		NSArray *allImages = [wSelf imagesSelected];
		[allImages enumerateObjectsUsingBlock:^(UIImage *image, NSUInteger idx, BOOL *stop) {
			[composeVC addImage:image];
		}];
		
		__weak SLComposeViewController *wComposeVC = composeVC;
		composeVC.completionHandler = ^ (SLComposeViewControllerResult result){
			[wComposeVC dismissViewControllerAnimated:YES completion:nil];
		};
		[wSelf presentViewController:composeVC animated:YES completion:nil];		
	};
	
	// set toolbar buttons
	IRBarButtonItem *fbButton = WABarButtonItem(nil, NSLocalizedString(@"ACTION_FACEBOOK", @"Share to Facebook action"), ^{
		composeForSL(SLServiceTypeFacebook);
	});
	
	IRBarButtonItem *twButton = WABarButtonItem(nil, NSLocalizedString(@"ACTION_TWITTER", @"Share to Twitter action"), ^{
		composeForSL(SLServiceTypeTwitter);
	});
	
	IRBarButtonItem *clButton = WABarButtonItem(nil, NSLocalizedString(@"ACTION_COLLECTION", @"Place photos in collections"), ^{
		displayAlert(@"Sorry", @"Collection editiing will be available soon.");
	});
	
	IRBarButtonItem *mlButton = WABarButtonItem(nil, NSLocalizedString(@"ACTION_EMAIL", @"Share thru Email"), ^{
		
		if (![MFMailComposeViewController canSendMail])
			return;
		
		MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
		mailer.mailComposeDelegate = wSelf;
		WAUser *user = [[WADataStore defaultStore] mainUserInContext:[[WADataStore defaultStore] disposableMOC]];
		NSString *subject = [NSString stringWithFormat:NSLocalizedString(@"MAIL_ACTION_SUBJECT", @"The email subject users will share photos thru. The nickname of user will be appended to this subject."), user.nickname];
		[mailer setSubject:subject];
		NSString *body = [WAEventViewController attributedDescriptionStringForEvent:wSelf.article].string;
		[mailer setMessageBody:body isHTML:NO];

		[wSelf.selectedPhotos enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			
			WAFile *file = wSelf.article.files[idx];
			NSString *imageFilename = [NSString stringWithFormat:@"image-%d.jpg", idx];
			[mailer addAttachmentData:[NSData dataWithContentsOfFile:file.smallThumbnailFilePath] mimeType:@"image/jpeg" fileName:imageFilename];

		}];
		[wSelf presentViewController:mailer animated:YES completion:nil];
		
	});


	self.toolbarItems = @[fbButton, twButton, clButton, mlButton];
	
	self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	self.navigationController.navigationBar.tintColor = [UIColor clearColor];
	
	self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;
	self.navigationController.toolbar.tintColor = [UIColor clearColor];
	
	self.navigationItem.leftBarButtonItem = (UIBarButtonItem*)WABarButtonItem(nil, NSLocalizedString(@"ACTION_CANCEL", nil), ^{
		
		[wSelf.navigationController dismissViewControllerAnimated:YES completion:nil];
		
	});
}

- (void) viewWillAppear:(BOOL)animated {
	
	[self.navigationController setToolbarHidden:NO animated:animated];
	
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSArray*) imagesSelected {
	
	NSMutableArray *marray = [NSMutableArray array];
	__weak WAEventActionsViewController *wSelf = self;
	[self.selectedPhotos enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		WAFile *file = wSelf.article.files[idx];
		[marray addObject:file.smallThumbnailImage];
	}];
	
	return [NSArray arrayWithArray:marray];
	
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
	
	[controller dismissViewControllerAnimated:YES completion:nil];
	
}

#pragma mark - CollectionView datasource
- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	
	return 1;
	
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	
	return self.article.files.count;
	
}

- (UICollectionViewCell*) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	WAEventPhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"EventPhotoCell" forIndexPath:indexPath];
	
	WAFile *file = [self.article.files objectAtIndex:indexPath.row];
	
	if ([self.selectedPhotos containsIndex:indexPath.row]) {
		cell.checkMarkView.hidden = NO;
		cell.checkMarkView.image = [UIImage imageNamed:@"IRAQ-Checkmark"];
	} else {
		cell.checkMarkView.image = nil;
		cell.checkMarkView.hidden = YES;
	}

	[cell.imageView irUnbind:@"image"];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		
		[cell.imageView irBind:@"image" toObject:file keyPath:@"extraSmallThumbnailImage" options:[NSDictionary dictionaryWithObjectsAndKeys: (id)kCFBooleanTrue, kIRBindingsAssignOnMainThreadOption, nil]];
		
	});
	
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
	
	WAEventPhotoViewCell *cell = (WAEventPhotoViewCell*)[collectionView cellForItemAtIndexPath:indexPath];

	cell.checkMarkView.hidden = NO;
	cell.checkMarkView.image = [UIImage imageNamed:@"IRAQ-Checkmark"];

	[self.selectedPhotos addIndex:indexPath.row];
	
}

- (void) collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
	
	WAEventPhotoViewCell *cell = (WAEventPhotoViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
	
	cell.checkMarkView.hidden = YES;
	cell.checkMarkView.image = nil;
	
	[self.selectedPhotos removeIndex:indexPath.row];
	
}


@end
