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

+ (WAFirstUseViewController *)initWithCompleteBlock:(void (^)(void))completeBlock {

	UIStoryboard *sb = [UIStoryboard storyboardWithName:@"WAFirstUse" bundle:nil];
	WAFirstUseViewController *vc = [sb instantiateInitialViewController];
	vc.completeBlock = completeBlock;
	vc.navigationBar.tintColor = [UIColor colorWithRed:98.0/255.0 green:176.0/255.0 blue:195.0/255.0 alpha:0.0];
	vc.navigationController.navigationBar.opaque = NO;
	

	return vc;

}

@end
