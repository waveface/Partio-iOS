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

@implementation WADocumentStreamViewCell

- (id)initWithFrame:(CGRect)frame {

	self = [[NSBundle mainBundle] loadNibNamed:@"WADocumentStreamViewCell" owner:self options:nil][0];

	return self;

}

#pragma mark - UICollectionReusableView delegates

- (void)prepareForReuse {

	[self.imageView irUnbind:@"image"];
	self.imageView.image = nil;

}

@end
