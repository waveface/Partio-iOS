//
//  WAEventViewController_Photo.m
//  wammer
//
//  Created by Shen Steven on 11/5/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAEventViewController_Photo.h"
#import "WAEventPhotoViewCell.h"
#import "WAEventPhotoAddingCell.h"

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

@interface WAEventViewController_Photo () 

@property (nonatomic, strong) UICollectionView *itemsView;
@property (nonatomic, strong) NSMutableIndexSet *selectedPhotos;
@property (nonatomic, strong) IRBarButtonItem *actionButton;
@property (nonatomic, strong) UIBarButtonItem *cancelButton;
@property (nonatomic, strong) UIBarButtonItem *backButton;
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
                               options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                               context:nil];
      
    }
    return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  __weak WAEventViewController_Photo *wSelf = self;
  
  self.backButton = self.navigationItem.leftBarButtonItem;

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
  [shareButton setTitleTextAttributes:@{UITextAttributeTextColor: [UIColor whiteColor]} forState:UIControlStateNormal];
  [shareButton setTintColor:[UIColor blackColor]];

  IRBarButtonItem *collectionButton = WABarButtonItem(nil, NSLocalizedString(@"ACTION_ADD_COLLECTION", @"Adding to collection action in the event view"), ^{
    
    UIActionSheet *actions = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"ACTIONSHEET_TITLE_ADD_COLLECTION", @"The title of action sheets to add selected photos into collection")];
    
    [actions addButtonWithTitle:NSLocalizedString(@"ACTIONSHEET_ACTION_NEW_COLLECTION", @"The action title to new a collection")
                        handler:^{
                          UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ALERT_TITLE_NEW_COLLECTION", @"The title of an alert view for user to input a collection name") message:@""];
                          __weak UIAlertView *wAlert = alert;
                          alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                          [alert setCancelButtonWithTitle:NSLocalizedString(@"ACTION_CANCEL", @"Cancel adding selected photos into collection") handler:nil];
                          [alert addButtonWithTitle:NSLocalizedString(@"ACTION_CREATE_COLLECTION", @"The action to create a new collection") handler:^{
                            
                            [wSelf.managedObjectContext performBlockAndWait:^{
                              
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
                            
                            [wSelf showDoneBezel];
                          }];
                          
                          [alert show];
                          
                        }];
    
    [actions addButtonWithTitle:NSLocalizedString(@"ACTIONSHEET_ACTION_ADD_EXISTING", @"The action title to add selected photos in a collection")
                        handler:^{
      
                          __block WACollectionPickerViewController *picker = [WACollectionPickerViewController pickerWithHandler:^(NSManagedObjectID *selectedCollection) {
                            
                            [wSelf.managedObjectContext performBlockAndWait:^{
        
                              WACollection *collection = (WACollection*)[wSelf.managedObjectContext objectWithID:selectedCollection];
                              
                              [collection addObjects:[wSelf.article.files objectsAtIndexes:wSelf.selectedPhotos]];
        
                              NSError *error = nil;
                              
                              [wSelf.managedObjectContext save:&error];
                              if (error) {
                                NSLog(@"Fail to save collection for error: %@", error);
                                [picker dismissViewControllerAnimated:YES completion:nil];
                                picker = nil;
                                
                                [wSelf showErrorBezelWithReason:error.description];
                              } else {
                                
                                [picker dismissViewControllerAnimated:YES completion:nil];
                                picker = nil;
                                
                                [wSelf showDoneBezel];
                              }
                              
                            }];
                            
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
  [collectionButton setTitleTextAttributes:@{UITextAttributeTextColor: [UIColor whiteColor]} forState:UIControlStateNormal];
  [collectionButton setTintColor:[UIColor blackColor]];
  
  IRBarButtonItem *deleteButton = WABarButtonItem(nil, NSLocalizedString(@"ACTION_PHOTOS_DELETE", @"Deleting action in the event view"), ^{

    UIActionSheet *actions = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"ACTIONSHEET_TITLE_DELETE_PHOTOS", @"The title of action sheets to delete selected photos")];
    [actions addButtonWithTitle:NSLocalizedString(@"ACTIONSHEET_ACTION_DEL_INEVENT", @"Remove selected photos from event")
                        handler:^{

                          NSMutableArray *identifiers = [NSMutableArray array];
                          [wSelf.selectedPhotos enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                            [identifiers addObject:[[wSelf.article.files objectAtIndex:idx] identifier]];
                          }];
                          
                          WAOverlayBezel *busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
                          dispatch_async(dispatch_get_main_queue(), ^{
                            [busyBezel showWithAnimation:WAOverlayBezelAnimationFade];
                          });
      
                          [[WARemoteInterface sharedInterface] removeAttachmentsFromPost:wSelf.article.identifier
                                                                             attachments:identifiers
                                                                               onSuccess:^(NSDictionary *postRep) {

                                                                                 [wSelf.managedObjectContext performBlock:^{
                                                                                   NSArray *remainingFiles = [[wSelf.article.files array] filteredArrayUsingPredicate:(NSPredicate *)[NSPredicate predicateWithFormat:@"NOT (identifier IN %@)", identifiers]];

                                                                                   wSelf.article.files = [NSOrderedSet orderedSetWithArray:remainingFiles];
                                                                                   NSError *error = nil;
                                                                                   
                                                                                   if (![wSelf.managedObjectContext save:&error]) {
                                                                                     NSLog(@"Fail to remove files %@ from article %@ for %@", identifiers, wSelf.article, error);
                                                                                   }
                                                                                 }];
                                                                                 
                                                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                                                   [busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
                                                                                   [wSelf showDoneBezel];
                                                                                   [wSelf.selectedPhotos removeAllIndexes];
                                                                                   [wSelf.itemsView reloadData];

                                                                                 });

                                                                               }
                                                                               onFailure:^(NSError *error) {
                                                                                 
                                                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                                                   [busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
                                                                                   
                                                                                   [wSelf showErrorBezelWithReason:error.description];
                                                                                   
                                                                                 });

                                                                               }];
                        }];
    
    [actions addButtonWithTitle:NSLocalizedString(@"ACTIONSHEET_ACTION_DELETE", @"Hide the selected photos")
                        handler:^{
      
                          NSMutableArray *identifiers = [NSMutableArray array];
                          [wSelf.selectedPhotos enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                            [identifiers addObject:[[wSelf.article.files objectAtIndex:idx] identifier]];
                          }];
      
                          WAOverlayBezel *busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
                          dispatch_async(dispatch_get_main_queue(), ^{
                            [busyBezel showWithAnimation:WAOverlayBezelAnimationFade];
                          });
      
                          [[WARemoteInterface sharedInterface] deleteAttachments:identifiers
                                                                     onSuccess:^(NSArray *successIDs, NSArray *failureIDs) {
                                                                       
                                                                       NSManagedObjectContext *moc = [[WADataStore defaultStore] autoUpdatingMOC];
                                                                       NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
                                                                       fetch.entity = [NSEntityDescription entityForName:@"WAFile" inManagedObjectContext:moc];
                                                                       fetch.predicate = [NSPredicate predicateWithFormat:@"identifier IN %@", identifiers];
                                                                       NSError *error = nil;
                                                                       NSArray *hiddingFiles = [moc executeFetchRequest:fetch error:&error];
                                                                       if (error) {
                                                                         NSLog(@"Unable to fetch files %@ for %@", identifiers, error);
                                                                       } else {
                                                                         for (WAFile *file in hiddingFiles) {
                                                                           [moc deleteObject:file];
                                                                         }
                                                                         if(![moc save:&error]) {
                                                                           NSLog(@"Fail to delete files for: %@", error);
                                                                         }
                                                                       }
                                                                    
                                                                       
                                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                                         [wSelf.itemsView reloadData];
                                                                         [busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
                                                                         [wSelf showDoneBezel];
                                                                         [wSelf.selectedPhotos removeAllIndexes];
                                                                         [wSelf.itemsView reloadData];
                                                                       });
                                                                       
                                                                     } onFailure:^(NSError *error) {
                                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                                         [busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
                                                                         [wSelf showErrorBezelWithReason:error.description];

                                                                       });
                                                                     }];
                          
                        }];
    
    [actions setCancelButtonWithTitle:NSLocalizedString(@"ACTION_CANCEL", @"Cancel the photo deletion") handler:nil];
    
    [actions showFromToolbar:wSelf.navigationController.toolbar];

  });
  deleteButton.tintColor = [UIColor redColor];
  [deleteButton setTitleTextAttributes:@{UITextAttributeTextColor: [UIColor whiteColor]} forState:UIControlStateNormal];

  UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  self.toolbarItems = @[space, shareButton, space, collectionButton, space, deleteButton, space];
  
  for(UIBarButtonItem *barButton in self.toolbarItems) {
    barButton.enabled = NO;
  }
  
  self.navigationController.toolbar.barStyle = UIBarStyleBlack;
  self.navigationController.toolbar.translucent = YES;
  self.navigationController.toolbar.tintColor = [UIColor clearColor];
  self.navigationController.toolbarHidden = YES;
  
  morePhotoBtnImages = [NSMutableArray arrayWithArray:@[@"add-DB", @"add-G", @"add-LB", @"add-O", @"add-Red"]];

	
  self.cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel handler:^(id sender) {
    [wSelf leaveEditingMode];
    
  }];
  
  self.actionButton = WABarButtonItem([UIImage imageNamed:@"action"], nil, ^{
    [wSelf enterEditingMode];
  });
    
  self.navigationItem.rightBarButtonItem = self.actionButton;
  
  if (![self.article.files count]) { // No photo available
	self.navigationItem.rightBarButtonItem.enabled = NO;
  }
	
  [self.itemsView registerClass:[WAEventPhotoViewCell class] forCellWithReuseIdentifier:@"EventPhotoCell"];
  [self.itemsView registerClass:[WAEventPhotoAddingCell class] forCellWithReuseIdentifier:@"EventPhotoAddingCell"];
	
}

