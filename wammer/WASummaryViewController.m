//
//  WASummaryViewController.m
//  wammer
//
//  Created by kchiu on 13/1/21.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WASummaryViewController.h"
#import "WADataStore.h"
#import "WAArticle.h"
#import "UIImage+WAAdditions.h"

@interface WASummaryViewController ()

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) WAArticle *article;

@end

@implementation WASummaryViewController

- (id)initWithDate:(NSDate *)date {

  self = [super init];
  if (self) {
    self.date = date;
    self.wantsFullScreenLayout = YES;
  }
  return self;

}

- (void)viewDidLoad {

  self.backgroundImageView.clipsToBounds = YES;

  NSFetchRequest *request = [[WADataStore defaultStore] newFetchRequestForArticlesOnDate:self.date];
  NSManagedObjectContext *context = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
  NSArray *articles = [context executeFetchRequest:request error:nil];
  if ([articles count] > 0) {
    self.article = articles[0];
    __weak WASummaryViewController *wSelf = self;
    [self.article.representingFile irObserve:@"smallThumbnailImage" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
      if (toValue) {
//        CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
//        [blurFilter setValue:@5.0f forKey:@"inputRadius"];
//        wSelf.backgroundImageView.layer.backgroundFilters = @[blurFilter];
//        wSelf.backgroundImageView.image = toValue;
        [toValue makeBlurredImageWithCompleteBlock:^(UIImage *image) {
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
	  wSelf.backgroundImageView.image = image;
	}];
        }];
      }
    }];
  }
  
}

@end
