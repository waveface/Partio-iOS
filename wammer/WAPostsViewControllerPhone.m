  //
  //  WAArticlesViewController.m
  //  wammer-iOS
  //
  //  Created by Evadne Wu on 7/20/11.
  //  Copyright 2011 Waveface. All rights reserved.
  //

#import <objc/runtime.h>

#import "WADefines.h"

#import "WADataStore.h"
#import "WAPostsViewControllerPhone.h"
#import "WACompositionViewController.h"
#import "WAPaginationSlider.h"

#import "WARemoteInterface.h"
#import "WARemoteInterface+ScheduledDataRetrieval.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"

#import "IRPaginatedView.h"
#import "IRBarButtonItem.h"
#import "IRTransparentToolbar.h"
#import "IRActionSheetController.h"
#import "IRActionSheet.h"
#import "IRAction.h"
#import "IRAlertView.h"

#import "WAArticleViewController.h"
#import "WAPostViewControllerPhone.h"

#import "WAArticleCommentsViewCell.h"
#import "WAPostViewCellPhone.h"
#import "WAComposeViewControllerPhone.h"

#import "WAGalleryViewController.h"

#import "WAPulldownRefreshView.h"

static NSString * const WAPostsViewControllerPhone_RepresentedObjectURI = @"WAPostsViewControllerPhone_RepresentedObjectURI";

@interface WAPostsViewControllerPhone () <NSFetchedResultsControllerDelegate, WAImageStackViewDelegate, UIActionSheetDelegate>

@property (nonatomic, readwrite, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) NSString *_lastID;
@property (nonatomic, readwrite, retain) IRActionSheetController *settingsActionSheetController;

- (void) refreshData;
- (void) syncLastRead:(NSIndexPath *)indexPath;
- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize FromImage:(UIImage *)sourceImage;
+ (IRRelativeDateFormatter *) relativeDateFormatter;

- (void) beginCompositionSessionWithURL:(NSURL *)anURL;

@end


@implementation WAPostsViewControllerPhone
@synthesize delegate;
@synthesize fetchedResultsController;
@synthesize managedObjectContext;
@synthesize _lastID;
@synthesize settingsActionSheetController;

- (void) dealloc {
	
	[managedObjectContext release];
	[fetchedResultsController release];
  [_lastID release];
	[super dealloc];
  
}


- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if (!self)
		return nil;
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleManagedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
  
  self.title = @"Wammer";
	
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"WASettingsGlyph"] style:UIBarButtonItemStylePlain target:self action:@selector(actionSettings:)] autorelease];
	
	self.navigationItem.rightBarButtonItem  = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(handleCompose:)] autorelease];
  
	self.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
	self.fetchedResultsController = [[[NSFetchedResultsController alloc] initWithFetchRequest:(( ^ {
		
		NSFetchRequest *fetchRequest = [self.managedObjectContext.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRArticles" substitutionVariables:[NSDictionary dictionary]];
		fetchRequest.sortDescriptors = [NSArray arrayWithObjects:
			[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO],
		nil];
		
		return fetchRequest;
		
	})()) managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil] autorelease];
	
	self.fetchedResultsController.delegate = self;
  
  NSError *fetchingError;
	if (![self.fetchedResultsController performFetch:&fetchingError])
		NSLog(@"error fetching: %@", fetchingError);
  
  __block __typeof__(self) nrSelf = self;

  self.settingsActionSheetController = [IRActionSheetController 
                                        actionSheetControllerWithTitle:@"Settings" 
                                        cancelAction:[IRAction actionWithTitle:@"Cancel" block:nil]
                                        destructiveAction:nil 
                                        otherActions:[ NSArray arrayWithObjects:
                                                      [IRAction actionWithTitle:@"Sign Out" 
                                                                          block:^{
                                                                            [[IRAlertView alertViewWithTitle:@"Sign Out" 
                                                                                                     message:@"Really sign out?" 
                                                                                                cancelAction:[IRAction actionWithTitle:@"Cancel" block:nil] 
                                                                                                otherActions:[NSArray arrayWithObjects:
                                                                                                              [IRAction actionWithTitle:@"Sign Out" 
                                                                                                                                  block: ^ { dispatch_async(dispatch_get_main_queue(), ^ {[nrSelf.delegate applicationRootViewControllerDidRequestReauthentication:nrSelf];});}], nil]
                                                                              ] show];
                                                                          }], [IRAction actionWithTitle:@"Change API URL" block:^ { [nrSelf.delegate applicationRootViewControllerDidRequestChangeAPIURL:nrSelf];}],
                                                      nil ]
                                        ];
  self.tableView.backgroundColor = [[UIColor alloc] initWithRed:226.0/255.0 green:230.0/255.0 blue:232/255.0 alpha:1.0];
	return self;
  
}

