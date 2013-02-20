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

@interface WANewDayEventViewCell ()

@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@end

@implementation WANewDayEventViewCell

- (void)awakeFromNib {

  [self.imageCollectionView registerNib:[UINib nibWithNibName:@"WANewDayEventImageViewCell" bundle:nil] forCellWithReuseIdentifier:kWANewDayEventImageViewCellID];
  self.imageCollectionView.layer.cornerRadius = 10.0;

  self.gradientLayer = [CAGradientLayer layer];
  self.gradientLayer.frame = (CGRect) {CGPointZero, self.descriptionView.frame.size};
  self.gradientLayer.colors = @[(id)[[UIColor colorWithWhite:0.0 alpha:0.0] CGColor], (id)[[UIColor colorWithWhite:0.0 alpha:0.8] CGColor]];
  self.gradientLayer.cornerRadius = 10.0;

}

- (void)setRepresentingDayEvent:(WANewDayEvent *)representingDayEvent {

  NSParameterAssert([NSThread isMainThread]);
  
  _representingDayEvent = representingDayEvent;

  if (_representingDayEvent.style == WADayEventStyleNone) {
    return;
  }

  [self.descriptionView.layer insertSublayer:self.gradientLayer atIndex:0];

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

  [self.gradientLayer removeFromSuperlayer];

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
    if (self.representingDayEvent.style == WADayEventStyleNone) {
      cell.imageView.contentMode = UIViewContentModeCenter; // Do not show the white edges of WASummaryNoEvent.png
    } else {
      cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
    }
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
