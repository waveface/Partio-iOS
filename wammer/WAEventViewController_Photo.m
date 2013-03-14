//
//  WAEventViewController_Photo.m
//  wammer
//
//  Created by Shen Steven on 11/5/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAEventViewController_Photo.h"
#import "WAEventPhotoViewCell.h"

#import "WARemoteInterface.h"

#import "WAFile+LazyImages.h"
#import "WADataStore.h"
#import "WACollection.h"
#import "WACollection+RemoteOperations.h"
#import "WACollectionPickerViewController.h"

#import "WAGalleryViewController.h"
#import "IRBindings.h"

#import "WAOverlayBezel.h"
#import "WAAppearance.h"
#import <BlocksKit/BlocksKit.h>
#import "GAI.h"

@interface WAEventViewController_Photo () 

@property (nonatomic, strong) UICollectionView *itemsView;
@property (nonatomic, strong) NSMutableIndexSet *selectedPhotos;
@property (nonatomic, assign) BOOL editing;

@end

@implementation WAEventViewController_Photo {
	NSMutableArray *morePhotoBtnImages ;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

      self.editing = NO;

      self.selectedPhotos = [NSMutableIndexSet indexSet];

      [self.selectedPhotos addObserver:self
                            forKeyPath:@"count"
                               options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                               context:nil];
      
    }
    return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  __weak WAEventViewController_Photo *wSelf = self;

  IRBarButtonItem *shareButton = WABarButtonItem(nil, NSLocalizedString(@"ACTION_SHARE", @"Sharing action in the event view"), ^{
    
    NSMutableArray *activityItems = [@[wSelf.article.text] mutableCopy];
    [activityItems addObjectsFromArray:[wSelf imagesSelected]];
    
    UIActivityViewController *actVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    actVC.completionHandler = ^(NSString *activityType, BOOL completed) {
      [[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Events" withAction:@"Export" withLabel:activityType withValue:@([wSelf.selectedPhotos count])];
    };
    actVC.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll];
    
    [wSelf presentViewController:actVC animated:YES completion:nil];
    
  });

  IRBarButtonItem *collectionButton = WABarButtonItem(nil, NSLocalizedString(@"ACTION_ADD_COLLECTION", @"Adding to collection action in the event view"), ^{
    
    UIActionSheet *actions = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"ACTIONSHEET_TITLE_ADD_COLLECTION", @"The title of action sheets to add selected photos into collection")];
    [actions addButtonWithTitle:NSLocalizedString(@"ACTIONSHEET_ACTION_NEW_COLLECTION", @"The action title to new a collection") handler:^{
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ALERT_TITLE_NEW_COLLECTION", @"The title of an alert view for user to input a collection name") message:@""];
      __weak UIAlertView *wAlert = alert;
      alert.alertViewStyle = UIAlertViewStylePlainTextInput;
      [alert setCancelButtonWithTitle:NSLocalizedString(@"ACTION_CANCEL", @"Cancel adding selected photos into collection") handler:nil];
      [alert addButtonWithTitle:NSLocalizedString(@"ACTION_CREATE_COLLECTION", @"The action to create a new collection") handler:^{
        NSString *collectionName = [wAlert textFieldAtIndex:0].text;
        wSelf.managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
        WACollection *collection = [[WACollection alloc] initWithName:collectionName
                                                            withFiles:[wSelf.article.files objectsAtIndexes:wSelf.selectedPhotos]
                                               inManagedObjectContext:wSelf.managedObjectContext];
        collection.creator = [[WADataStore defaultStore] mainUserInContext:wSelf.managedObjectContext];
        NSError *error;
        if ([wSelf.managedObjectContext save:&error]==NO){
          NSLog(@"Save error: %@", error);
        }

      }];
      [alert show];
    }];
    
    [actions addButtonWithTitle:NSLocalizedString(@"ACTIONSHEET_ACTION_ADD_EXISTING", @"The action title to add selected photos in a collection") handler:^{
      
      __block WACollectionPickerViewController *picker = [WACollectionPickerViewController pickerWithHandler:^(NSManagedObjectID *selectedCollection) {
        
        WACollection *collection = (WACollection*)[wSelf.managedObjectContext objectWithID:selectedCollection];
        
        [collection addObjects:[wSelf.article.files objectsAtIndexes:wSelf.selectedPhotos]];
        
        NSError *error = nil;
        [wSelf.managedObjectContext save:&error];
        if (error) {
          NSLog(@"Fail to save collection for error: %@", error);
        }
        
        [picker dismissViewControllerAnimated:YES completion:nil];
        picker = nil;
      } onCancel:^{
        [picker dismissViewControllerAnimated:YES completion:nil];
        picker = nil;
      }];
      
      wSelf.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
      wSelf.modalPresentationStyle = UIModalPresentationFullScreen;
      [wSelf presentViewController:picker animated:YES completion:nil];
    }];
    
    [actions setCancelButtonWithTitle:NSLocalizedString(@"ACTION_CANCEL", @"Cancel the photos adding to collection") handler:nil];
    
    [actions showFromToolbar:wSelf.navigationController.toolbar];

  });
  
  IRBarButtonItem *deleteButton = WABarButtonItem(nil, NSLocalizedString(@"ACTION_PHOTOS_DELETE", @"Deleting action in the event view"), ^{

    UIActionSheet *actions = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"ACTIONSHEET_TITLE_DELETE_PHOTOS", @"The title of action sheets to delete selected photos")];
    [actions addButtonWithTitle:NSLocalizedString(@"ACTIONSHEET_ACTION_DEL_INEVENT", @"Remove selected photos from event") handler:^{
      
    }];
    
    [actions addButtonWithTitle:NSLocalizedString(@"ACTIONSHEET_ACTION_DELETE", @"Hide the selected photos") handler:^{
      
      NSMutableArray *identifiers = [NSMutableArray array];
      [wSelf.selectedPhotos enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [identifiers addObject:[[wSelf.article.files objectAtIndex:idx] identifier]];
      }];
      
      WAOverlayBezel *busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
      dispatch_async(dispatch_get_main_queue(), ^{
        [busyBezel showWithAnimation:WAOverlayBezelAnimationFade];
      });
      
      [[WARemoteInterface sharedInterface] hideAttachments:identifiers onSuccess:^(NSArray *successIDs) {

        dispatch_async(dispatch_get_main_queue(), ^{
          [busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
        });

      } onFailure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
        });
      }];
      
    }];
    
    [actions setCancelButtonWithTitle:NSLocalizedString(@"ACTION_CANCEL", @"Cancel the photo deletion") handler:nil];
    
    [actions showFromToolbar:wSelf.navigationController.toolbar];

  });

  self.toolbarItems = @[shareButton, collectionButton, deleteButton];
  
  for(UIBarButtonItem *barButton in self.toolbarItems) {
    barButton.enabled = NO;
  }
  
  self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;
  self.navigationController.toolbar.tintColor = [UIColor clearColor];
  self.navigationController.toolbarHidden = YES;
  
  morePhotoBtnImages = [NSMutableArray arrayWithArray:@[@"add-DB", @"add-G", @"add-LB", @"add-O", @"add-Red"]];

	
  IRBarButtonItem *cancelButton = WABarButtonItem(nil, @"Cancel", nil);
  
  IRBarButtonItem *actionButton = WABarButtonItem([UIImage imageNamed:@"action"], nil, ^{
    [wSelf.navigationController setToolbarHidden:NO animated:YES];
    wSelf.navigationItem.rightBarButtonItem = cancelButton;
    wSelf.navigationItem.leftBarButtonItem.enabled = NO;
    wSelf.editing = YES;
    wSelf.itemsView.allowsMultipleSelection = YES;
//		WAEventActionsViewController *editingModeVC = [WAEventActionsViewController new];
//		editingModeVC.article = wSelf.article;
//
//		WANavigationController *navVC = [[WANavigationController alloc] initWithRootViewController:editingModeVC];
//		if (isPad()) {
//			
//			navVC.modalPresentationStyle = UIModalPresentationCurrentContext;
//			navVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
//
//		} else
//			navVC.modalPresentationStyle = UIModalPresentationPageSheet;
//
//		[wSelf presentViewController:navVC animated:YES completion:nil];
	});
  
  cancelButton.block = ^{
    [wSelf.navigationController setToolbarHidden:YES animated:YES];
    wSelf.navigationItem.rightBarButtonItem = actionButton;
    wSelf.navigationItem.leftBarButtonItem.enabled = YES;
    wSelf.editing = NO;
    wSelf.itemsView.allowsMultipleSelection = NO;
    [wSelf.selectedPhotos removeAllIndexes];
    [wSelf.itemsView reloadData];
  };
  
  self.navigationItem.rightBarButtonItem = actionButton;
  
  if (![self.article.files count]) { // No photo available
	self.navigationItem.rightBarButtonItem.enabled = NO;
  }
	
  [self.itemsView registerClass:[WAEventPhotoViewCell class] forCellWithReuseIdentifier:@"EventPhotoCell"];
	
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) dealloc {

  [self.selectedPhotos removeObserver:self forKeyPath:@"count" context:nil];

}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  
  if ([keyPath isEqualToString:@"count"]) {
    NSInteger newNum = [change[NSKeyValueChangeNewKey] integerValue];
    NSInteger oldNum = [change[NSKeyValueChangeOldKey] integerValue];
    if (!oldNum && newNum) {
      
      for(UIBarButtonItem *barButton in self.toolbarItems) {
        barButton.enabled = YES;
      }
      
    } else if (!newNum && oldNum) {
      
      for(UIBarButtonItem *barButton in self.toolbarItems) {
        barButton.enabled = NO;
      }
      
    }
	
  }
  
}

