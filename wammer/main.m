//
//  main.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "WAAppDelegate.h"

CFAbsoluteTime StartTime;

int main(int argc, char *argv[]) {
  StartTime = CFAbsoluteTimeGetCurrent();
  @autoreleasepool {
	return UIApplicationMain(argc, argv, nil, NSStringFromClass([WAAppDelegate class]));
  }
}