- (void) handleManagedObjectContextDidSave:(NSNotification *)aNotification {
  
	NSManagedObjectContext *savedContext = (NSManagedObjectContext *)[aNotification object];
	
	if (savedContext == self.managedObjectContext)
		return;
		
	if (![[[aNotification userInfo] objectForKey:NSInsertedObjectsKey] count])
	if (![[[aNotification userInfo] objectForKey:NSUpdatedObjectsKey] count])
	if (![[[aNotification userInfo] objectForKey:NSDeletedObjectsKey] count])
	if (![[[aNotification userInfo] objectForKey:NSRefreshedObjectsKey] count])
	if (![[[aNotification userInfo] objectForKey:NSInvalidatedObjectsKey] count])
	if (![[[aNotification userInfo] objectForKey:NSInvalidatedAllObjectsKey] count])
		return;
	
	[self.tableView performBlockOnInteractionEventsEnd: ^ {
	
		[self.managedObjectContext mergeChangesFromContextDidSaveNotification:aNotification];
		
		/*
		
			Asynchronous file loading in WAFile works this way:
		
			1.	-[WAFile resourceFilePath] is accessed.
			2.	Primitive value for the path is not found, and the primitive value for `resourceURL` is not a file URL.
			3.	That infers the resource URL is a HTTP resource URL.
			4.	The shared remote resources manager is triggered and a download is enqueued.
			5.	On download completion, a disposable managed object context is created, and all managed objects in that context holding the eligible resource URLs are updated.
			6.	The disposed managed object context is saved.  At this moment the notification is sent and this method is invoked.  However,
			7.	The class conforms to <NSFetchedResultsControllerDelegate> and will only reload on -controllerDidChangeContent:.
			8.	The method is not implicitly invoked because the fetched results controller’s fetch request latches on WAArticle
			9.	So, trigger a forced refresh by refreshing all the fetched objects in the fetched results controller’s results
			10.	This seems to work around a Core Data bug where changes on a managed object’s related entity’s attributes do not always trigger a change.
		
		*/
		
		NSArray *allFetchedObjects = [self.fetchedResultsController fetchedObjects];
		
		for (NSManagedObject *aFetchedObject in allFetchedObjects)
			[aFetchedObject.managedObjectContext refreshObject:aFetchedObject mergeChanges:YES];
			
	}];
  
}

- (void) viewDidUnload {
	
	[super viewDidUnload];
  
}

- (void) viewDidLoad {

	[super viewDidLoad];
	
	self.tableView.separatorColor = [UIColor colorWithWhite:.96 alpha:1];
	__block WAPulldownRefreshView *pulldownHeader = [WAPulldownRefreshView viewFromNib];
	__block __typeof__(self) nrSelf = self;
	
	self.tableView.pullDownHeaderView = pulldownHeader;
	self.tableView.onPullDownMove = ^ (CGFloat progress) {
		pulldownHeader.progress = progress;	
	};
	self.tableView.onPullDownEnd = ^ (BOOL didFinish) {
		if (didFinish) {
			pulldownHeader.progress = 0;
			[[WARemoteInterface sharedInterface] performAutomaticRemoteUpdatesNow];
		}
	};
	
}

- (void) viewWillAppear:(BOOL)animated {
  
	[super viewWillAppear:animated];
  [self refreshData];
	
	[[WARemoteInterface sharedInterface] addObserver:self forKeyPath:@"isPerformingAutomaticRemoteUpdates" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCompositionSessionRequest:) name:kWACompositionSessionRequestedNotification object:nil];

}

- (void) viewWillDisappear:(BOOL)animated {
  
	[super viewWillDisappear:animated];
	[[WARemoteInterface sharedInterface] removeObserver:self forKeyPath:@"isPerformingAutomaticRemoteUpdates"];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kWACompositionSessionRequestedNotification object:nil];
 
	NSArray * visibleRows = [self.tableView indexPathsForVisibleRows];
  if ( [visibleRows count] ) {
    [self syncLastRead:[visibleRows objectAtIndex:0]];
  }
	
}

