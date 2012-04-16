//
//  WADiscretePaginatedArticlesViewController+ReadingProgress.m
//  wammer
//
//  Created by Evadne Wu on 3/26/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WADiscretePaginatedArticlesViewController+ReadingProgress.h"

#import "WARemoteInterface.h"
#import "WAOverlayBezel.h"
#import "WADataStore.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"

#import "Foundation+IRAdditions.h"


NSString * const kLastReadObjectIdentifier = @"WADiscretePaginatedArticlesViewController_lastReadObjectIdentifier";
NSString * const kLastHandledReadObjectIdentifier = @"WADiscretePaginatedArticlesViewController_lastHandledReadObjectIdentifier";
NSString * const kLastReadingProgressAnnotation = @"WADiscretePaginatedArticlesViewController_lastReadingProgressAnnotation";
NSString * const kLastReadingProgressAnnotationView = @"WADiscretePaginatedArticlesViewController_lastReadingProgressAnnotationView";


@interface WADiscretePaginatedArticlesViewController (ReadingProgress_Private)

@property (nonatomic, readwrite, retain) NSString *lastReadObjectIdentifier;
@property (nonatomic, readwrite, retain) NSString *lastHandledReadObjectIdentifier;
@property (nonatomic, readwrite, retain) WAPaginationSliderAnnotation *lastReadingProgressAnnotation;
@property (nonatomic, readwrite, retain) UIView *lastReadingProgressAnnotationView;

@end


@implementation WADiscretePaginatedArticlesViewController (ReadingProgress)

- (NSString *) lastReadObjectIdentifier {

	return [self irAssociatedObjectWithKey:&kLastReadObjectIdentifier];

}

- (void) setLastReadObjectIdentifier:(NSString *)newLastReadObjectIdentifier {

	[self irAssociateObject:newLastReadObjectIdentifier usingKey:&kLastReadObjectIdentifier policy:OBJC_ASSOCIATION_COPY_NONATOMIC changingObservedKey:nil];

	[self updateLastReadingProgressAnnotation];	//	?

}

- (NSString *) lastHandledReadObjectIdentifier {

	return [self irAssociatedObjectWithKey:&kLastHandledReadObjectIdentifier];

}

- (void) setLastHandledReadObjectIdentifier:(NSString *)newLastHandledReadObjectIdentifier {

	[self irAssociateObject:newLastHandledReadObjectIdentifier usingKey:&kLastHandledReadObjectIdentifier policy:OBJC_ASSOCIATION_COPY_NONATOMIC changingObservedKey:nil];

}

- (WAPaginationSliderAnnotation *) lastReadingProgressAnnotation {

	NSUInteger gridIndex = [self gridIndexOfLastReadArticle];
	
	if (gridIndex == NSNotFound) {
		self.lastReadingProgressAnnotationView = nil;	//	Make sure it is niled
		return nil;
	}
	
	if (![self irAssociatedObjectWithKey:&kLastReadingProgressAnnotation])
		self.lastReadingProgressAnnotation = [[WAPaginationSliderAnnotation alloc] init];
	
	WAPaginationSliderAnnotation *annotation = [self irAssociatedObjectWithKey:&kLastReadingProgressAnnotation];
	annotation.pageIndex = gridIndex;
	
	return annotation;

}

- (void) setLastReadingProgressAnnotation:(WAPaginationSliderAnnotation *)newAnnotation {

	[self irAssociateObject:newAnnotation usingKey:&kLastReadingProgressAnnotation policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC changingObservedKey:nil];

}

- (UIView *) lastReadingProgressAnnotationView {
	
	UIView *view = [self irAssociatedObjectWithKey:&kLastReadingProgressAnnotationView];
	if (view)
		return view;
	
	view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"WALastReadIndicator"]];
	[view sizeToFit];
	
	self.lastReadingProgressAnnotationView = view;
	return view;

}

- (void) setLastReadingProgressAnnotationView:(UIView *)newView {

	[self irAssociateObject:newView usingKey:&kLastReadingProgressAnnotationView policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC changingObservedKey:nil];
	
}