- (NSArray*) imagesSelected {
  
  NSMutableArray *marray = [NSMutableArray array];
  __weak WAEventViewController_Photo *wSelf = self;
  [self.selectedPhotos enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    WAFile *file = wSelf.article.files[idx];
    if (file.smallThumbnailImage)
      [marray addObject:file.smallThumbnailImage];
  }];
  
  return [NSArray arrayWithArray:marray];
  
}

#pragma mark - CollectionView datasource

- (UICollectionViewCell*) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

	WAEventPhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"EventPhotoCell" forIndexPath:indexPath];
	
	if (self.article.files.count) {
	
		WAFile *file = [self.article.files objectAtIndex:indexPath.row];

		[cell.imageView irUnbind:@"image"];

      	dispatch_async(dispatch_get_main_queue(), ^{
          
			[cell.imageView irBind:@"image" toObject:file keyPath:@"smallThumbnailImage" options:[NSDictionary dictionaryWithObjectsAndKeys: (id)kCFBooleanTrue, kIRBindingsAssignOnMainThreadOption, nil]];

		});

      if ([self.selectedPhotos containsIndex:indexPath.row]) {
        cell.checkMarkView.hidden = NO;
        cell.checkMarkView.image = [UIImage imageNamed:@"IRAQ-Checkmark"];
      } else {
        cell.checkMarkView.image = nil;
        cell.checkMarkView.hidden = YES;
      }
		
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

  if (!self.editing) {
	__weak WAGalleryViewController *galleryVC = nil;
	
	if (!self.article.files.count) {
      //TODO: popup UI to add some photos
      return;
	}
	
	WAFile *file = [self.article.files objectAtIndex:indexPath.row];
	
	galleryVC = [WAGalleryViewController
                 controllerRepresentingArticleAtURI:[[self.article objectID] URIRepresentation]
                 context:[NSDictionary dictionaryWithObjectsAndKeys: [[file objectID] URIRepresentation], kWAGalleryViewControllerContextPreferredFileObjectURI, nil]];
  
    [[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Event" withAction:@"EnterGallery" withLabel:nil withValue:@0];
	
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
    
  } else {
   
    WAEventPhotoViewCell *cell = (WAEventPhotoViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
    
    cell.checkMarkView.hidden = NO;
    cell.checkMarkView.image = [UIImage imageNamed:@"IRAQ-Checkmark"];

    [self.selectedPhotos willChangeValueForKey:@"count"];
    [self.selectedPhotos addIndex:indexPath.row];
    [self.selectedPhotos didChangeValueForKey:@"count"];

  }
	
}

- (void) collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {

  if (self.editing) {
    WAEventPhotoViewCell *cell = (WAEventPhotoViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
    
    cell.checkMarkView.hidden = YES;
    cell.checkMarkView.image = nil;
    
    [self.selectedPhotos willChangeValueForKey:@"count"];
    [self.selectedPhotos removeIndex:indexPath.row];
    [self.selectedPhotos didChangeValueForKey:@"count"];
  }
  
}


@end
