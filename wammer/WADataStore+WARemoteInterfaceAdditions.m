//
//  WADataStore+WARemoteInterfaceAdditions.m
//  wammer
//
//  Created by Evadne Wu on 11/4/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WADefines.h"
#import "WARemoteInterface.h"

#import "WADataStore+WARemoteInterfaceAdditions.h"
#import "WAOverlayBezel.h"

#import "WAFacebookConnectionSwitch.h"
#import "WAStation.h"
#import <MagicalRecord/MagicalRecord.h>
#import <MagicalRecord/NSManagedObject+MagicalRecord.h>

NSString * const kWADataStoreArticleUpdateShowsBezels = @"WADataStoreArticleUpdateShowsBezels";

@interface WADataStore (WARemoteInterfaceAdditions_Private)

- (NSMutableSet *) articlesCurrentlyBeingUpdated;

@end


@implementation WADataStore (WARemoteInterfaceAdditions)

- (BOOL) hasDraftArticles {
  
  NSManagedObjectContext *context = [self disposableMOC];
  
  NSFetchRequest *fr = [[self managedObjectModel] fetchRequestTemplateForName:@"WAFRArticleDrafts"];
  
  NSError *fetchingError = nil;
  NSArray *fetchedDrafts = [context executeFetchRequest:fr error:&fetchingError];
  
  if (!fetchedDrafts)
    NSLog(@"Error fetching: %@", fetchingError);
  
  return (BOOL)!![fetchedDrafts count];
  
}

- (void) updateArticlesWithCompletion:(void(^)(NSError *))aBlock {
  
  [self updateArticlesOnSuccess: ^ {
    
    if (aBlock)
      aBlock(nil);
    
  } onFailure:aBlock];
  
}

- (void)updateAttachmentsMetaOnSuccess:(void (^)(void))successBlock onFailure:(void (^)(NSError *))failureBlock {
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
    const NSUInteger MAX_UPDATING_FILES_COUNT = 50;
    NSMutableArray *updatingFiles = [@[] mutableCopy];
    
    WADataStore *ds = [WADataStore defaultStore];
    // TODO: need a better way to fetch the latest files needing update meta
    NSArray *files = [ds fetchFilesRequireMetaUpdateUsingContext:[ds disposableMOC]];
    [files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      
      [updatingFiles addObject:[obj identifier]];
      
      if ([updatingFiles count] == MAX_UPDATING_FILES_COUNT || idx == [files count] - 1) {
        
        [[WARemoteInterface sharedInterface] retrieveMetaForAttachments:updatingFiles onSuccess:^(NSArray *attachmentReps, NSArray *successList, NSArray *failureList) {
	
          NSManagedObjectContext *context = [ds autoUpdatingMOC];
          context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
          [WAFile insertOrUpdateObjectsUsingContext:context withRemoteResponse:attachmentReps usingMapping:nil options:IRManagedObjectOptionIndividualOperations];

          if (failureList.count) {
            [WAFile MR_deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"identifier IN %@", failureList] inContext:context];
          }

          [context save:nil];
	
        } onFailure:^(NSError *error) {
	
          NSLog(@"Unable to retrieve attachment metas:%@ error:%@", updatingFiles, error);
	
        }];
        
        [updatingFiles removeAllObjects];
        
      }
      
    }];
    
    successBlock();
    
  });
  
}

- (void) updateArticlesOnSuccess:(void (^)(void))successBlock
		   onFailure:(void (^)(NSError *error))failureBlock {
  
  NSDictionary *defaultOption = @{kWAArticleSyncStrategy: kWAArticleSyncDefaultStrategy};
  
  [WAArticle
   synchronizeWithOptions: defaultOption
   completion:^(BOOL didFinish, NSError *anError) {
     
     if (didFinish) {
       
       if (successBlock)
         successBlock();
       
     } else {
       
       if (failureBlock)
         failureBlock(anError);
       
     }
     
   }];
  
}

- (void) uploadArticle:(NSURL *)anArticleURI withCompletion:(void(^)(NSError *))aBlock {
  
  [self updateArticle:anArticleURI onSuccess:^ {
    
    if (aBlock)
      aBlock(nil);
    
  } onFailure:aBlock];
  
}

- (void) updateArticle:(NSURL *)anArticleURI onSuccess:(void (^)(void))successBlock onFailure:(void (^)(NSError *error))failureBlock {
  
  [self updateArticle:anArticleURI withOptions:nil onSuccess:successBlock onFailure:failureBlock];
  
}

