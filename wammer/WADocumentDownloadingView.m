//
//  WADocumentDownloadingView.m
//  wammer
//
//  Created by kchiu on 12/12/13.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WADocumentDownloadingView.h"

@implementation WADocumentDownloadingView

- (id)initWithFrame:(CGRect)frame {

	self = [[NSBundle mainBundle] loadNibNamed:@"WADocumentDownloadingView" owner:self options:nil][0];
	return self;

}

@end
