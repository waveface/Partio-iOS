//
//  WAUser+WAAdditions.h
//  wammer
//
//  Created by Evadne Wu on 4/19/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAUser.h"

@class WAStorage;

@interface WAUser (WAAdditions)

@property (nonatomic, readonly, retain) WAStorage *mainStorage;

@end
