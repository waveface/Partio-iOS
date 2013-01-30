//
//  WAOneDaySummary.h
//  wammer
//
//  Created by kchiu on 13/1/23.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WAUser, WASummaryPageView;
@interface WADaySummary : NSObject

@property (nonatomic) NSInteger summaryIndex;
@property (nonatomic) NSInteger eventIndex;
@property (nonatomic, strong) NSArray *articles;
@property (nonatomic, strong) WASummaryPageView *summaryPage;
@property (nonatomic, strong) NSMutableArray *eventPages;
@property (nonatomic, weak) UIViewController *delegate;

- (id)initWithUser:(WAUser *)user date:(NSDate *)date context:(NSManagedObjectContext *)context;

@end
