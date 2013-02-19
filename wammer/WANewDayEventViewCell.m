//
//  WANewDayEventViewCell.m
//  wammer
//
//  Created by kchiu on 13/2/10.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WANewDayEventViewCell.h"
#import "WANewDayEvent.h"
#import "Foundation+IRAdditions.h"
#import "WANewDayEventImageViewCell.h"

NSString *kWANewDayEventViewCellID = @"NewDayEventViewCell";

@implementation WANewDayEventViewCell

- (void)awakeFromNib {

  [self.imageCollectionView registerNib:[UINib nibWithNibName:@"WANewDayEventImageViewCell" bundle:nil] forCellWithReuseIdentifier:kWANewDayEventImageViewCellID];

}

- (void)setRepresentingDayEvent:(WANewDayEvent *)representingDayEvent {

  NSParameterAssert([NSThread isMainThread]);
  
  _representingDayEvent = representingDayEvent;

  if (_representingDayEvent.style == WADayEventStyleNone) {
    return;
  }

  self.startTimeLabel.text = [[[self class] sharedDateFormatter] stringFromDate:representingDayEvent.startTime];
  self.descriptionLabel.text = representingDayEvent.eventDescription;

  [_representingDayEvent irObserve:@"startTime" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      self.startTimeLabel.text = [[[self class] sharedDateFormatter] stringFromDate:toValue];
    }];
  }];
  
  [_representingDayEvent irObserve:@"eventDescription" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      self.descriptionLabel.text = toValue;
    }];
  }];

}

- (void)dealloc {

  [self.representingDayEvent irRemoveObserverBlocksForKeyPath:@"startTime"];
  [self.representingDayEvent irRemoveObserverBlocksForKeyPath:@"eventDescription"];
  [self.representingDayEvent.images irRemoveAllObserves];
  
}

- (void)prepareForReuse {

  [self.representingDayEvent irRemoveObserverBlocksForKeyPath:@"startTime"];
  [self.representingDayEvent irRemoveObserverBlocksForKeyPath:@"eventDescription"];
  [self.representingDayEvent.images irRemoveAllObserves];

  self.representingDayEvent = nil;

  self.startTimeLabel.text = @"";
  self.descriptionLabel.text = @"";

  [self.imageCollectionView reloadData];

}

+ (NSDateFormatter *)sharedDateFormatter {
  
  static NSDateFormatter *formatter;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"h:mm a"];
  });
  return formatter;
  
}

#pragma mark - UICollectionView DataSource delegates

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

  switch (self.representingDayEvent.style) {
    case WADayEventStyleNone:
      return 1;
    case WADayEventStyleCheckin:
      return 1;
    case WADayEventStyleOnePhoto:
      return 1;
    case WADayEventStyleTwoPhotos:
      return 2;
    case WADayEventStyleThreePhotos:
      return 3;
    case WADayEventStyleFourPhotos:
      return 4;
    default:
      return 0;
  }

}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

  if (self.representingDayEvent.style == WADayEventStyleCheckin) {
    // add map view to cell
    return nil;
  } else {
    WANewDayEventImageViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kWANewDayEventImageViewCellID forIndexPath:indexPath];
    cell.imageView.image = self.representingDayEvent.images[@(indexPath.row)];
    [self.representingDayEvent.images irObserve:[@(indexPath.row) description] options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        cell.imageView.image = toValue;
      }];
    }];
    return cell;
  }

}

@end
