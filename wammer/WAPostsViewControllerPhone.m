  //
  //  WAArticlesViewController.m
  //  wammer-iOS
  //
  //  Created by Evadne Wu on 7/20/11.
  //  Copyright 2011 Waveface. All rights reserved.
  //

#import <objc/runtime.h>

#import "WADataStore.h"
#import "WAPostsViewControllerPhone.h"
#import "WACompositionViewController.h"
#import "WAPaginationSlider.h"

#import "WARemoteInterface.h"

#import "IRPaginatedView.h"
#import "IRBarButtonItem.h"
#import "IRTransparentToolbar.h"
#import "IRActionSheetController.h"
#import "IRActionSheet.h"
#import "IRAlertView.h"

#import "WAArticleViewController.h"
#import "WAPostViewControllerPhone.h"
#import "WAUserSelectionViewController.h"

#import "WAArticleCommentsViewCell.h"
#import "WAPostViewCellPhone.h"
#import "WAComposeViewControllerPhone.h"

#import "WAGalleryViewController.h"


static NSString * const WAPostsViewControllerPhone_RepresentedObjectURI = @"WAPostsViewControllerPhone_RepresentedObjectURI";

@interface WAPostsViewControllerPhone () <NSFetchedResultsControllerDelegate, WAImageStackViewDelegate>

@property (nonatomic, readwrite, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) NSIndexPath *__currentRow;
@property (nonatomic, readwrite, retain) NSString *__lastID;

- (void) refreshData;

+ (IRRelativeDateFormatter *) relativeDateFormatter;

@end


@implementation WAPostsViewControllerPhone
@synthesize delegate;
@synthesize fetchedResultsController;
@synthesize managedObjectContext;
@synthesize __currentRow, __lastID;

- (void) dealloc {
	
	[managedObjectContext release];
	[fetchedResultsController release];
  [__currentRow release];
	[super dealloc];
  
}


- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if (!self)
		return nil;
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleManagedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
  
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Sign Out" style:UIBarButtonItemStyleBordered target:self action:@selector(handleAccount:)] autorelease];
	
  self.title = @"Wammer";
  self.navigationItem.rightBarButtonItem  = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(handleCompose:)]autorelease];
  
	self.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
	self.fetchedResultsController = [[[NSFetchedResultsController alloc] initWithFetchRequest:((^ {
    
		NSFetchRequest *returnedRequest = [[[NSFetchRequest alloc] init] autorelease];
		returnedRequest.entity = [NSEntityDescription entityForName:@"WAArticle" inManagedObjectContext:self.managedObjectContext];
		returnedRequest.predicate = [NSPredicate predicateWithFormat:@"(self != nil) AND (draft == NO)"];
		returnedRequest.sortDescriptors = [NSArray arrayWithObjects:
                                       [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO],
                                       nil];
    return returnedRequest;
    
	})()) managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil] autorelease];
	
	self.fetchedResultsController.delegate = self;
  
  
  NSError *error;
	[self.fetchedResultsController performFetch:&error];
  
	return self;
  
}

- (void) handleManagedObjectContextDidSave:(NSNotification *)aNotification {
  
	NSManagedObjectContext *savedContext = (NSManagedObjectContext *)[aNotification object];
	
	if (savedContext == self.managedObjectContext)
		return;
	
	dispatch_async(dispatch_get_main_queue(), ^ {
	
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
			
	});
  
}

- (void) viewDidUnload {
	
	[super viewDidUnload];
  
}

- (void) viewDidLoad {

	[super viewDidLoad];
	
	self.tableView.separatorColor = [UIColor colorWithWhite:.96 alpha:1];
  
}

