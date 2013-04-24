//
//  FBRequestConnection+WAAdditions.m
//  wammer
//
//  Created by Shen Steven on 4/6/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "FBRequestConnection+WAAdditions.h"

@implementation FBRequestConnection (WAAdditions)

+ (FBRequestConnection*)startForUserCheckinsAfterId:(NSNumber*)checkinID completeHandler:(FBRequestHandler)completionBlock {
  
  NSString *checkinQueryName = @"checkinQuery";
  NSString *placeQueryName = @"placeQuery";
  NSDictionary *queries = @{
                            checkinQueryName:@"SELECT checkin_id,coords,tagged_uids,page_id,message,timestamp FROM checkin WHERE author_uid = me()",
                            placeQueryName:[NSString stringWithFormat:@"SELECT name,page_id from place WHERE page_id IN (SELECT page_id FROM #%@)", checkinQueryName]
                            };
  
 
  NSString *queryString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:queries options:0 error:nil] encoding:NSUTF8StringEncoding];

  return [FBRequestConnection startWithGraphPath:@"/fql"
                                      parameters:@{@"q":queryString}
                                      HTTPMethod:@"GET"
                               completionHandler:^(FBRequestConnection *connection, NSDictionary *response, NSError *error) {

                                 if (error) {
                                   completionBlock(connection, nil, error);
                                   return;
                                 }
                                 
                                 NSArray *data = response[@"data"];
                                 if (!data) {
                                   completionBlock(connection, nil, [NSError errorWithDomain:@"FBResponse" code:-1 userInfo:nil]);
                                   return;
                                 }
                                 

                                 NSMutableArray *returningList = [NSMutableArray array];
                                 NSArray *checkinList = @[];
                                 NSArray *placeList = @[];
 
                                 for (NSDictionary *results in data) {
                                   NSArray *resultSet = results[@"fql_result_set"];
                                   NSString *queryName = results[@"name"];
                                 
                                   if ([queryName isEqualToString:checkinQueryName]) {
                                     checkinList = [NSMutableArray arrayWithArray:resultSet];
                                   } else if ([queryName isEqualToString:placeQueryName]) {
                                     placeList = [NSArray arrayWithArray:resultSet];
                                   }
                                 }

                                 for (NSDictionary *place in placeList) {
                                   
                                   if (!place[@"page_id"])
                                     continue;
                                   
                                   for (NSDictionary *checkin in checkinList) {
                                     if ([place[@"page_id"] isEqualToNumber:checkin[@"page_id"]]) {
                                       NSMutableDictionary *returningItem = [NSMutableDictionary dictionaryWithDictionary:checkin];
                                       returningItem[@"name"] = place[@"name"];
                                       if (checkin[@"coords"]) {
                                         returningItem[@"latitude"] = checkin[@"coords"][@"latitude"];
                                         returningItem[@"longitude"] = checkin[@"coords"][@"longitude"];
                                       }
                                       [returningList addObject:returningItem];
                                       break;
                                     }
                                   }
                                   
                                 }
                                 
                                 completionBlock(connection, [NSArray arrayWithArray:returningList], nil);
                              }];

}

@end
