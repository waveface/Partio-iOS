//
//  WADefines+Mac.m
//  wammer
//
//  Created by Evadne Wu on 12/17/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WADefines.h"
#import "WADefines+Mac.h"

#import "WAAppDelegate_Mac.h"


WAAppDelegate * AppDelegate (void) {

	return (WAAppDelegate_Mac *)[UIApplication sharedApplication].delegate;

}
