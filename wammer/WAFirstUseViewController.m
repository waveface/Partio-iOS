//
//  WAFirstUseViewController.m
//  wammer
//
//  Created by kchiu on 12/10/24.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFirstUseViewController.h"

@interface WAFirstUseViewController ()

@end

@implementation WAFirstUseViewController

+ (WAFirstUseViewController *)initWithAuthSuccessBlock:(WAFirstUseDidAuthSuccess)authSuccessBlock authFailBlock:(WAFirstUseDidAuthFail)authFailBlock  finishBlock:(WAFirstUseDidFinish)finishBlock {

	UIStoryboard *sb = [UIStoryboard storyboardWithName:@"WAFirstUse" bundle:nil];
	WAFirstUseViewController *vc = [sb instantiateInitialViewController];
	vc.didAuthSuccessBlock = authSuccessBlock;
	vc.didAuthFailBlock = authFailBlock;
	vc.didFinishBlock	= finishBlock;
	vc.navigationBar.opaque = NO;

	return vc;
	
}

- (BOOL) shouldAutorotate {

	if (isPad())
		return YES;
	return NO;

}

- (NSUInteger) supportedInterfaceOrientations {
	
	if (isPad())
		return UIInterfaceOrientationMaskAll;
	return UIInterfaceOrientationMaskPortrait;
	
}

@end
