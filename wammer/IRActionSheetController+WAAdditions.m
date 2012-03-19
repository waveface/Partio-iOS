//
//  IRActionSheetController+WAAdditions.m
//  wammer
//
//  Created by jamie on 2/20/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "IRActionSheetController+WAAdditions.h"
#import <objc/runtime.h>


static void __attribute__((constructor)) initialize() {

	@autoreleasepool {

		Class class = [IRActionSheetController class];
		
		method_exchangeImplementations(
			class_getClassMethod(class, @selector(defaultCancelAction)),
			class_getClassMethod(class, @selector(swizzledDefaultCancelAction))
		);
	
	}
	
}


@implementation IRActionSheetController (WAAdditions)

+ (IRAction *) swizzledDefaultCancelAction {

	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
		return [IRAction actionWithTitle:NSLocalizedString(@"ACTION_CANCEL", @"Action title for cancelling stuff") block:nil];
		
	return nil;

}

@end
