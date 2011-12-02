//
//  WAUserInfoHeaderCell.m
//  wammer
//
//  Created by Evadne Wu on 12/2/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//


#import <QuartzCore/QuartzCore.h>
#import "QuartzCore+IRAdditions.h"

#import "WAUserInfoHeaderCell.h"
#import "IRGradientView.h"

@implementation WAUserInfoHeaderCell
@synthesize avatarView;
@synthesize userNameLabel;
@synthesize userEmailLabel;

+ (WAUserInfoHeaderCell *) cellFromNib {

  return [[[[UINib nibWithNibName:NSStringFromClass(self) bundle:[NSBundle bundleForClass:self]] instantiateWithOwner:nil options:nil] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
    return [evaluatedObject isKindOfClass:self];
  }]] lastObject];

}

- (void) awakeFromNib {

  [super awakeFromNib];
  
  self.avatarView.layer.cornerRadius = 4.0f;
  self.avatarView.layer.masksToBounds = YES;
  self.avatarView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.25].CGColor;
  self.avatarView.layer.borderWidth = 2;
  [self.avatarView.superview insertSubview:((^ {
    UIView *returnedView = [[[UIView alloc] initWithFrame:self.avatarView.frame] autorelease];
    returnedView.layer.backgroundColor = [UIColor grayColor].CGColor;
    returnedView.layer.cornerRadius = self.avatarView.layer.cornerRadius;
    returnedView.layer.shadowOpacity = 0.25;
    returnedView.layer.shadowOffset = (CGSize){ 0, 1 };
    returnedView.layer.shadowRadius = 1;
    return returnedView;
  })()) belowSubview:self.avatarView];
  
  self.userNameLabel.shadowColor = [UIColor colorWithWhite:1 alpha:0.95];
  self.userNameLabel.shadowOffset = (CGSize){ 0, 1 }; 
  
  self.userEmailLabel.shadowColor = [UIColor colorWithWhite:1 alpha:0.95];
  self.userEmailLabel.shadowOffset = (CGSize){ 0, 1 }; 
  
  CGRect ownBounds = self.contentView.bounds;
  CGSize ownSize = self.contentView.bounds.size;
  
  self.backgroundView = ((^ {
    
    IRGradientView *returnedView = [[[IRGradientView alloc] initWithFrame:(CGRect){ CGPointZero, ownSize }] autorelease];
    
    IRGradientView *topShadow = [[[IRGradientView alloc] initWithFrame:IRGravitize(ownBounds, (CGSize){ ownSize.width, 3 }, kCAGravityTop)] autorelease];
    [returnedView addSubview:topShadow];
    
    IRGradientView *bottomShadow = [[[IRGradientView alloc] initWithFrame:IRGravitize(ownBounds, (CGSize){ ownSize.width, 2 }, kCAGravityBottom)] autorelease];
    [returnedView addSubview:bottomShadow];
    
    UIView *topGlare = [[[UIView alloc] initWithFrame:IRGravitize(ownBounds, (CGSize){ ownSize.width, 1 }, kCAGravityTop)] autorelease];
    [returnedView addSubview:topGlare];
    
    UIView *bottomGlare = [[[UIView alloc] initWithFrame:IRGravitize(ownBounds, (CGSize){ ownSize.width, 1 }, kCAGravityBottom)] autorelease];
    [returnedView addSubview:bottomGlare];
    
    void (^gradient)(IRGradientView *, UIColor *, UIColor *) = ^ (IRGradientView *aView, UIColor *fromColor, UIColor *toColor) {
      [aView setLinearGradientFromColor:fromColor anchor:irTop toColor:toColor anchor:irBottom];
    };
    
    gradient(returnedView, [UIColor colorWithWhite:.95 alpha:1], [UIColor colorWithWhite:.8 alpha:1]);
    
    topShadow.frame = CGRectOffset(topShadow.frame, 0, -1 * CGRectGetHeight(topShadow.bounds));
    gradient(topShadow, [UIColor colorWithWhite:0 alpha:0], [UIColor colorWithWhite:0 alpha:.125]);
    
    bottomShadow.frame = CGRectOffset(bottomShadow.frame, 0, CGRectGetHeight(bottomShadow.bounds));
    gradient(bottomShadow, [UIColor colorWithWhite:0 alpha:.25], [UIColor colorWithWhite:0 alpha:0]);
    
    topGlare.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
    topGlare.backgroundColor = [UIColor whiteColor];
    
    bottomGlare.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
    bottomGlare.backgroundColor = [UIColor colorWithWhite:0 alpha:0.25];
    
    return returnedView;
    
  })());

}

- (void) dealloc {

  [avatarView release];
  [userNameLabel release];
  [userEmailLabel release];
  [super dealloc];
	
}

@end
