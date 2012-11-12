//
//  WAAssetLibraryManagerTests.m
//  wammer
//
//  Created by jamie on 9/4/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAAssetLibraryManagerTests.h"

@implementation WAAssetLibraryManagerTests {
	id mockLibrary;
	WAAssetsLibraryManager *manager;
}

-(void)setUp {
	mockLibrary = [OCMockObject mockForClass:[ALAssetsLibrary class]];
	manager = [WAAssetsLibraryManager defaultManager];
	manager.assetsLibrary = mockLibrary;
}

-(void)tearDown {
	mockLibrary = nil;
}

-(void)testSingleton {
	STAssertEqualObjects(manager, [WAAssetsLibraryManager defaultManager], @"Should be the same one.");
}

-(void)testObtainAnAssetSuccessfully {
	[[[mockLibrary expect]
		andDo:^(NSInvocation *invocation) {
			void (^resultBlock)(ALAsset *asset) = nil;
			[invocation getArgument:&resultBlock atIndex:3];
			resultBlock(nil);
		} ]
	 assetForURL:OCMOCK_ANY
	 resultBlock:OCMOCK_ANY
	 failureBlock:OCMOCK_ANY];
	
	[manager assetForURL:[NSURL URLWithString:@"SomeGoodURL"]
					 resultBlock:^(ALAsset *asset) { STAssertTrue(true, @"successful case"); }
					failureBlock:nil];
	[mockLibrary verify];
}

@end