- (void) showDoneBezel {
  __weak id wSelf = self;

  if (![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [wSelf showDoneBezel];
    });
  }
  
  WAOverlayBezel *doneBezel = [WAOverlayBezel bezelWithStyle:WACheckmarkBezelStyle];
  [doneBezel showWithAnimation:WAOverlayBezelAnimationNone];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [doneBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
  });
  
}

- (void) showErrorBezelWithReason:(NSString*)reason {
  __weak id wSelf = self;
  if (![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [wSelf showErrorBezelWithReason:reason];
    });
  }

  WAOverlayBezel *errorBezel = [[WAOverlayBezel alloc] initWithStyle:WAErrorBezelStyle];
  [errorBezel setCaption:reason];
  [errorBezel show];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^ {
    [errorBezel dismiss];
  });

}

- (void) enterEditingMode {
  
  [self.navigationController setToolbarHidden:NO animated:YES];
  CGRect frame = self.itemsView.frame;
  frame.size.height -= self.navigationController.toolbar.frame.size.height;
  self.itemsView.frame = frame;
  self.navigationItem.rightBarButtonItem = self.cancelButton;
  self.navigationItem.leftBarButtonItem = nil;
  self.editing = YES;
  self.itemsView.allowsMultipleSelection = YES;
  [self.itemsView reloadData];

}

