//
//  WAOpenGraphElement+WAAdditions.h
//  wammer
//
//  Created by Evadne Wu on 2/17/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAOpenGraphElement.h"

@interface WAOpenGraphElement (WAAdditions)

@property (nonatomic, readonly, retain) NSString *providerCaption;
//	$providerName ($providerDisplay), $providerName, $providerDisplay, or $providerURL in order of availability

@end
