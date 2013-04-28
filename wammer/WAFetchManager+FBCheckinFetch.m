//
//  WAFetchManager+FBCheckinFetch.m
//  wammer
//
//  Created by Shen Steven on 4/27/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAFetchManager+FBCheckinFetch.h"
#import "IRAsyncOperation.h"
#import "WADataStore.h"
#import "WACheckin.h"
#import <FacebookSDK/FacebookSDK.h>
#import <FacebookSDK/FBRequestConnection.h>
#import "FBRequestConnection+WAAdditions.h"

static NSString * const kWAFBRequestConnection = @"kWAFBRequestionConnection";
@implementation WAFetchManager (FBCheckinFetch)

- (FBRequestConnection *)fbConnection {
  return objc_getAssociatedObject(self, &kWAFBRequestConnection);
}

- (void)setFbConnection:(FBRequestConnection*)newConnection {
  objc_setAssociatedObject(self, &kWAFBRequestConnection, newConnection, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (IRAsyncOperation *) fbCheckinFetchPrototype {
  __weak WAFetchManager *wSelf = self;
  IRAsyncOperation *operation = [IRAsyncOperation operationWithWorker:^(IRAsyncOperationCallback callback) {
    
    [wSelf beginPostponingFetch];

    void (^initRequest)(void) = ^{
      self.fbConnection = [FBRequestConnection
                           startForUserCheckinsAfterId:nil
                           completeHandler:^(FBRequestConnection *connection, NSArray *result, NSError *error) {
       
                             if (error) {
                               
                               NSLog(@"fb request error: %@", error);
                               callback(error);
                               [wSelf endPostponingFetch];
                               
                             } else {
                               //                                                          NSLog(@"fb request success: %@", result);
         
                               NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
                               
                               for (NSDictionary *checkinItem in result) {
                                 
                                 
                                 [WACheckin insertOrUpdateObjectsUsingContext:context withRemoteResponse:result usingMapping:nil options:IRManagedObjectOptionIndividualOperations];
           
                               }
                               
                               NSError *error = nil;
                               [context save:&error];
                               if (error) {
                                 NSLog(@"fail to save checkin for %@", error);
                                 callback(error);
                               } else {
                                 callback(nil);
                               }
                               [wSelf endPostponingFetch];
                               
                             }
                           }];
    };
    
    // FBRequestConnection only works in mainthread
    if (![NSThread isMainThread]) {
      dispatch_sync(dispatch_get_main_queue(), initRequest);
    } else {
      initRequest();
    }
  }  trampoline:^(IRAsyncOperationInvoker callback) {
    
//	NSCParameterAssert(![NSThread isMainThread]);
	callback();
	
  } callback:^(id results) {
    
	// NO OP
    
  } callbackTrampoline:^(IRAsyncOperationInvoker callback) {
    
//	NSCParameterAssert(![NSThread isMainThread]);
	callback();
	
  }];

  return operation;
}
@end
