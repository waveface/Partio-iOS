//
//  WARemoteInterface+Summary.m
//  wammer
//
//  Created by Shen Steven on 2/5/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WARemoteInterface+Summary.h"

@implementation WARemoteInterface (Summary)

- (void) retrieveSummariesSince:(NSDate*)startDate daysOffset:(NSInteger)daysOffset inGroup:(NSString*)anGroupIdentifier onSuccess:(void(^)(NSArray *summaries, BOOL hasMore))successBlock onFailure:(void(^)(NSError *error))failureBlock {

  NSParameterAssert(startDate);
  NSParameterAssert(anGroupIdentifier);
  
  static NSDateFormatter *dateFormatter;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
  });

  float timezoneOffset = [[NSTimeZone systemTimeZone] secondsFromGMT] / 3600.0f;
  NSDictionary *arguments = @{@"start_date":[dateFormatter stringFromDate:startDate],
							  @"offset_days":@(daysOffset),
							  @"group_id":anGroupIdentifier,
							  @"local_time_zone": @(timezoneOffset)};

  [self.engine fireAPIRequestNamed:@"pio_summary/getByPeriod"
					 withArguments:nil
						   options:@{kIRWebAPIEngineRequestContextFormURLEncodingFieldsKey:arguments ,kIRWebAPIEngineRequestHTTPMethod: @"POST"}
						 validator:WARemoteInterfaceGenericNoErrorValidator()
					successHandler:^(NSDictionary *response, IRWebAPIRequestContext *context) {
	
					  NSArray *summaries = response[@"summary"];
					  BOOL hasMore = [response[@"has_more"] boolValue];
    if (successBlock) {
      successBlock(summaries, hasMore);
    }
	
  } failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

  
}
@end