- (void) performReadingProgressSync {

	static NSString * const kWADiscretePaginatedArticlesViewController_PerformingReadingProgressSync = @"WADiscretePaginatedArticlesViewController_PerformingReadingProgressSync";

	if (objc_getAssociatedObject(self, &kWADiscretePaginatedArticlesViewController_PerformingReadingProgressSync))
		return;
	
	objc_setAssociatedObject(self, &kWADiscretePaginatedArticlesViewController_PerformingReadingProgressSync, (id)kCFBooleanTrue, OBJC_ASSOCIATION_ASSIGN);

	NSUInteger lastPage = NSNotFound;
	if ([self isViewLoaded])
		lastPage = self.paginatedView.currentPage;
	
	NSString *capturedLastReadObjectID = self.lastReadObjectIdentifier;
	
	[[WARemoteInterface sharedInterface] beginPerformingAutomaticRemoteUpdates];
	
	[self retrieveLatestReadingProgressWithCompletion:^(NSTimeInterval timeTaken) {
	
		[[WARemoteInterface sharedInterface] endPerformingAutomaticRemoteUpdates];
	
		objc_setAssociatedObject(self, &kWADiscretePaginatedArticlesViewController_PerformingReadingProgressSync, nil, OBJC_ASSOCIATION_ASSIGN);
		
		if (![self isViewLoaded])
			return;
		
		if (timeTaken > 3)
			return;
		
		NSInteger currentIndex = [self gridIndexOfLastReadArticle];
		if (currentIndex == NSNotFound)
			return;
		
		if (self.paginatedView.currentPage != lastPage)
			return;
		
		if (![self.lastHandledReadObjectIdentifier isEqualToString:capturedLastReadObjectID]) {
			
			//	Scrolling is annoying
			//	[self.paginatedView scrollToPageAtIndex:currentIndex animated:YES];
			
			self.lastHandledReadObjectIdentifier = self.lastReadObjectIdentifier;
			
		}
			
	}];	

}

- (void) updateLastReadingProgressAnnotation {

	WAPaginationSliderAnnotation *annotation = self.lastReadingProgressAnnotation;
	WAPaginationSlider *slider = self.paginationSlider;
	
	if (annotation) {
	
		if (![slider.annotations containsObject:annotation])
			[self.paginationSlider addAnnotationsObject:annotation];
			
	} else {
	
		[self.paginationSlider removeAnnotations:[NSSet setWithArray:self.paginationSlider.annotations]];
		
	}
	
	[self.paginationSlider setNeedsAnnotationsLayout];
	[self.paginationSlider layoutSubviews];
	[self.paginationSlider setNeedsLayout];

}

//	FIXMEL: Key paths affecting grid index of last read article should be stated

- (NSUInteger) gridIndexOfLastReadArticle {

	__block WAArticle *lastReadArticle = nil;
	
	[[WADataStore defaultStore] fetchArticleWithIdentifier:self.lastReadObjectIdentifier usingContext:self.fetchedResultsController.managedObjectContext onSuccess: ^ (NSString *identifier, WAArticle *article) {
	
		lastReadArticle = article;
		
	}];
	
	if (!lastReadArticle)
		return NSNotFound;
	
	return [self gridIndexOfArticle:lastReadArticle];

}

- (void) updateLatestReadingProgressWithIdentifier:(NSString *)anIdentifier {

	[self updateLatestReadingProgressWithIdentifier:anIdentifier completion:nil];

}

- (void) updateLatestReadingProgressWithIdentifier:(NSString *)anIdentifier completion:(void(^)(BOOL didUpdate))aBlock {

	__weak WADiscretePaginatedArticlesViewController *nrSelf = self;
	__block WAOverlayBezel *nrBezel = nil;
	
	BOOL usesBezel = [[NSUserDefaults standardUserDefaults] boolForKey:kWADebugLastScanSyncBezelsVisible];
	if (usesBezel) {
		nrBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
		nrBezel.caption = @"Set Last Scan";
		[nrBezel showWithAnimation:WAOverlayBezelAnimationFade];
	}
	
	WARemoteInterface *ri = [WARemoteInterface sharedInterface];
	[ri updateLastScannedPostInGroup:ri.primaryGroupIdentifier withPost:anIdentifier onSuccess:^{
		
		dispatch_async(dispatch_get_main_queue(), ^{
		
			nrSelf.lastReadObjectIdentifier = anIdentifier;	//	Heh
			
			if (aBlock)
				aBlock(YES);
			
			if (usesBezel) {
				[nrBezel dismissWithAnimation:WAOverlayBezelAnimationNone];
				nrBezel = [WAOverlayBezel bezelWithStyle:WACheckmarkBezelStyle];
				[nrBezel showWithAnimation:WAOverlayBezelAnimationNone];
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
					[nrBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
				});
			}
			
		});
		
	} onFailure:^(NSError *error) {
	
		dispatch_async(dispatch_get_main_queue(), ^{
			
			if (aBlock)
				aBlock(NO);
			
			if (usesBezel) {
				[nrBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
				nrBezel = [WAOverlayBezel bezelWithStyle:WAErrorBezelStyle];
				nrBezel.caption = @"Can’t Set";
				[nrBezel showWithAnimation:WAOverlayBezelAnimationNone];
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
					[nrBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
				});
			}
		
		});
		
	}];

}
 
- (void) retrieveLatestReadingProgress {

	[self retrieveLatestReadingProgressWithCompletion:nil];

}