- (void) handleCompositionSessionRequest:(NSNotification *)incomingNotification {

	NSString *content = [[incomingNotification userInfo] objectForKey:@"content"];
	NSURL *contentURL = [[incomingNotification userInfo] objectForKey:@"foundURL"];
	
	[self beginCompositionSessionWithURL:contentURL];
	
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	if (object == [WARemoteInterface sharedInterface])
	if ([[change objectForKey:NSKeyValueChangeNewKey] isEqual:(id)kCFBooleanFalse])
	if ([self isViewLoaded])
		[self.tableView resetPullDown];

}

/* sync last read pointer with remote */
- (void) syncLastRead:(NSIndexPath *)indexPath {
  NSString *currentRowIdentifier = [[self.fetchedResultsController objectAtIndexPath:indexPath] identifier];
  [[WARemoteInterface sharedInterface] setLastReadArticleRemoteIdentifier:currentRowIdentifier  onSuccess:^(NSDictionary *response) {
  } onFailure:^(NSError *error) {
    NSLog(@"SetLastRead failed %@", error);
  }];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
	return [[self.fetchedResultsController sections] count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [(id<NSFetchedResultsSectionInfo>)[[self.fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  WAArticle *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
  
  static NSString *textOnlyCellIdentifier = @"PostCell-TextOnly";
  static NSString *imageCellIdentifier = @"PostCell-Stacked";
  static NSString *webLinkCellIdentifier = @"PostCell-WebLink";
  
  BOOL postHasFiles = (BOOL)!![post.files count];
  BOOL postHasPreview = (BOOL)!![post.previews count];
  
  NSString *identifier = postHasFiles ? imageCellIdentifier : postHasPreview ? webLinkCellIdentifier : textOnlyCellIdentifier;
  WAPostViewCellStyle style = postHasFiles ? WAPostViewCellStyleImageStack : postHasPreview ? WAPostViewCellStyleWebLink : WAPostViewCellStyleDefault;
  WAPostViewCellPhone *cell = (WAPostViewCellPhone *)[tableView dequeueReusableCellWithIdentifier:identifier];
	
  if (!cell) {
		
    cell = [[WAPostViewCellPhone alloc] initWithPostViewCellStyle:style reuseIdentifier:identifier];
    cell.imageStackView.delegate = self;
		cell.commentLabel.userInteractionEnabled = YES;
		
  }
	
  cell.userNicknameLabel.text = [[post.owner.nickname componentsSeparatedByString: @" "] objectAtIndex:0];
  cell.avatarView.image = post.owner.avatar;
  cell.dateLabel.text = [[[[self class] relativeDateFormatter] stringFromDate:post.timestamp] lowercaseString];
	cell.commentLabel.attributedText = [cell.commentLabel attributedStringForString:post.text];
 
	//	cell.commentLabel.attributedText = ((^{
	//	
	//		NSMutableAttributedString *attributedString = [[[cell.commentLabel attributedStringForString:post.text] mutableCopy] autorelease];
	//		
	//		[attributedString beginEditing];
	//		[[NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil] enumerateMatchesInString:post.text options:0 range:(NSRange){ 0, [post.text length] } usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
	//			[attributedString addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
	//				(id)[UIColor colorWithRed:0 green:0 blue:0.5 alpha:1].CGColor, kCTForegroundColorAttributeName,
	//				result.URL, kIRTextLinkAttribute,
	//			nil] range:result.range];		
	//		}];
	//		[attributedString endEditing];
	//		
	//		return attributedString;
	//		
	//	})());
	
  if (postHasPreview) {
	
		WAPreview *anyPreview = (WAPreview *)[[[post.previews allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObjects:
			[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES],
		nil]] lastObject];	
		[cell.previewBadge configureWithPreview:anyPreview];
		
  }
    
  if (postHasFiles) {
    
		objc_setAssociatedObject(cell.imageStackView, &WAPostsViewControllerPhone_RepresentedObjectURI, [[post objectID] URIRepresentation], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  
		NSArray *firstTwoImages = [post.fileOrder irMap: ^ (id inObject, NSUInteger index, BOOL *stop) {
      
      if (index > 0)
        *stop = YES;
      
      WAFile *file = (WAFile *)[post.managedObjectContext irManagedObjectForURI:inObject];
      return [self imageByScalingAndCroppingForSize:CGSizeMake(150, 150) FromImage:file.thumbnailImage];
      
		}];
		
		[cell.imageStackView setImages:firstTwoImages asynchronously:YES withDecodingCompletion:nil];
	
	}
  
  return cell;
  
}

- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize FromImage:(UIImage *)sourceImage
{
  UIImage *newImage = nil;        
  CGSize imageSize = sourceImage.size;
  CGFloat width = imageSize.width;
  CGFloat height = imageSize.height;
  CGFloat targetWidth = targetSize.width;
  CGFloat targetHeight = targetSize.height;
  CGFloat scaleFactor = 0.0;
  CGFloat scaledWidth = targetWidth;
  CGFloat scaledHeight = targetHeight;
  CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
  
  if (CGSizeEqualToSize(imageSize, targetSize) == NO) 
    {
    CGFloat widthFactor = targetWidth / width;
    CGFloat heightFactor = targetHeight / height;
    
    if (widthFactor > heightFactor) 
      scaleFactor = widthFactor; // scale to fit height
    else
      scaleFactor = heightFactor; // scale to fit width
    scaledWidth  = width * scaleFactor;
    scaledHeight = height * scaleFactor;
    
    // center the image
    if (widthFactor > heightFactor)
      {
      thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5; 
      }
    else 
      if (widthFactor < heightFactor)
        {
        thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }       
  
  UIGraphicsBeginImageContext(targetSize); // this will crop
  
  CGRect thumbnailRect = CGRectZero;
  thumbnailRect.origin = thumbnailPoint;
  thumbnailRect.size.width  = scaledWidth;
  thumbnailRect.size.height = scaledHeight;
  
  [sourceImage drawInRect:thumbnailRect];
  
  newImage = UIGraphicsGetImageFromCurrentImageContext();
  if(newImage == nil) 
    NSLog(@"could not scale image");
  
  //pop the context to get back to the default
  UIGraphicsEndImageContext();
  return newImage;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  WAArticle *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
	UIFont *baseFont = [UIFont fontWithName:@"Helvetica" size:14.0];
  CGFloat height = [post.text sizeWithFont:baseFont constrainedToSize:(CGSize){
		CGRectGetWidth(tableView.frame) - 80,
		9999.0
	} lineBreakMode:UILineBreakModeWordWrap].height;

	return height + ([post.files count] ? 222 : [post.previews count] ? 164 : 64);
	
}

#pragma mark -- Actions

- (IBAction)actionSettings:(id)sender
{
  [self.settingsActionSheetController.managedActionSheet showFromBarButtonItem:sender animated:YES];

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)newOrientation {
  
  return newOrientation == UIInterfaceOrientationPortrait;	
}

- (void) refreshData {

	[[WARemoteInterface sharedInterface] rescheduleAutomaticRemoteUpdates];

}

- (void) controllerWillChangeContent:(NSFetchedResultsController *)controller {

	if (![self isViewLoaded])
		return;
	
	[self.tableView beginUpdates];
	
}

- (void) controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {

	switch (type) {
		case NSFetchedResultsChangeInsert: {
			[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
			break;
		}
		case NSFetchedResultsChangeDelete: {
			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
			break;
		}
		case NSFetchedResultsChangeMove: {
			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
			[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
			break;
		}
		case NSFetchedResultsChangeUpdate: {
			[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
			break;
		}
	}

}

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller {
		
	if (![self isViewLoaded])
		return;

	[self.tableView endUpdates];
		
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [self syncLastRead:indexPath];
  WAArticle *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
  WAPostViewControllerPhone *controller = [WAPostViewControllerPhone controllerWithPost:[[post objectID] URIRepresentation]];
  
  [self.navigationController pushViewController:controller animated:YES];
}

- (void) beginCompositionSessionWithURL:(NSURL *)anURL {

  [[WARemoteInterface sharedInterface] beginPostponingDataRetrievalTimerFiring];
  WAComposeViewControllerPhone *composeViewController = [WAComposeViewControllerPhone controllerWithWebPost:anURL completion:^(NSURL *aPostURLOrNil) {
    
		[[WADataStore defaultStore] uploadArticle:aPostURLOrNil onSuccess: ^ {
			//	We’ll get a save, do nothing
			//	dispatch_async(dispatch_get_main_queue(), ^ {
			//		[self refreshData];
			//	});
		} onFailure:nil];
    [[WARemoteInterface sharedInterface] endPostponingDataRetrievalTimerFiring];
	}];
  
  UINavigationController *navigationController = [[[UINavigationController alloc]initWithRootViewController:composeViewController]autorelease];
  navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  [self presentModalViewController:navigationController animated:YES];
}

- (void) handleCompose:(UIBarButtonItem *)sender {
  
  [[WARemoteInterface sharedInterface] beginPostponingDataRetrievalTimerFiring];
  WAComposeViewControllerPhone *composeViewController = [WAComposeViewControllerPhone controllerWithPost:nil completion:^(NSURL *aPostURLOrNil) {
    
		[[WADataStore defaultStore] uploadArticle:aPostURLOrNil onSuccess: ^ {
			//	We’ll get a save, do nothing
			//	dispatch_async(dispatch_get_main_queue(), ^ {
			//		[self refreshData];
			//	});
		} onFailure:nil];
    [[WARemoteInterface sharedInterface] endPostponingDataRetrievalTimerFiring];
	}];
  
  UINavigationController *navigationController = [[[UINavigationController alloc]initWithRootViewController:composeViewController]autorelease];
  navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  [self presentModalViewController:navigationController animated:YES];
}

+ (IRRelativeDateFormatter *) relativeDateFormatter {
  
	static IRRelativeDateFormatter *formatter = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		formatter = [[IRRelativeDateFormatter alloc] init];
		formatter.approximationMaxTokenCount = 1;
    
	});
  
	return formatter;
  
}

- (void) imageStackView:(WAImageStackView *)aStackView didRecognizePinchZoomGestureWithRepresentedImage:(UIImage *)representedImage contentRect:(CGRect)aRect transform:(CATransform3D)layerTransform {
  
	NSURL *representedObjectURI = objc_getAssociatedObject(aStackView, &WAPostsViewControllerPhone_RepresentedObjectURI);
	
	__block __typeof__(self) nrSelf = self;
	__block WAGalleryViewController *galleryViewController = nil;
	galleryViewController = [WAGalleryViewController controllerRepresentingArticleAtURI:representedObjectURI];
	galleryViewController.hidesBottomBarWhenPushed = YES;
	galleryViewController.onDismiss = ^ {
    
		CATransition *transition = [CATransition animation];
		transition.duration = 0.3f;
		transition.type = kCATransitionPush;
		transition.subtype = ((^ {
			switch (self.interfaceOrientation) {
				case UIInterfaceOrientationPortrait:
					return kCATransitionFromLeft;
				case UIInterfaceOrientationPortraitUpsideDown:
					return kCATransitionFromRight;
				case UIInterfaceOrientationLandscapeLeft:
					return kCATransitionFromTop;
				case UIInterfaceOrientationLandscapeRight:
					return kCATransitionFromBottom;
			}
		})());
		transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
		transition.fillMode = kCAFillModeForwards;
		transition.removedOnCompletion = YES;
    
		[galleryViewController.navigationController setNavigationBarHidden:NO animated:NO];
		[galleryViewController.navigationController popViewControllerAnimated:NO];
		
		[nrSelf.navigationController.view.layer addAnimation:transition forKey:@"transition"];
	};
	
	CATransition *transition = [CATransition animation];
	transition.duration = 0.3f;
	transition.type = kCATransitionPush;
	transition.subtype = ((^ {
		switch (self.interfaceOrientation) {
			case UIInterfaceOrientationPortrait:
				return kCATransitionFromRight;
			case UIInterfaceOrientationPortraitUpsideDown:
				return kCATransitionFromLeft;
			case UIInterfaceOrientationLandscapeLeft:
				return kCATransitionFromBottom;
			case UIInterfaceOrientationLandscapeRight:
				return kCATransitionFromTop;
		}
	})());
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	transition.fillMode = kCAFillModeForwards;
	transition.removedOnCompletion = YES;
	
	[self.navigationController setNavigationBarHidden:YES animated:NO];
	[self.navigationController pushViewController:galleryViewController animated:NO];
	
	[self.navigationController.view.layer addAnimation:transition forKey:@"transition"];
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
  
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, transition.duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];
	});
	
}
@end
