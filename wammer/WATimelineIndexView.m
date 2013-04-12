//
//  WATimelineIndexView.m
//  wammer
//
//  Created by Shen Steven on 4/6/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WATimelineIndexView.h"

@interface WATimelineIndexLabel : UILabel

- (void) show;
- (void) hide;
@property (nonatomic, readonly) BOOL showing;

@end

@interface WATimelineIndexLabel ()
@property (nonatomic, assign) BOOL showing;
@end

@implementation WATimelineIndexLabel

- (id) initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  
  if (self) {
    self.showing = NO;
    self.alpha = 0.0f;
    self.textAlignment = NSTextAlignmentCenter;
  }
  
  return self;
}

- (void) show {
  if (!self.showing) {
    
    [UIView animateWithDuration:0.4
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionShowHideTransitionViews
                     animations:^{
                       self.alpha = 1.0f;
                     } completion:^(BOOL finished) {
                     }];
    self.showing = YES;
    
  }
}

- (void) hide {
  if (self.showing) {
    [UIView animateWithDuration:1
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionShowHideTransitionViews
                     animations:^{
                       self.alpha = 0.0f;
                     } completion:^(BOOL finished) {
                     }];
    
    self.showing = NO;
  }
}

@end



@interface WATimelineIndexView ()

@property (nonatomic, strong) NSMutableArray *indexics;
@property (nonatomic, strong) NSMutableArray *labels;
@property (nonatomic, strong) UIView *dot;

@end
@implementation WATimelineIndexView

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    // Initialization code
  }
  return self;
}

- (void) awakeFromNib {
    
  self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
  self.layer.cornerRadius = self.frame.size.width/2;
  self.dot = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width/2-4, 10, 8, 8)];
  self.dot.layer.cornerRadius = self.dot.frame.size.width/2;
  self.dot.backgroundColor = [UIColor colorWithWhite:250 alpha:0.8];
  [self addSubview:self.dot];
    
  self.indexics = [NSMutableArray array];
  self.labels = [NSMutableArray array];
}


- (void) addIndex:(CGFloat)index label:(NSString*)label {

  NSInteger i = 0;
  for (NSNumber *value in self.indexics) {
    if (index > [value floatValue]) {
      break;
    }
    i++;
  }
  
  [self.indexics insertObject:[NSNumber numberWithFloat:index] atIndex:i];
  
  WATimelineIndexLabel *newLabel = [[WATimelineIndexLabel alloc] initWithFrame:CGRectMake(-100, 0, 90, 22)];
  newLabel.backgroundColor = [UIColor blackColor];
  newLabel.textColor = [UIColor whiteColor];
  newLabel.textAlignment = NSTextAlignmentCenter;
  newLabel.text = label;
  [newLabel sizeToFit];
  [self addSubview:newLabel];
  CGRect newFrame = newLabel.frame;
  newFrame.origin.x = -10 - newFrame.size.width;
  newLabel.frame = newFrame;
  
  [self.labels insertObject:newLabel atIndex:i];
  
}

- (NSInteger) indexForPercentage:(CGFloat)percentage {

  int i = 0;
  for (NSNumber *index in self.indexics) {
    CGFloat max = [index floatValue] + 0.01;
    CGFloat min = [index floatValue] - 0.005;
    
    if (percentage < max && percentage > min) {
      return i;
    }
    i++;
  }
  
  return NSNotFound;
}

- (void) setPercentage:(CGFloat)percentage {
    
  CGFloat newY = self.frame.size.height * percentage;
  CGRect newRect = CGRectMake(self.frame.size.width/2-4, newY, 8, 8);
  [UIView animateWithDuration:0.2 animations:^{
    self.dot.frame = newRect;
  }];
  
  NSInteger indexInRange = [self indexForPercentage:percentage];
  if (indexInRange != NSNotFound) {
    CGRect frame = ((WATimelineIndexLabel*)self.labels[indexInRange]).frame;
    frame.origin.y = newY - 11;
    ((WATimelineIndexLabel*)self.labels[indexInRange]).frame = frame;
    
    if (!((WATimelineIndexLabel*)self.labels[indexInRange]).showing)
      [((WATimelineIndexLabel*)self.labels[indexInRange]) show];
  }
  
  NSInteger preIndexInRange = [self indexForPercentage:_percentage];
  if (preIndexInRange != NSNotFound && ((WATimelineIndexLabel*)self.labels[preIndexInRange]).showing ) {
    [((WATimelineIndexLabel*)self.labels[preIndexInRange]) hide];
  }
  
  _percentage = percentage;

}



/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