- (void) leaveEditingMode {

  self.navigationItem.rightBarButtonItem = self.actionButton;
  self.navigationItem.leftBarButtonItem = self.backButton;
  self.editing = NO;
  self.itemsView.allowsMultipleSelection = NO;
  [self.selectedPhotos removeAllIndexes];
  [self.itemsView reloadData];
  CGRect frame = self.itemsView.frame;
  frame.size.height += self.navigationController.toolbar.frame.size.height;
  self.itemsView.frame = frame;
  [self.navigationController setToolbarHidden:YES animated:YES];

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
  
	if (self.article.files.count) {
      WAEventPhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"EventPhotoCell" forIndexPath:indexPath];
      cell.editing = self.editing;

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
		
      return cell;
	} else {
		
      WAEventPhotoAddingCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"EventPhotoAddingCell" forIndexPath:indexPath];

      int index = arc4random() % morePhotoBtnImages.count;

      cell.imageView.image = [UIImage imageNamed:morePhotoBtnImages[index]];
      [morePhotoBtnImages removeObjectAtIndex:index];
      
      if (!morePhotoBtnImages.count) {
        morePhotoBtnImages = [@[@"add-DB", @"add-G", @"add-LB", @"add-O", @"add-Red"] mutableCopy];
      }
		
      return cell;
	}

	return nil;
	
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
   
    [self.selectedPhotos willChangeValueForKey:@"count"];
    [self.selectedPhotos addIndex:indexPath.row];
    [self.selectedPhotos didChangeValueForKey:@"count"];

  }
	
}

- (void) collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {

  if (self.editing) {
    
    [self.selectedPhotos willChangeValueForKey:@"count"];
    [self.selectedPhotos removeIndex:indexPath.row];
    [self.selectedPhotos didChangeValueForKey:@"count"];
  }
  
}


@end
