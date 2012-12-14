//
//  WADocumentStreamViewCell.m
//  wammer
//
//  Created by kchiu on 12/12/5.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WADocumentStreamViewCell.h"
#import "Foundation+IRAdditions.h"

NSString * const kWADocumentStreamViewCellID = @"DocumentStreamViewCell";
NSString * kWADocumentStreamViewCellKVOContext = @"DocuementStreamViewCellKVOContext";

@implementation WADocumentStreamViewCell

- (id)initWithFrame:(CGRect)frame {

	self = [[NSBundle mainBundle] loadNibNamed:@"WADocumentStreamViewCell" owner:self options:nil][0];
	self.imageView.clipsToBounds = YES;
	self.imageView.layer.borderColor = [UIColor colorWithWhite:0.95 alpha:1.0].CGColor;
	self.imageView.layer.borderWidth = 1;
	self.eventCardImageView.image = [[self class] eventCardBackgroundImage];

	return self;

}

- (void)dealloc {

	[self.pageElement irRemoveObserverBlocksForKeyPath:@"thumbnailImage"
																						 context:&kWADocumentStreamViewCellKVOContext];
	self.imageView.image = nil;

}

+ (UIImage *) eventCardBackgroundImage {
	
	static UIImage *image = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    image = [[UIImage imageNamed:@"EventCardBG"] resizableImageWithCapInsets:UIEdgeInsetsMake(15, 15, 15, 15)];
	});
	
	return image;
	
}

#pragma mark - UICollectionReusableView delegates

- (void)prepareForReuse {

	[self.pageElement irRemoveObserverBlocksForKeyPath:@"thumbnailImage"
																						 context:&kWADocumentStreamViewCellKVOContext];
	self.imageView.image = nil;

}

@end
