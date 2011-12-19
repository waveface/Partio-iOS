//
//  WAArticleController_PlaintextCell.m
//  wammer
//
//  Created by Evadne Wu on 12/19/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAArticleTextStackCell.h"
#import "WADefines.h"
#import "WAArticle.h"


@interface WAArticleTextStackCell ()
- (void) waInit;
@end

@implementation WAArticleTextStackCell
@synthesize onSizeThatFits;

+ (id) cellFromNib {

	return [[[[UINib nibWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]] instantiateWithOwner:nil options:nil] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
		return [evaluatedObject isKindOfClass:[self class]];
	}]] lastObject];

}

- (void) dealloc {

	[onSizeThatFits release];
	[super dealloc];

}

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {

	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (!self)
		return nil;
	
	[self waInit];
	
	return self;

}

- (void) awakeFromNib {

	[super awakeFromNib];
	
	[self waInit];

}

- (void) waInit {

	self.backgroundView = WAStandardArticleStackCellBackgroundView();

}

- (void) setSelected:(BOOL)selecte animated:(BOOL)animated {

	//	FIXME: move into IRTableViewCell
  //  Default behavior is undesirable

}

- (void) setHighlighted:(BOOL)highlighted animated:(BOOL)animated {

	//	FIXME: move into IRTableViewCell
  //  Default behavior is undesirable

  if (highlighted) {
  
    if (self.backgroundView)
    if (self.selectedBackgroundView) {

      self.selectedBackgroundView.frame = self.bounds;
      [self insertSubview:self.selectedBackgroundView aboveSubview:self.backgroundView];
    
    }
  
  } else {
  
    [self.selectedBackgroundView removeFromSuperview];
  
  }

}

- (CGSize) sizeThatFits:(CGSize)size {

	CGSize superSize = [super sizeThatFits:size];
	
	if (self.onSizeThatFits)
		return self.onSizeThatFits(size, superSize);
	
	return superSize;

}

@end
