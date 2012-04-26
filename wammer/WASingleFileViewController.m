//
//  WASingleFileViewController.m
//  wammer
//
//  Created by Evadne Wu on 12/5/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WASingleFileViewController.h"
#import "WAFile.h"
#import "WADataStore.h"

#import "IRRemoteResourceDownloadOperation.h"

#import "WAFile.h"
#import "WAFile+QuickLook.h"


@interface WASingleFileViewController ()

@property (nonatomic, readwrite, retain) UIView *overlayView;

@property (nonatomic, readwrite, retain) NSURL *fileURI;
@property (nonatomic, readwrite, retain) WAFile *file;
@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, readwrite, retain) id downloadProgressListener;

- (void) updateInterfaceWithFilePath:(NSString *)newPath;
- (void) updateInterfaceWithProgress:(float_t)progress;

@end


@implementation WASingleFileViewController
@synthesize overlayView;
@synthesize progressView;
@synthesize fileLoadingLabel;
@synthesize fileLoadingProgressLabel;
@synthesize fileURI, file, managedObjectContext;
@synthesize onFinishLoad;
@synthesize downloadProgressListener;

+ (id) controllerForFile:(NSURL *)aFileURI {

  WASingleFileViewController *returnedController = [[self alloc] init];
  returnedController.fileURI = aFileURI;
  
  return returnedController;

}

- (id) init {

  self = [super init];
  if (!self)
    return nil;
  
  self.dataSource = self;
  self.delegate = self;
  
  return self;

}

- (WAFile *) file {

  if (file)
    return file;
  
  file = (WAFile *)[self.managedObjectContext irManagedObjectForURI:self.fileURI];
  
  return file;

}

- (NSManagedObjectContext *) managedObjectContext {

  if (managedObjectContext)
    return managedObjectContext;
  
  managedObjectContext = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
  return managedObjectContext;

}

- (void) dealloc {

  [[NSNotificationCenter defaultCenter] removeObserver:downloadProgressListener];

}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (!self)
    return nil;
  
  return self;
  
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  
  return YES;
  
}

- (void) viewDidLoad {

	[super viewDidLoad];
  
  UIView *oldView = self.view;
  UINib *ownNib = [UINib nibWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]];
  [ownNib instantiateWithOwner:self options:nil];
 
	self.overlayView = self.view;
  self.overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
  
  self.view = oldView;
  [oldView addSubview:self.overlayView];
  
  self.overlayView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.85f];
  self.overlayView.opaque = NO;

  self.progressView.progress = 1;
  
	self.fileLoadingLabel.text = NSLocalizedString(@"STATE_LOADING_SINGLE_DOCUMENT", nil);
  self.fileLoadingProgressLabel.text = [self.file.remoteFileSize stringValue];
  
  [self.file addObserver:self forKeyPath:@"resourceFilePath" options:NSKeyValueObservingOptionNew context:nil];
  
  NSURL *ownResourceURL = [NSURL URLWithString:self.file.resourceURL];
  
  self.downloadProgressListener = [[NSNotificationCenter defaultCenter] addObserverForName:kIRRemoteResourceDownloadOperationDidReceiveDataNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
  
    IRRemoteResourceDownloadOperation *downloadOperation = note.object;
    NSURL *downloadedURL = [note.userInfo objectForKey:kIRRemoteResourceDownloadOperationURL];
    
    if (![[downloadedURL absoluteString] isEqual:[ownResourceURL absoluteString]])
      return;
    
    [self updateInterfaceWithProgress:downloadOperation.progress];
    
  }];
  
  [self updateInterfaceWithFilePath:self.file.resourceFilePath];
  
}

- (void) viewDidUnload {

  self.overlayView = nil;
  
  self.file = nil;
  self.managedObjectContext = nil;
  
  [[NSNotificationCenter defaultCenter] removeObserver:self.downloadProgressListener];
  self.downloadProgressListener = nil;

  self.progressView = nil;
  self.fileLoadingLabel = nil;
  self.fileLoadingProgressLabel = nil;

	[super viewDidUnload];
	
}

- (void) viewWillAppear:(BOOL)animated {

  [super viewWillAppear:animated];
  self.overlayView.frame = self.overlayView.superview.bounds;
  [self.overlayView.superview bringSubviewToFront:self.overlayView];

}

- (void) viewDidAppear:(BOOL)animated {

  [super viewDidAppear:animated];
  self.overlayView.frame = self.overlayView.superview.bounds;
  [self.overlayView.superview bringSubviewToFront:self.overlayView];

}

- (void) viewDidDisappear:(BOOL)animated {

  //  http://www.openradar.me/10431759
  //  We have the eat the exception any way.  It was assumed that the exception was shoddily eaten in Apple’s code too.
  
  @try {

    [super viewDidDisappear:animated];

  } @catch (NSException *exception) {
  
    NSLog(@"Exception: %@", exception);
    
  }

}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

  if (object == file)
  if ([keyPath isEqualToString:@"resourceFilePath"]) {
  
    NSString * newPath = [change objectForKey:NSKeyValueChangeNewKey];
    if (![newPath isKindOfClass:[NSString class]])
      newPath = nil;
    
    [self updateInterfaceWithFilePath:newPath];
    
  }

}

- (void) updateInterfaceWithFilePath:(NSString *)newPath {

  if (newPath) {

    [self updateInterfaceWithProgress:1];
    
    if (self.onFinishLoad)
      self.onFinishLoad(self);

  } else {

    [self updateInterfaceWithProgress:0];

  }

}

- (void) updateInterfaceWithProgress:(float_t)progress {

  NSParameterAssert(progress >= 0);
  NSParameterAssert(progress <= 1);
  
  if (progress == 1) {
  
    if ([self.dataSource numberOfPreviewItemsInPreviewController:self])
      self.navigationItem.rightBarButtonItem.enabled = [self.class canPreviewItem:[self.dataSource previewController:self previewItemAtIndex:0]];
  
  } else {
  
    self.navigationItem.rightBarButtonItem.enabled = NO;
  
  }
  
  self.progressView.progress = progress;
  
}

@end





@implementation WASingleFileViewController (QuickLook)

+ (void(^)(WASingleFileViewController *self)) defaultQuickLookFinishLoadHandler {

  return ^ (WASingleFileViewController *self) {
    
    if (!self.navigationController)
      return;
  
    if (self != self.navigationController.topViewController)
      return;
    
    [self reloadData];
    [self refreshCurrentPreviewItem];
    
    self.overlayView.hidden = YES;
    
    self.onFinishLoad = nil;
  
  };

}

- (NSInteger) numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
  
  return 1;

}

- (id <QLPreviewItem>) previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {

  return self.file;

}

@end
