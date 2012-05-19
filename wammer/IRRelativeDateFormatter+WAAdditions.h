//
//  IRRelativeDateFormatter+WAAdditions.h
//  wammer
//
//  Created by jamie on 5/18/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "IRRelativeDateFormatter.h"

@interface IRRelativeDateFormatter (WAAdditions)

+ (NSArray *) stringRepresentationFormatterStringsforCalendarUnit:(NSCalendarUnit)inCalendarUnit past:(BOOL)inRepresentingDateInThePast;

+ (NSString *) wrappedStringRepresentationForString:(NSString *)inString representedDateTimepoint:(IRDateTimepoint)timePoint;

@end
