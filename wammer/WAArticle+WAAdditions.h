//
//  WAArticle+WAAdditions.h
//  wammer
//
//  Created by Evadne Wu on 2/13/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAArticle.h"


@interface WAArticle (WAAdditions)

- (BOOL) hasMeaningfulContent;

@property (nonatomic, readonly, strong) NSDate *presentationDate;
@property (nonatomic, readonly, strong) NSArray *uniqueCheckins;

@end
