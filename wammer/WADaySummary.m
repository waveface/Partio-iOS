//
//  WAOneDaySummary.m
//  wammer
//
//  Created by kchiu on 13/1/23.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WADaySummary.h"
#import "WADataStore.h"
#import "WAEventPageView.h"
#import "WASummaryPageView.h"

@implementation WADaySummary

- (id)initWithUser:(WAUser *)user date:(NSDate *)date context:(NSManagedObjectContext *)context {

  self = [super init];
  if (self) {
    NSFetchRequest *request = [[WADataStore defaultStore] newFetchRequestForArticlesOnDate:date];
    self.articles = [context executeFetchRequest:request error:nil];
    
    self.eventPages = [NSMutableArray array];
    if ([self.articles count] == 0) {
      WAEventPageView *eventPageView = [WAEventPageView viewWithRepresentingArticle:nil];
      [self.eventPages addObject:eventPageView];
    }
    for (WAArticle *article in self.articles) {
      WAEventPageView *eventPageView = [WAEventPageView viewWithRepresentingArticle:article];
      [self.eventPages addObject:eventPageView];
    }
    
    self.summaryPage = [WASummaryPageView viewFromNib];
    self.summaryPage.user = user;
    self.summaryPage.date = date;
    self.summaryPage.numberOfEvents = [self.articles count];
  }
  return self;

}

@end
