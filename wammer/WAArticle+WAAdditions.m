//
//  WAArticle+WAAdditions.m
//  wammer
//
//  Created by Evadne Wu on 2/13/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAArticle+WAAdditions.h"

#import "WADataStore.h"

@implementation WAArticle (WAAdditions)

- (WAFile *) representingFile {

	[self willAccessValueForKey:@"representingFile"];
	WAFile *file = [self primitiveValueForKey:@"representingFile"];
	[self didAccessValueForKey:@"representingFile"];
	
	if (!file) {
	
		[self willAccessValueForKey:@"files"];
		
		NSOrderedSet *files = [self primitiveValueForKey:@"files"];
		
		if ([files count]) {
		
			file = [[files array] objectAtIndex:0];
			[self setPrimitiveValue:file forKey:@"representingFile"];
			
		}

		[self didAccessValueForKey:@"files"];
	
	}
	
	return file;

}

- (void) setRepresentingFile:(WAFile *)representingFile {

	[self willChangeValueForKey:@"representingFile"];
	[self setPrimitiveValue:representingFile forKey:@"representingFile"];
	[self didChangeValueForKey:@"representingFile"];

}

+ (NSSet *) keyPathsForValuesAffectingHasMeaningfulContent {

	return [NSSet setWithObjects:
	
		@"files",
		@"previews",
		@"text",
	
	nil];

}

- (BOOL) hasMeaningfulContent {

	if ([self.files count])
		return YES;
		
	if ([[self.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length])
		return YES;

	return NO;

}

+ (BOOL) automaticallyNotifiesObserversForKey:(NSString *)key {

	if ([super automaticallyNotifiesObserversForKey:key])
		return YES;
	
	if ([key isEqualToString:@"text"])
		return YES;
	
	if ([key isEqualToString:@"files"])
		return YES;
	
	return YES;

}

- (NSDate *) presentationDate {

	return self.eventStartDate;

}

- (NSString *)description {
  
  NSMutableString *desc = [@"" mutableCopy];
  if (self.text && self.text.length) {
    [desc appendFormat:@"%@ ", self.text];
  }

  if (self.location && self.location.latitude && self.location.longitude) {
    
    NSMutableArray *allTags = [NSMutableArray array];
    
    for (WALocation *loc in self.checkins) {
      if (loc.name)
        [allTags addObject:loc.name];
    }
    
    if (allTags.count > 0) // dedup
      allTags = [NSMutableArray arrayWithArray:[[NSSet setWithArray:allTags] allObjects]];
    
    for (WATag *aTagRep in self.location.tags) {
      [allTags addObject:aTagRep.tagValue];
    }
    
    if (allTags.count) {
      [desc appendFormat:@"%@ %@ ",
       NSLocalizedString(@"EVENT_DESC_LOCATION_CONJUNCTION", @"The conjunction between description and location."),
       [allTags componentsJoinedByString:@", "]];
    }
  }

  if (self.people) {
    NSMutableArray *people = [NSMutableArray array];
    [self.people enumerateObjectsUsingBlock:^(WAPeople *aPersonRep, BOOL *stop) {
      [people addObject:aPersonRep.name];
    }];
    
    if (people.count) {
      [desc appendFormat:@"%@ %@",
       NSLocalizedString(@"EVENT_DESC_PEOPLE_CONJUNCTION", @"The conjunction between description and people's names"),
       [people componentsJoinedByString:@", "]];
    }
  }
  
  return [NSString stringWithString:desc];

}

@end
