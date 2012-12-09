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

	return self;

}

- (void)dealloc {

	[self.pageElement irRemoveObserverBlocksForKeyPath:@"thumbnailImage"
																						 context:&kWADocumentStreamViewCellKVOContext];
	self.imageView.image = nil;

}

#pragma mark - UICollectionReusableView delegates

- (void)prepareForReuse {

	[self.pageElement irRemoveObserverBlocksForKeyPath:@"thumbnailImage"
																						 context:&kWADocumentStreamViewCellKVOContext];
	self.imageView.image = nil;

}

@end