- (void) viewWillAppear:(BOOL)animated {
  
	[super viewWillAppear:animated];
	
  [self.fetchedResultsController performFetch:nil];
  [self refreshData];
  
  [[WARemoteInterface sharedInterface] retrieveLastReadArticleRemoteIdentifierOnSuccess:^(NSString *last, NSDate *modDate) {
    
    NSLog(@"For the current user, the last read article # is %@ at %@", self.__lastID, modDate);
    
    if([self __lastID]){
      NSArray *allObjects = [self.fetchedResultsController fetchedObjects];
      
      for( WAArticle *post in allObjects ){
        if ([post.identifier isEqualToString:self.__lastID]) {
          NSIndexPath *lastReadRow = [self.fetchedResultsController indexPathForObject:post];
          [self.tableView selectRowAtIndexPath:lastReadRow animated:YES scrollPosition:UITableViewScrollPositionMiddle];
          break;
        }
      }
      
      self.__lastID = nil;
      self.__currentRow = nil;
    }
		
	} onFailure: ^ (NSError *error) {
    
		NSLog(@"Retrieve last read articile: %@", error);
		
	}];
}

- (void) viewWillDisappear:(BOOL)animated {
  
	[super viewWillDisappear:animated];
  self.__currentRow = [[self.tableView indexPathsForVisibleRows]objectAtIndex:0 ];
  NSString *currentRowIdentifier = [[self.fetchedResultsController objectAtIndexPath:self.__currentRow] identifier];
  [[WARemoteInterface sharedInterface] setLastReadArticleRemoteIdentifier:currentRowIdentifier  onSuccess:^(NSDictionary *response) {
    NSLog(@"SetLastRead: %@", response);
  } onFailure:^(NSError *error) {
    NSLog(@"SetLastRead failed %@", error);
  }];
	
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
  if (!self.fetchedResultsController.fetchedObjects) {
    return 0;
  }
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if(!self.fetchedResultsController.fetchedObjects)
    return 0;
  return [[self.fetchedResultsController.sections objectAtIndex:section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  
  WAArticle *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
  NSParameterAssert(post);
  
  static NSString *textOnlyCellIdentifier = @"PostCell-TextOnly";
  static NSString *imageCellIdentifier = @"PostCell-Stacked";
  static NSString *webLinkCellIdentifier = @"PostCell-WebLink";
  
  BOOL postHasFiles = (BOOL)!![post.files count];
  BOOL postHasPreview = (BOOL)!![post.previews count];
  
  NSString *identifier = nil;
  WAPostViewCellStyle style = 0;
  if (postHasFiles) {
    identifier = imageCellIdentifier;
    style = WAPostViewCellStyleImageStack;
  } else if (postHasPreview) {
    identifier = webLinkCellIdentifier;
    style = WAPostViewCellStyleWebLink;
  } else {
    identifier = textOnlyCellIdentifier;
    style = WAPostViewCellStyleDefault;
  }
  
  WAPostViewCellPhone *cell = (WAPostViewCellPhone *)[tableView dequeueReusableCellWithIdentifier:identifier];
  if (!cell) {
    cell = [[WAPostViewCellPhone alloc] initWithPostViewCellStyle:style reuseIdentifier:identifier];
    cell.imageStackView.delegate = self;
  }
	
  if (post.identifier == self.__lastID) {
    self.__currentRow = indexPath;
  }
  // Common components
	cell.userNicknameLabel.text = post.owner.nickname;
  cell.avatarView.image = post.owner.avatar;
  cell.dateLabel.text = [[[[self class] relativeDateFormatter] stringFromDate:post.timestamp] lowercaseString];
 
	NSMutableAttributedString *attributedString = [[[cell.commentLabel attributedStringForString:post.text] mutableCopy] autorelease];
	
	[attributedString beginEditing];
	
	[[NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil] enumerateMatchesInString:post.text options:0 range:(NSRange){ 0, [post.text length] } usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
	
		[attributedString addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
			(id)[UIColor colorWithRed:0 green:0 blue:0.5 alpha:1].CGColor, kCTForegroundColorAttributeName,
			result.URL, kIRTextLinkAttribute,
		nil] range:result.range];
		
	}];
	
	[attributedString endEditing];
	
	cell.commentLabel.attributedText = attributedString;
	cell.commentLabel.userInteractionEnabled = YES;
  
	
  // For web link
  if (postHasPreview) {
	
		WAPreview *anyPreview = (WAPreview *)[[[post.previews allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObjects:
			[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES],
		nil]] lastObject];	
		[cell.previewBadge configureWithPreview:anyPreview];
		
  }
    
  if (postHasFiles)
    objc_setAssociatedObject(cell.imageStackView, &WAPostsViewControllerPhone_RepresentedObjectURI, [[post objectID] URIRepresentation], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  
  NSArray *allFilePaths = [post.fileOrder irMap: ^ (id inObject, int index, BOOL *stop) {
    
		return ((WAFile *)[[post.files objectsPassingTest: ^ (WAFile *aFile, BOOL *stop) {		
			return [[[aFile objectID] URIRepresentation] isEqual:inObject];
		}] anyObject]).resourceFilePath;
    
	}];
	
	
	NSArray *allImages = nil;
	
	if ([allFilePaths count] == [post.files count]) {
    
		allImages = [allFilePaths irMap: ^ (NSString *aPath, int index, BOOL *stop) {
			
			return [UIImage imageWithContentsOfFile:aPath];
			
		}];
    
	} else {
	
    allImages = nil;
		
  }
	
	[cell.imageStackView setImages:allImages asynchronously:YES withDecodingCompletion:nil];
  
  return cell;
  
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  WAArticle *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
	UIFont *baseFont = [UIFont fontWithName:@"Helvetica" size:14.0];
  CGFloat height = [post.text sizeWithFont:baseFont constrainedToSize:(CGSize){
		CGRectGetWidth(tableView.frame) - 80,
		9999.0
	} lineBreakMode:UILineBreakModeWordWrap].height;
	return 64 + height + ([post.files count] ? 158 : [post.previews count] ? 96 : 0);
	
}

- (void) handleAccount:(UIBarButtonItem *)sender {

	__block __typeof__(self) nrSelf = self;
  
	[[IRAlertView alertViewWithTitle:@"Sign Out" message:@"Really sign out?" cancelAction:[IRAction actionWithTitle:@"Cancel" block:nil] otherActions:[NSArray arrayWithObjects:
		
		[IRAction actionWithTitle:@"Sign Out" block: ^ {
		
			dispatch_async(dispatch_get_main_queue(), ^ {
			
				[nrSelf.delegate applicationRootViewControllerDidRequestReauthentication:nrSelf];
					
			});

		}],
	
	nil]] show];
		
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)newOrientation {
  
	if ([[UIApplication sharedApplication] isIgnoringInteractionEvents])
		return (self.interfaceOrientation == newOrientation);
  
	return YES;
	
}

- (void) refreshData {
  
	[[WADataStore defaultStore] updateUsersOnSuccess:nil onFailure:nil];
	[[WADataStore defaultStore] updateArticlesOnSuccess:nil onFailure:nil];
  
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
  WAArticle *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
  WAPostViewControllerPhone *controller = [WAPostViewControllerPhone controllerWithPost:[[post objectID] URIRepresentation]];
  
  [self.navigationController pushViewController:controller animated:YES];
}

- (void) handleCompose:(UIBarButtonItem *)sender
{
  
  WAComposeViewControllerPhone *composeViewController = [WAComposeViewControllerPhone controllerWithPost:nil completion:^(NSURL *aPostURLOrNil) {
    
		[[WADataStore defaultStore] uploadArticle:aPostURLOrNil onSuccess: ^ {
      static dispatch_once_t onceToken;
      dispatch_once(&onceToken, ^{
        [self refreshData];
      });
		} onFailure:nil];
    
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
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
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
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:NO];
	});
	
}

@end
