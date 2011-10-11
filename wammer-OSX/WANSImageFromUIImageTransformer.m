//
//  WANSImageFromUIImageTransformer.m
//  wammer-OSX
//
//  Created by Evadne Wu on 10/10/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import "WANSImageFromUIImageTransformer.h"

@implementation WANSImageFromUIImageTransformer

+ (void) initialize {

	[NSValueTransformer setValueTransformer:[[[self alloc] init] autorelease] forName:NSStringFromClass([self class])];

}

+ (Class) transformedValueClass {

	return [NSImage class];

}

+ (BOOL) allowsReverseTransformation {

	return YES;

}

- (id)reverseTransformedValue:(id)value {

	if (!value)
		return nil;
	
	if(![value isKindOfClass:[NSImage class]])
		[NSException raise:NSInternalInconsistencyException format:@"Value (%@) is not an NSImage instance", [value class]];
		
	return [[[UIImage alloc] initWithNSImage:value] autorelease];
	
}

- (id) transformedValue:(id)value {

	if (![value isKindOfClass:[UIImage class]])
		return nil;
	
	return [value NSImage];

}

@end
