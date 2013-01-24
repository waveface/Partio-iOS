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
#import <CoreData+MagicalRecord.h>
#import "WACollection+RemoteOperations.h"

#import "UIKit+IRAdditions.h"
#import "GAI.h"

@interface WAEventActionsViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MFMailComposeViewControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIAlertViewDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) UICollectionView *itemsView;
@property (nonatomic, strong) NSMutableIndexSet *selectedPhotos;
@property (nonatomic, strong) UIPickerView *collectionPicker;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation WAEventActionsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.selectedPhotos = [NSMutableIndexSet new];
    self.collectionPicker = [[UIPickerView alloc] init];
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
  
  // Set up collection picker
  CGSize size = self.view.frame.size;
  _collectionPicker.frame = CGRectMake( 0.0, size.height-_collectionPicker.frame.size.height-44.0, size.width, 216.0 );
  _collectionPicker.hidden = YES;
  _collectionPicker.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
  _collectionPicker.showsSelectionIndicator = YES;
  _collectionPicker.delegate = self;
  _collectionPicker.dataSource =self;
  [self.view addSubview:_collectionPicker];
  
  NSPredicate *allCollections = [NSPredicate predicateWithFormat:@"isHidden == FALSE"];
  _fetchedResultsController = [WACollection MR_fetchAllSortedBy:@"modificationDate"
                                                      ascending:NO
                                                  withPredicate:allCollections
                                                        groupBy:nil
                                                       delegate:self
                                                      inContext:[_article managedObjectContext]
                               ];
  [_collectionPicker selectRow:1 inComponent:0 animated:NO];
  
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
    
    [[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Events"
                                                     withAction:@"Export"
                                                      withLabel:SLname
                                                      withValue:nil];
    
  };
  
  // set toolbar buttons
  IRBarButtonItem *fbButton = WABarButtonItem(nil, NSLocalizedString(@"ACTION_FACEBOOK", @"Share to Facebook action"), ^{
    composeForSL(SLServiceTypeFacebook);
  });
  [fbButton setTintColor:[UIColor clearColor]];
  [fbButton setTitleTextAttributes:@{UITextAttributeTextColor: [UIColor whiteColor]} forState:UIControlStateNormal];
  
  IRBarButtonItem *twButton = WABarButtonItem(nil, NSLocalizedString(@"ACTION_TWITTER", @"Share to Twitter action"), ^{
    composeForSL(SLServiceTypeTwitter);
  });
  [twButton setTintColor:[UIColor clearColor]];
  [twButton setTitleTextAttributes:@{UITextAttributeTextColor: [UIColor whiteColor]} forState:UIControlStateNormal];
  
  IRBarButtonItem *clButton = WABarButtonItem(nil, NSLocalizedString(@"ACTION_COLLECTION", @"Place photos in collections"), ^{
    __strong WAEventActionsViewController *strongSelf = wSelf;
    strongSelf.collectionPicker.hidden = NO;
    strongSelf.navigationController.toolbarHidden = YES;
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ACTION_ADD_TO_COLLECTION", @"In event view")
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(collectionSelected)];
    strongSelf.navigationItem.rightBarButtonItem = doneButton;
  });
  [clButton setTintColor:[UIColor clearColor]];
  [clButton setTitleTextAttributes:@{UITextAttributeTextColor: [UIColor whiteColor]} forState:UIControlStateNormal];
  
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
    
    [[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Events"
                                                     withAction:@"Export"
                                                      withLabel:@"Mail"
                                                      withValue:nil];
    
  });
  [mlButton setTintColor:[UIColor clearColor]];
  [mlButton setTitleTextAttributes:@{UITextAttributeTextColor: [UIColor whiteColor]} forState:UIControlStateNormal];
  
  self.toolbarItems = @[fbButton, twButton, clButton, mlButton];
  
  self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
  self.navigationController.navigationBar.tintColor = [UIColor clearColor];
  [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
  
  self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;
  self.navigationController.toolbar.tintColor = [UIColor clearColor];
  
  self.navigationItem.leftBarButtonItem = (UIBarButtonItem*)WABarButtonItem(nil, NSLocalizedString(@"ACTION_CANCEL", nil), ^{
    
    [wSelf.navigationController dismissViewControllerAnimated:YES completion:nil];
    
  });
  [self.navigationItem.leftBarButtonItem setTintColor:[UIColor clearColor]];
  [self.navigationItem.leftBarButtonItem setTitleTextAttributes:@{UITextAttributeTextColor: [UIColor whiteColor]} forState:UIControlStateNormal];
  
  [[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Events"
                                                   withAction:@"Enter event actions"
                                                    withLabel:nil
                                                    withValue:nil];
  
}

- (void) viewWillAppear:(BOOL)animated {
  
  [self.navigationController setToolbarHidden:NO animated:animated];
  
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Privates
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

- (void) collectionSelected {
  NSUInteger row = [_collectionPicker selectedRowInComponent:0];
  if (row == 0) { // New Collection
    UIAlertView *alertForName = [[UIAlertView alloc] initWithTitle:@"Collection Name"
                                                           message:@""
                                                          delegate:self
                                                 cancelButtonTitle:@"Cancel"
                                                 otherButtonTitles:@"Create", nil];
    alertForName.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertForName textFieldAtIndex:0].text = _article.eventDescription;
    [alertForName show];
    
  } else { // Add to Collection
    WACollection *selectedCollection = [_fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:row-1 inSection:0]];
    
    NSMutableOrderedSet *orderedSet = [selectedCollection.files mutableCopy];
    [orderedSet addObjectsFromArray:[_article.files objectsAtIndexes:self.selectedPhotos]];
    
    selectedCollection.files = orderedSet;
    
    NSError *error;
    if(![[selectedCollection managedObjectContext] save:&error]){
      NSLog(@"Add to Collection failed: %@", error);
    }
  
    [_collectionPicker setHidden:YES];
    self.navigationController.toolbarHidden = NO;
    self.navigationItem.rightBarButtonItem = nil;
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
  }

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

#pragma mark - UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
  return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
  return [[[_fetchedResultsController sections] objectAtIndex:0] numberOfObjects]+1;
}

#pragma mark - UIPickerViewDelegate
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
  if (row == 0) {
    return NSLocalizedString(@"NEW_COLLECTION", @"In collection picker view");
  }
  WACollection *selectedCollection = [_fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:row-1 inSection:0]];
  return [NSString stringWithFormat:@"%@ (%d)", selectedCollection.title, [selectedCollection.files count]];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  NSString *collectionName = [alertView textFieldAtIndex:0].text;
  NSManagedObjectContext *context = [_article managedObjectContext];
  WACollection *collection = [[WACollection alloc] initWithName:collectionName
                                                      withFiles:[_article.files objectsAtIndexes:self.selectedPhotos]
                                         inManagedObjectContext:context];
  collection.creator = _article.owner;
  NSError *error;
  if ([context save:&error]==NO){
    NSLog(@"Save error: %@", error);
  }
  [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
