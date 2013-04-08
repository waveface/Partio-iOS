//
//  WAGeoLocation.m
//  wammer
//
//  Created by Shen Steven on 4/5/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAGeoLocation.h"

@interface WAGeoLocation () <NSURLConnectionDelegate>

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, copy) void (^completionBlock) (NSArray *results);
@property (nonatomic, copy) void (^failureBlock) (NSError *error);
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

@end

@implementation WAGeoLocation

+ (NSMutableDictionary*)cachedData {
  
  static NSMutableDictionary *cachedLocation = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    cachedLocation = [NSMutableDictionary dictionary];
  });
  
  return cachedLocation;
}

- (void) identifyLocation:(CLLocationCoordinate2D)coordinate onComplete:(void(^)(NSArray*))completeBlock onError:(void(^)(NSError*))failureBlock {
  
  NSMutableDictionary *cache = [[self class] cachedData];
  NSString *key = [NSString stringWithFormat:@"%.2f/%.2f", coordinate.latitude, coordinate.longitude];
  
  NSDictionary *langMapping = @{@"zh-Hant": @"zh-TW", @"zh-Hans": @"zh-CN"};

  if (cache[key] != nil) {
    if (completeBlock)
      completeBlock(cache[key]);
  } else {

    self.coordinate = coordinate;
    self.completionBlock = completeBlock;
    self.failureBlock = failureBlock;

	NSString *preferedLanguage = @"en";
	NSArray *preferedLanguages = [NSLocale preferredLanguages];
    if ([preferedLanguages count] > 0) {
      if (langMapping[preferedLanguages[0]])
        preferedLanguage = langMapping[preferedLanguages[0]];
    }

    NSString *urlString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/geocode/json?latlng=%f,%f&sensor=true&language=%@", coordinate.latitude, coordinate.longitude, preferedLanguage];
    
    NSURL *requestURL = [NSURL URLWithString:urlString];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:requestURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    if (self.connection) {
      self.responseData = [NSMutableData data];
    }
  }
}

- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response {
  
  [self.responseData setLength:0];

}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data {
  
  [self.responseData appendData:data];

}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error {
  
  if (self.failureBlock)
    self.failureBlock(error);

}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn {
  
  NSError *jsonError          = nil;
  
  NSDictionary *parsedJSON = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingAllowFragments error:&jsonError];

  if (jsonError) {
    if (self.failureBlock) {
      self.failureBlock(jsonError);
      return;
    }
  }
  
  if (!parsedJSON[@"status"] || ![parsedJSON[@"status"] isEqual:@"OK"]) {
    NSLog(@"%@", parsedJSON);
    if (self.failureBlock)
      self.failureBlock([NSError errorWithDomain:@"GoogleResponse" code:-1 userInfo:@{NSLocalizedDescriptionKey: parsedJSON[@"status"]}]);
    return;
  }
  
  if (!parsedJSON[@"results"]) {
    if (self.failureBlock)
      self.failureBlock([NSError errorWithDomain:@"GoogleResponse" code:-2 userInfo:@{NSLocalizedDescriptionKey: @"no results responsed"}]);
    return;
  }
  
  NSArray *results = parsedJSON[@"results"];
  if (!results.count) {
    if (self.failureBlock)
      self.failureBlock([NSError errorWithDomain:@"GoogleResponse" code:-3 userInfo:@{NSLocalizedDescriptionKey: @"empty results"}]);
    return;
  }
  
  if (!results[0][@"address_components"]) {
    if (self.failureBlock)
      self.failureBlock([NSError errorWithDomain:@"GoogleResponse" code:-4 userInfo:@{NSLocalizedDescriptionKey: @"No address components available"}]);
    return;
  }
  
  NSArray *validTypes = @[@"locality", @"administrative_area_level_2", @"administrative_area_level_1", @"country"];
  NSArray *addrComponents = results[0][@"address_components"];
  NSMutableArray *regions = [NSMutableArray array];

  [addrComponents enumerateObjectsUsingBlock:^(NSDictionary *component, NSUInteger idx, BOOL *stop) {
    NSArray *types = component[@"types"];
    __block BOOL match = NO;

    [types enumerateObjectsUsingBlock:^(NSString *value, NSUInteger idx, BOOL *stop2) {
      
      if ([validTypes indexOfObject:value] != NSNotFound) {
        *stop2 = YES;
        match = YES;
      }
      
    }];
    
    if (match) {
      *stop = YES;
      [regions addObject:component[@"long_name"]];
    }
    
  }];
  
  if (self.completionBlock) {
    [[[self class] cachedData] setValue:regions forKey:[NSString stringWithFormat:@"%.2f/%.2f", self.coordinate.latitude, self.coordinate.longitude]];
    
    self.completionBlock([NSArray arrayWithArray:regions]);
  }
}


@end