- (void) updateArticle:(NSURL *)anArticleURI withOptions:(NSDictionary *)options onSuccess:(void (^)(void))successBlock onFailure:(void (^)(NSError *error))failureBlock {
  
  NSManagedObjectContext *context = [self disposableMOC];
  WAArticle *article = (WAArticle *)[context irManagedObjectForURI:anArticleURI];
  __weak WADataStore *wSelf = self;

  if ([NSThread isMainThread]) {
	[[self articlesCurrentlyBeingUpdated] addObject:anArticleURI];
  } else {
	dispatch_sync(dispatch_get_main_queue(), ^{
	  [[wSelf articlesCurrentlyBeingUpdated] addObject:anArticleURI];
	});
  }

  void (^fireCallback)(BOOL, NSError *) = ^ (BOOL didFinish, NSError *error) {
    
    if (didFinish) {
      
      if (successBlock)
        successBlock();
      
    } else {
      
      if (failureBlock)
        failureBlock(error);
      
    }
   
	if ([NSThread isMainThread]) {
	  [[wSelf articlesCurrentlyBeingUpdated] addObject:anArticleURI];
	} else {
	  dispatch_sync(dispatch_get_main_queue(), ^{
		[[wSelf articlesCurrentlyBeingUpdated] removeObject:anArticleURI];
	  });
	}
    
  };
  
  void (^handleResult)(BOOL, NSError *) = ^ (BOOL didFinish, NSError *error) {
    
    fireCallback(didFinish, error);
    
  };
  
  [article synchronizeWithCompletion:^(BOOL didFinish, NSError *error) {
    
    handleResult(didFinish, error);
    
  }];
  
}

- (BOOL) isUpdatingArticle:(NSURL *)anObjectURI {
  
  __block BOOL returnedValue = NO;
  dispatch_sync(dispatch_get_main_queue(), ^{
    returnedValue = [[self articlesCurrentlyBeingUpdated] containsObject:anObjectURI];
  });

  return returnedValue;

}

- (void) addComment:(NSString *)commentText onArticle:(NSURL *)anArticleURI onSuccess:(void(^)(void))successBlock onFailure:(void(^)(void))failureBlock {
  
  NSManagedObjectContext *context = [self disposableMOC];
  WAArticle *updatedArticle = (WAArticle *)[context irManagedObjectForURI:anArticleURI];
  
  NSString *postIdentifier = updatedArticle.identifier;
  NSString *groupIdentifier = updatedArticle.group.identifier;
  
  if (!postIdentifier) {
    [NSException raise:NSInternalInconsistencyException format:@"Article %@ has not been saved, and was not assigned a remote identifier.", updatedArticle];
    return;
  }
  
  if (!groupIdentifier) {
    [NSException raise:NSInternalInconsistencyException format:@"Article %@ has not yet been assigned a group.", updatedArticle];
    return;
  }
  
  [[WARemoteInterface sharedInterface] createCommentForPost:postIdentifier inGroup:groupIdentifier withContentText:commentText onSuccess:^(NSDictionary *updatedPostRep) {
    
    [self performBlock:^{
      
      NSManagedObjectContext *context = [self disposableMOC];
      context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
      
      [WAArticle insertOrUpdateObjectsUsingContext:context withRemoteResponse:@[updatedPostRep] usingMapping:nil options:IRManagedObjectOptionIndividualOperations];
      
      NSError *savingError = nil;
      if (![context save:&savingError])
        NSLog(@"Error Saving: %@", savingError);
      
      if (successBlock)
        successBlock();
      
    } waitUntilDone:NO];
    
  } onFailure:^(NSError *error) {
    
    if (failureBlock)
      failureBlock();
    
  }];
  
}