- (void) retrieveLatestReadingProgressWithCompletion:(void (^)(NSTimeInterval))aBlock {

	WARemoteInterface *ri = [WARemoteInterface sharedInterface];
	WADataStore *ds = [WADataStore defaultStore];
	
	if (!ri.primaryGroupIdentifier)
			return;

	if ([ri isPostponingDataRetrievalTimerFiring])
		return;

	CFAbsoluteTime operationStart = CFAbsoluteTimeGetCurrent();
	
	[ri beginPostponingDataRetrievalTimerFiring];
				
	void (^cleanup)() = ^ {
	
		NSParameterAssert([NSThread isMainThread]);
		
		if (aBlock)
			aBlock((NSTimeInterval)(CFAbsoluteTimeGetCurrent() - operationStart));
	
		[ri endPostponingDataRetrievalTimerFiring];
		
	};
	
	BOOL usesBezel = [[NSUserDefaults standardUserDefaults] boolForKey:kWADebugLastScanSyncBezelsVisible];
	
	__block WADiscretePaginatedArticlesViewController *nrSelf = self;
	__block WAOverlayBezel *nrBezel = nil;
	
	if (usesBezel) {
		nrBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
		nrBezel.caption = @"Get Last Scan";
		[nrBezel showWithAnimation:WAOverlayBezelAnimationFade];
	}
	
	//	Retrieve the last scanned post in the primary group
	//	Before anything happens at all
	
	[ri retrieveLastScannedPostInGroup:ri.primaryGroupIdentifier onSuccess: ^ (NSString *lastScannedPostIdentifier) {
	
		dispatch_async(dispatch_get_main_queue(), ^{
		
			//	On retrieval completion, set it on the main queue
			//	Then ensure the object exists locally
			
			[ds fetchArticleWithIdentifier:lastScannedPostIdentifier usingContext:self.fetchedResultsController.managedObjectContext onSuccess:^(NSString *identifier, WAArticle *article) {
			
				//	If the object exists locally, go on, things are merry

				if (article) {
					
					nrSelf.lastReadObjectIdentifier = lastScannedPostIdentifier;
					
					if (usesBezel) {
						[nrBezel dismissWithAnimation:WAOverlayBezelAnimationNone];
						nrBezel = [WAOverlayBezel bezelWithStyle:WACheckmarkBezelStyle];
						[nrBezel showWithAnimation:WAOverlayBezelAnimationNone];
						dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
							[nrBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
						});
					}
					
					cleanup();
					return;
					
				}
				
				[nrBezel dismissWithAnimation:WAOverlayBezelAnimationNone];
				nrBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
				nrBezel.caption = @"Loading";
				[nrBezel showWithAnimation:WAOverlayBezelAnimationNone];
				
				//	Otherwise, fetch stuff until things are tidy again
				
				[WAArticle synchronizeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:
					
					kWAArticleSyncFullyFetchOnlyStrategy, kWAArticleSyncStrategy,
					
				nil] completion:^(BOOL didFinish, NSManagedObjectContext *temporalContext, NSArray *prospectiveUnsavedObjects, NSError *anError) {
				
					if (!didFinish) {
						
						dispatch_async(dispatch_get_main_queue(), ^ {

							[nrBezel dismissWithAnimation:WAOverlayBezelAnimationNone];
							
							if (usesBezel) {
								nrBezel = [WAOverlayBezel bezelWithStyle:WAErrorBezelStyle];
								nrBezel.caption = @"Load Failed";
								[nrBezel showWithAnimation:WAOverlayBezelAnimationNone];
								dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
									[nrBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
								});
							}

							cleanup();
							
						});
						
						return;
						
					}
				
					NSError *savingError = nil;
					if (![temporalContext save:&savingError]) {
						NSLog(@"Error saving: %@", savingError);
						NSParameterAssert(NO);
					}
						
					dispatch_async(dispatch_get_main_queue(), ^{

						[nrBezel dismissWithAnimation:WAOverlayBezelAnimationNone];
						
						if (usesBezel) {
							nrBezel = [WAOverlayBezel bezelWithStyle:WACheckmarkBezelStyle];
							[nrBezel showWithAnimation:WAOverlayBezelAnimationNone];
							dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
								[nrBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
							});
						}

						nrSelf.lastReadObjectIdentifier = lastScannedPostIdentifier;
						
						cleanup();
						
					});
					
					return;
					
				}];
				
			}];
		
		});
	
	} onFailure: ^ (NSError *error) {
	
		dispatch_async(dispatch_get_main_queue(), ^{

			[nrBezel dismissWithAnimation:WAOverlayBezelAnimationNone];
			
			if (usesBezel) {
				nrBezel = [WAOverlayBezel bezelWithStyle:WAErrorBezelStyle];
				nrBezel.caption = @"Fetch Failed";
				[nrBezel showWithAnimation:WAOverlayBezelAnimationNone];
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
					[nrBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
				});
			}

			//	?
			
			cleanup();
		
		});
		
	}];

}

@end
