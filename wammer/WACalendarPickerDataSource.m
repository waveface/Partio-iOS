//
//  WACalendarPickerDataSource.m
//  wammer
//
//  Created by Greener Chen on 12/11/23.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WACalendarPickerDataSource.h"
#import "NSDate+WAAdditions.h"

@implementation WACalendarPickerDataSource

+ (WACalendarPickerDataSource *)dataSource
{
	return [[[self class] alloc] init];
}

- (id)init
{
	self = [super init];
	
	if (self) {
		_days = [[NSMutableArray alloc] init];
		_items = [[NSMutableArray alloc] init];
		_events = [[NSMutableArray alloc] init];
	}
	
	return self;
}

#pragma mark - KalDataSource protocol conformance

- (void)presentingDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate delegate:(id<KalDataSourceCallbacks>)delegate
{
	[delegate loadedDataSource:self];	
}

- (NSArray *)markedDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate
{
	return _days;
}

- (void)loadItemsFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
	_items = [NSMutableArray array];
	
	for (WAArticle *event in _events) {
		
		if (isSameDay(event.creationDate, fromDate))
			[_items addObject:event];
	
	}
}

- (void)removeAllItems
{
	[_items removeAllObjects];
}

- (WAArticle *)eventAtIndexPath:(NSIndexPath *)indexPath
{
	return [_items objectAtIndex:indexPath.row];
}

#pragma mark - UITableViewDataSource protocol conformance

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *identifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
	}

	for (UIView *subview in cell.contentView.subviews)
		[subview removeFromSuperview];
		
	if (![_items count]) {
		UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(54, 0, 200, 54)];
		[title setText:NSLocalizedString(@"CALENDAR_NO_EVENT", "Description for no event day in calendar")];
		[title setTextAlignment:NSTextAlignmentCenter];
		[title setFont:[UIFont boldSystemFontOfSize:16.f]];
		[title setTextColor:[UIColor grayColor]];
		[title setBackgroundColor:[UIColor colorWithRed:0.89f green:0.89f blue:0.89f alpha:1.f]];
		[cell.contentView addSubview:title];
		
		[cell setAccessoryView:nil];
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	}
	else {
		WAArticle *event = [self eventAtIndexPath:indexPath];
		// TODO: show thumbnail images in kvo way
		UIImageView *thumbnail = [[UIImageView alloc] initWithImage:event.representingFile.extraSmallThumbnailImage];
		[thumbnail setBackgroundColor:[UIColor grayColor]];
		[thumbnail setBounds:CGRectMake(4, 4, 45, 45)];
		[thumbnail setFrame:CGRectMake(4, 4, 45, 45)];
		[thumbnail setClipsToBounds:YES];
		[cell.contentView addSubview:thumbnail];
		
		UILabel *title = [[UILabel alloc] init];
		title.attributedText = [[self class] attributedDescStringforEvent:event];
		[title setBackgroundColor:[UIColor colorWithRed:0.89f green:0.89f blue:0.89f alpha:1.f]];
		title.numberOfLines = 0;
		[title setFrame:CGRectMake(60, 0, 220, 54)];
		[cell.contentView addSubview:title];
		
		// TODO: determine icon type
		[cell setAccessoryView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"EventCameraIcon"]]];
	}
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (![_items count])
		return 1;
	
	return [_items count];
}

+ (NSAttributedString *)attributedDescStringforEvent:(WAArticle *)event
{
	NSMutableArray *locations = [NSMutableArray array];
	if (event.location != nil && event.location.name != nil) {
		[locations addObject:event.location.name];
	}
	
	NSMutableArray *people = [NSMutableArray array];
	if (event.people != nil) {
		[event.people enumerateObjectsUsingBlock:^(WAPeople *aPersonRep, BOOL *stop) {
			[people addObject:aPersonRep.name];
		}];
	}
		
	UIFont *hlFont = [UIFont fontWithName:@"Georgia-Italic" size:14.0f];
	UIFont *bFont = [UIFont boldSystemFontOfSize:14.f];
	
	NSString *locString = [locations componentsJoinedByString:@","];
	NSString *peoString = [people componentsJoinedByString:@","];
	NSMutableString *rawString = nil;
	
	if (event.eventDescription && event.eventDescription.length) {
		rawString = [NSMutableString stringWithFormat:@"%@", event.eventDescription];
	} else {
		rawString = [NSMutableString string];
	}
	
	if (locations && locations.count) {
		[rawString appendFormat:@"At %@", locString];
	}
	
	if (people && people.count) {
		[rawString appendFormat:@" With %@.", peoString];
	}
		
	NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:rawString];
	
	UIColor *descColor = [UIColor colorWithRed:0.353f green:0.361f blue:0.361f alpha:1.f];
	
	NSDictionary *actionAttr = @{NSForegroundColorAttributeName: descColor, NSFontAttributeName: hlFont};
	NSDictionary *locationAttr = @{NSForegroundColorAttributeName: descColor, NSFontAttributeName: hlFont};
	NSDictionary *peopleAttr = @{NSForegroundColorAttributeName: descColor, NSFontAttributeName: hlFont};
	NSDictionary *othersAttr = @{NSForegroundColorAttributeName: descColor, NSFontAttributeName: bFont};
	
	[attrString setAttributes:othersAttr range:(NSRange)[rawString rangeOfString:rawString]];
	if (event.eventDescription && event.eventDescription.length > 0)
		[attrString setAttributes:actionAttr range:(NSRange){0, event.eventDescription.length}];
	if (locString && locString.length > 0 )
		[attrString setAttributes:locationAttr range:(NSRange)[rawString rangeOfString:locString]];
	if (peoString && peoString.length > 0 )
		[attrString setAttributes:peopleAttr range:(NSRange)[rawString rangeOfString:peoString]];
	
	return attrString;
}

@end