//
//  WAFBGraphObjectTableDataSource.h
//  wammer
//
//  Created by Greener Chen on 13/5/16.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <FBGraphObjectTableDataSource.h>

@interface WAFBGraphObjectTableDataSource : FBGraphObjectTableDataSource

@property (nonatomic, retain) NSDictionary *indexMap;

- (NSString *)titleForSection:(NSInteger)sectionIndex;

@end

static NSString *kFrenquentFriendList = @"FrenquentFriendList";
