//
//  WAPartioTokenFieldCell.m
//  wammer
//
//  Created by Greener Chen on 13/6/4.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WAPartioTokenFieldCell.h"

static const CGFloat kMarginX = 8.f;
static const CGFloat kMarginY = 4.f;
static const CGFloat kMaxWidth = 250.f;

@interface WAPartioTokenFieldCell()

@property (nonatomic, weak) UIButton *buttonView;

@end


@implementation WAPartioTokenFieldCell

- (id)init
{
  self = [super init];
  if (self) {
    // Initialization code
    self.buttonView = [UIButton buttonWithType:UIButtonTypeCustom];
    self.backgroundColor = [UIColor colorWithRed:117/255.f green:193/255.f blue:166/255.f alpha:1.f];
    [self.buttonView setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.buttonView.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.buttonView.titleLabel.font = [UIFont fontWithName:@"OpenSans-Regular" size:16.f];
    [self.buttonView.layer setCornerRadius:14.f];
    [self.buttonView setClipsToBounds:YES];
    
    [self addSubview:self.buttonView];
    
  }
  return self;
}

#pragma mark - properties

- (NSString *)text
{
  return self.buttonView.titleLabel.text;
}

- (void)setText:(NSString *)text
{
  [self.buttonView setTitle:text forState:UIControlStateNormal];
  [self sizeToFit];
}

- (UIFont *)font
{
  return self.buttonView.titleLabel.font;
}

- (void)setFont:(UIFont *)font
{
  self.buttonView.titleLabel.font = font;
}

- (void)setSelected:(BOOL)selected
{
  self.selected = selected;
  self.buttonView.highlighted = selected;
}

#pragma mark - UIView

- (CGSize)sizeToFit
{
  CGSize buttonSize = [self.text sizeWithFont:self.buttonView.titleLabel.font];
  CGFloat width = buttonSize.width + 2*kMarginX;
  self.buttonView.frame = CGRectMake(self.buttonView.frame.origin.x,
                                       self.buttonView.frame.origin.y,
                                       (width > kMaxWidth)? kMaxWidth : width,
                                       buttonSize.height + 2*kMarginY);

  self.frame = self.buttonView.frame;
  return CGSizeMake((width > kMaxWidth)? kMaxWidth : width, buttonSize.height + 2*kMarginY);
}

@end
