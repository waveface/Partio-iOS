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
static NSString * const kWALastFBCheckinID = @"kWLastFBCheckinID";
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
      NSString *lastCheckinID = [[NSUserDefaults standardUserDefaults] stringForKey:kWALastFBCheckinID];
      self.fbConnection = [FBRequestConnection
                           startForUserCheckinsAfterId:lastCheckinID
                           completeHandler:^(FBRequestConnection *connection, NSArray *result, NSError *error) {
       
                             if (error) {
                               
                               NSLog(@"fb request error: %@", error);
                               callback(error);
                               [wSelf endPostponingFetch];
                               
                             } else {
         
                               NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
                               NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
                               [numFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
                               NSNumber *lastCheckinIDNumber = @(0);
                               if (lastCheckinID) {
                                 lastCheckinIDNumber = [numFormatter numberFromString:lastCheckinID];
                               }
                               
                               for (NSDictionary *checkinItem in result) {
                               
                                 id checkinIDRep = checkinItem[@"checkin_id"];
                                 NSNumber *checkinID = nil;
                                 if ([checkinIDRep isKindOfClass:[NSString class]])
                                   checkinID = [numFormatter numberFromString:checkinIDRep];
                                 else if ([checkinIDRep isKindOfClass:[NSNumber class]])
                                   checkinID = checkinIDRep;
                                 if ([checkinID compare:lastCheckinIDNumber] == NSOrderedDescending)
                                   lastCheckinIDNumber = checkinID;
                                 
                                 [WACheckin insertOrUpdateObjectsUsingContext:context withRemoteResponse:result usingMapping:nil options:IRManagedObjectOptionIndividualOperations];
           
                               }
                               
                               [[NSUserDefaults standardUserDefaults] setValue:[NSString stringWithFormat:@"%@", lastCheckinIDNumber] forKey:kWALastFBCheckinID];
                               [[NSUserDefaults standardUserDefaults] synchronize];
                               
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
