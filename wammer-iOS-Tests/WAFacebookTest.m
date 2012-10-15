//
//  WAFacebook.m
//  wammer
//
//  Created by jamie on 12/10/15.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFacebookTest.h"

@implementation WAFacebookTest

- (void)setUp {
	_theSwitch = [[WAFacebookConnectionSwitch alloc] init];
}

- (void)tearDown {
	_theSwitch = nil;
}

- (void)testChangeStatusPersistence {
	_theSwitch.on = YES;
	STAssertTrue([[NSUserDefaults standardUserDefaults] boolForKey:kWAFacebookUserDataImport],
							 @"This should be true");
}

@end
