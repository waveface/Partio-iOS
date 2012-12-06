//
//  WACalendarPickerDataSource.h
//  wammer
//
//  Created by Greener Chen on 12/11/23.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WACalendarPickerDataSource.h"
#import <Foundation/Foundation.h>
#import "WADataStore.h"
#import "Kal.h"

@interface WACalendarPickerDataSource : NSObject <UITableViewDataSource, KalDataSource>

@property (nonatomic, strong) NSMutableArray *days;
@property (nonatomic, strong) NSMutableArray *events;
@property (nonatomic, strong)	NSMutableArray *items;
@property (nonatomic, strong) NSMutableArray *files;

+ (WACalendarPickerDataSource *)dataSource;
- (WAArticle *)eventAtIndexPath:(NSIndexPath *)indexPath;
- (void) loadEventsFiles;

@end