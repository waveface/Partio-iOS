//
//  WAArticleDateItem.m
//  wammer
//
//  Created by Evadne Wu on 6/28/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAArticleDateItem.h"

@implementation WAArticleDateItem
@synthesize dateLabel;
@synthesize deviceLabel;

+ (WAArticleDateItem *) instanceFromNib {

	UINib *nib = [UINib nibWithNibName:@"WAArticleDateItem" bundle:nil];
	
	UIView *placeholderView = [[UIView alloc] initWithFrame:CGRectZero];
	WAArticleDateItem *item = [[self alloc] initWithCustomView:placeholderView];
	NSArray *views = [nib instantiateWithOwner:item options:nil];
	item.customView = [views lastObject];
	
	return item;
	
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"article.presentationDate"]) {

		[self.dateLabel setText:[NSDateFormatter localizedStringFromDate:(NSDate *)[change objectForKey:NSKeyValueChangeNewKey] dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterMediumStyle]];

	} else if ([keyPath isEqualToString:@"article.creationDeviceName"]) {

		[self.deviceLabel setText:(NSString *)[change objectForKey:NSKeyValueChangeNewKey]];

	}
}

@end
