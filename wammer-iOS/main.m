//
//  main.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "WAAppDelegate.h"

int main(int argc, char *argv[])
{
	int retVal = 0;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	retVal = UIApplicationMain(argc, argv, nil, NSStringFromClass([WAAppDelegate class]));
	[pool drain];
	return retVal;
}
