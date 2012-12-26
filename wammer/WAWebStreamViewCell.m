//
//  WAWebStreamViewCell.m
//  wammer
//
//  Created by Shen Steven on 12/17/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAWebStreamViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "IRObservings.h"

NSString * kWAWebStreamViewCellKVOContext = @"DocuementStreamViewCellKVOContext";

@interface WAWebStreamViewCell ()

@property (nonatomic, readwrite, weak) IBOutlet UIImageView *cardBGImageView;

@end

@implementation WAWebStreamViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
			
			
    }
    return self;
}

+ (UIImage *) cardBackgroundImage {
	
	static UIImage *image = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    image = [[UIImage imageNamed:@"EventCardBG"] resizableImageWithCapInsets:UIEdgeInsetsMake(15, 15, 15, 15) resizingMode:UIImageResizingModeTile];
	});
	
	return image;
	
}

- (void) awakeFromNib {
	
	CAGradientLayer *gradient = [CAGradientLayer layer];
	gradient.frame = (CGRect) {CGPointZero, self.frame.size};
	gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithWhite:1.0f alpha:0.0f] CGColor],
										 (id)[[UIColor colorWithWhite:0.9 alpha:0.3f] CGColor],
										 (id)[[UIColor colorWithWhite:0.7 alpha:0.5f] CGColor],
										 (id)[[UIColor colorWithWhite:0 alpha:0.7f] CGColor],
										 (id)[[UIColor colorWithWhite:0 alpha:0.95f] CGColor], nil];
	[self.imageView.layer insertSublayer:gradient atIndex:0];
	
	self.imageView.layer.cornerRadius = 5.0f;
  self.imageView.layer.masksToBounds = YES;
	self.imageView.layer.borderColor = [[UIColor colorWithWhite:0.9 alpha:0.3f] CGColor];
	self.imageView.layer.borderWidth = 1.0f;

	self.cardBGImageView.image = [[self class] cardBackgroundImage];

}

- (void) prepareForReuse {
	
	if (self.file) {
		[self.file irRemoveObserverBlocksForKeyPath:@"thumbnailImage" context:&kWAWebStreamViewCellKVOContext];
	}
	
	self.imageView.image = nil;
	self.sourceImageView.image = nil;
	
}

@end