- (void) updateCurrentUserOnSuccess:(void(^)(void))successBlock onFailure:(void(^)(void))failureBlock {
  
  WARemoteInterface *ri = [WARemoteInterface sharedInterface];
  NSString *userIdentifier = ri.userIdentifier;
  if (!userIdentifier) {
    return;
  }
  
  __weak WADataStore *wSelf = self;
  
  [ri retrieveUserAndSNSInfo:userIdentifier onSuccess:^(NSDictionary *userRep, NSArray *snsReps) {
    
    [wSelf performBlock:^{
      
      NSManagedObjectContext *context = [wSelf autoUpdatingMOC];
      context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
      
      WAUser *user = [wSelf mainUserInContext:context];
      if (!user) {
        
        //	Fresh user with “seeding” database.
        
        if (failureBlock)
	failureBlock();
        
        return;
        
      }
      
      // delete uninstalled stations
      for (WAStation *station in user.stations) {
        BOOL found = NO;
        for (NSDictionary *stationRep in userRep[@"stations"]) {
	if ([station.identifier isEqualToString:stationRep[@"station_id"]]) {
	  found = YES;
	  break;
	}
        }
        if (!found) {
	[context deleteObject:station];
        }
      }

      NSArray *touchedUsers = [WAUser insertOrUpdateObjectsUsingContext:context withRemoteResponse:@[userRep] usingMapping:nil options:0];
      
      NSCParameterAssert([touchedUsers count] == 1);
      //			NSCParameterAssert([touchedUsers containsObject:user]);
      
      NSError *savingError = nil;
      if (![context save:&savingError])
        NSLog(@"%@: %@", NSStringFromSelector(_cmd), savingError);
      
      if ([userRep[@"billing"][@"type"] isEqualToString:@"free"]) {
        [[NSUserDefaults standardUserDefaults] setInteger:WABusinessPlanFree forKey:kWABusinessPlan];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kWABackupFilesToCloudEnabled];
        NSNumber *docQuota = userRep[@"quota"][@"doc"][@"origin_size"];
        NSNumber *imageQuota = userRep[@"quota"][@"image"][@"origin_size"];
        [wSelf setStorageQuota:@([docQuota unsignedIntegerValue] + [imageQuota unsignedIntegerValue])];
        NSNumber *docUsage = userRep[@"usage"][@"doc"][@"origin_size"];
        NSNumber *imageUsage = userRep[@"usage"][@"image"][@"origin_size"];
        [wSelf setStorageUsage:@([docUsage unsignedIntegerValue] + [imageUsage unsignedIntegerValue])];
      } else {
        [[NSUserDefaults standardUserDefaults] setInteger:WABusinessPlanUltimate forKey:kWABusinessPlan];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kWABackupFilesToCloudEnabled];
        NSNumber *totalQuota = userRep[@"quota"][@"total"][@"origin_size"];
        NSNumber *totalUsage = userRep[@"usage"][@"total"][@"origin_size"];
        [wSelf setStorageQuota:totalQuota];
        [wSelf setStorageUsage:totalUsage];
      }

      if (snsReps) {
        NSArray *facebookReps = [snsReps filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^ (id evaluatedObject, NSDictionary *bindings) {
	
	return [[evaluatedObject valueForKeyPath:@"type"] isEqual:@"facebook"];
	
        }]];
        
        BOOL importing = NO;
        
        if ([facebookReps count] >= 1) {
	NSDictionary *fbRep = [facebookReps lastObject];
	//	NSString *fbStatus = [fbRep valueForKeyPath:@"status"];
	NSNumber *fbImportingEnabled = [fbRep valueForKeyPath:@"enabled"];
	
	importing = [fbImportingEnabled isEqual:(id)kCFBooleanTrue];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
	[[NSUserDefaults standardUserDefaults] setBool:importing forKey:kWASNSFacebookConnectEnabled];
        });
        
      }
      
      if (successBlock)
        successBlock();
      
    } waitUntilDone:NO];
    
  } onFailure:^(NSError *error) {
    
    NSLog(@"%@: %@", NSStringFromSelector(_cmd), error);
    
    if (failureBlock)
      failureBlock();
    
  }];
  
}

- (void) updateCollectionsOnSuccess: (void (^)(void))successBlock
		      onFailure: (void (^)(NSError *))failureBlock {
  
  WARemoteInterface *remoteInterface = [WARemoteInterface sharedInterface];
  
  __weak WADataStore *weakSelf = self;
  
  [remoteInterface.engine
   fireAPIRequestNamed:@"collections/getAll"
   withArguments:nil
   options:nil
   validator:WARemoteInterfaceGenericNoErrorValidator()
   successHandler:^(NSDictionary *response, IRWebAPIRequestContext *context) {

     // TODO: need a better way to fetch collections without blocking data retrieval
     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

       NSManagedObjectContext *moc = [weakSelf autoUpdatingMOC];
       moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
       NSArray *collections = [WACollection
			 insertOrUpdateObjectsUsingContext:moc
			 withRemoteResponse:[response objectForKey:@"collections"]
			 usingMapping:nil
			 options:IRManagedObjectOptionIndividualOperations
			 ];
       
       NSError *error;
       [moc save:&error];
       if (error)
         NSLog(@"Error on saving collection: %@", error);
       
     });

     successBlock();     

   }
   failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)
   ];
}

@end


@implementation WADataStore (WARemoteInterfaceAdditions_Private)

- (NSMutableSet *) articlesCurrentlyBeingUpdated {
  
  static NSString * const key = @"WADataStore_WARemoteInterfaceAdditions_articlesCurrentlyBeingUploaded";
  
  NSMutableSet *returnedSet = objc_getAssociatedObject(self, &key);
  if (!returnedSet) {
    returnedSet = [NSMutableSet set];
    objc_setAssociatedObject(self, &key, returnedSet, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  
  return returnedSet;
  
}

@end
