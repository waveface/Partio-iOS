//
//  WADocumentPreviewController.m
//  wammer
//
//  Created by kchiu on 12/12/13.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WADocumentPreviewController.h"
#import <MKNetworkKit.h>
#import "WARemoteInterface.h"
#import "WADataStore.h"
#import "WAFile+WAConstants.h"
#import "WADocumentDownloadingView.h"
#import "WAGalleryViewController.h"

static NSString * kWADocumentPreviewControllerKVOContext = @"WADocumentPreviewControllerKVOContext";

@interface WADocumentPreviewController ()

@property (nonatomic, strong) WADocumentDownloadingView *downloadingView;
@property (nonatomic, strong) WAFile *file;
@property (nonatomic, strong) MKNetworkOperation *downloadOperation;
@property (nonatomic, strong) UIBarButtonItem *slideShowButton;

@end

@implementation WADocumentPreviewController

- (WADocumentPreviewController *)initWithFile:(WAFile *)file {

	self = [self init];
	if (self) {
		self.file = file;
		self.delegate = self;
		self.dataSource = self;
	}
	return self;

}

- (void)viewDidLoad {

	[super viewDidLoad];

	if (!self.file.resourceFilePath) {

		self.downloadingView = [[WADocumentDownloadingView alloc] init];

		if (self.file.remoteFileSize) {
			NSString *fileSize = [NSByteCountFormatter stringFromByteCount:[self.file.remoteFileSize longLongValue] countStyle:NSByteCountFormatterCountStyleBinary];
			self.downloadingView.downloadTitle.text = [NSString stringWithFormat:@"%@ (%@)", self.file.remoteFileName, fileSize];
		} else {
			self.downloadingView.downloadTitle.text = self.file.remoteFileName;
		}
		self.downloadingView.downloadProgress.progress = 0;

		[self.downloadingView setFrame:self.view.bounds];
		
		[self.view addSubview:self.downloadingView];

	}

	// hide title because file names are often too long to display
	[self.navigationController.navigationBar setTitleTextAttributes:@{
		UITextAttributeTextColor:[UIColor colorWithWhite:0.95 alpha:1.0],
		UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:(UIOffset){0,0}],
		UITextAttributeTextShadowColor:[UIColor colorWithWhite:0.95 alpha:1.0]
	}];

}

- (void)viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];

	[self.view bringSubviewToFront:self.downloadingView];

	NSString *fileExtension = [self.file.remoteFileName pathExtension];
	if ([fileExtension isEqualToString:@"ppt"] || [fileExtension isEqualToString:@"pptx"]) {
		// insert slide show button for powerpoint files
		// however, we cannot insert to right buttons because QLPreviewController will overwrite them with an action button
		if (!self.slideShowButton) {
			self.navigationItem.leftItemsSupplementBackButton = YES;
			self.slideShowButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(handleSlideShow:)];
			self.navigationItem.leftBarButtonItem = self.slideShowButton;
		}
	}

}

- (void)viewDidAppear:(BOOL)animated {

	[super viewDidAppear:animated];

	if (!self.file.resourceFilePath) {

		WARemoteInterface *ri = [WARemoteInterface sharedInterface];
		NSString *host = [ri hasReachableStation] ? [ri.monitoredHosts[1] absoluteString] : [ri.engine.context.baseURL absoluteString];
		NSString *url = [host stringByAppendingPathComponent:@"attachments/view"];
		NSDictionary *parameters = @{
			@"object_id": self.file.identifier,
			@"apikey": ri.apiKey,
			@"session_token": ri.userToken
		};
		MKNetworkOperation *operation = [[MKNetworkOperation alloc] initWithURLString:url params:parameters httpMethod:@"GET"];
		NSString *tempFilePath = [[[[WADataStore defaultStore] oneUseTemporaryFileURL] path] stringByAppendingPathExtension:[self.file.remoteFileName pathExtension]];
		[operation addDownloadStream:[NSOutputStream outputStreamToFileAtPath:tempFilePath append:YES]];

		__weak WADocumentPreviewController *wSelf = self;
		[operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {

			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

				NSManagedObjectContext *context = [[WADataStore defaultStore] autoUpdatingMOC];
				context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
				WAFile *resourceFile = (WAFile *)[context irManagedObjectForURI:[[wSelf.file objectID] URIRepresentation]];
				
				if ([[WADataStore defaultStore] updateObject:resourceFile inContext:context takingBlobFromTemporaryFile:tempFilePath usingResourceType:nil forKeyPath:kWAFileResourceFilePath matchingURL:[NSURL URLWithString:resourceFile.resourceURL] forKeyPath:kWAFileResourceURL]) {
					
					NSError *error = nil;
					if ([context save:&error]) {

						[[NSOperationQueue mainQueue] addOperationWithBlock:^{
							[wSelf.downloadingView removeFromSuperview];
							[wSelf reloadData];
						}];

					} else {

						NSLog(@"Unable to save downloaded file path to database");

					}
					
				} else {
					
					NSLog(@"Unable to save downloaded file");
					
				}

			});

		} errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {

			wSelf.downloadingView.downloadTitle.text = NSLocalizedString(@"DOC_DOWNLOAD_FAIL_TITLE", @"Title of document download");
			wSelf.downloadingView.downloadProgress.hidden = YES;

		}];

		[operation onDownloadProgressChanged:^(double progress) {
			wSelf.downloadingView.downloadProgress.progress = progress;
		}];

		[operation setCacheHandler:^(MKNetworkOperation *completedOperation) {
			// must be implemented for HTTP GET
		}];

		[operation start];

		self.downloadOperation = operation;

	}

}

- (void)dealloc {

	if (self.downloadOperation) {
		[self.downloadOperation cancel];
	}

	self.delegate = nil;
	self.dataSource = nil;

}

#pragma mark - Target actions

- (void)handleSlideShow:(id)sender {

	WAGalleryViewController *galleryVC = [[WAGalleryViewController alloc] initWithImageFiles:[self.file.pageElements array] atIndex:0];

	__weak WAGalleryViewController *wGalleryVC = galleryVC;
	galleryVC.onDismiss = ^ {
		[wGalleryVC dismissViewControllerAnimated:YES completion:nil];
	};
	galleryVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	[self presentViewController:galleryVC animated:YES completion:nil];

}

#pragma mark - QLPreviewController delegates

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {

	return 1;

}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {

	if (self.file.resourceFilePath) {

		// create a hard link so that the controller title will be the original file name (symbolic link not works)
		NSString *hardlink = [[[WADataStore defaultStore] persistentFileURLBasePath] stringByAppendingPathComponent:self.file.remoteFileName];
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSError *error = nil;
		NSDictionary *attributes = [fileManager attributesOfItemAtPath:hardlink error:&error];
		if (attributes) {
			error = nil;
			if (![fileManager removeItemAtPath:hardlink error:&error]) {
				NSLog(@"Unable to remove hard link: %@", error);
			}
		}
		error = nil;
		if ([[NSFileManager defaultManager] linkItemAtPath:self.file.resourceFilePath toPath:hardlink error:&error]) {
			return [NSURL fileURLWithPath:hardlink];
		}
		
		NSLog(@"Unable to create hard link: %@", error);
		return [NSURL fileURLWithPath:self.file.resourceFilePath];

	}
	
	// return non-nil object to avoid strange exceptions
	return [NSURL fileURLWithPath:self.file.remoteFileName];

}

@end
