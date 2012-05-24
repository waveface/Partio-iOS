//
//  WAPreview+WAAdditions.m
//  wammer
//
//  Created by Evadne Wu on 2/17/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAPreview+WAAdditions.h"
#import "WAOpenGraphElement+WAAdditions.h"
#import "WAOpenGraphElementImage+WAAdditions.h"

@implementation WAPreview (WAAdditions)

+ (NSSet *) keyPathsForValuesAffectingThumbnail {

	return [NSSet setWithObject:@"graphElement.representingImage.image"];

}


- (UIImage *) thumbnail {

	return self.graphElement.representingImage.image;

}

@end
