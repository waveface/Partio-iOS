//
//  WAArticleViewController_Plaintext.m
//  wammer
//
//  Created by Evadne Wu on 12/19/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAArticleViewController_Plaintext.h"
#import "WAArticleTextStackCell.h"
#import "WAArticleTextEmphasisLabel.h"
#import "WAArticle.h"

@implementation WAArticleViewController_Plaintext
@synthesize tableView;

- (void) dealloc {

	[tableView release];
	[super dealloc];

}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (!self)
		return nil;
	
	//	?
	
	NSLog(@":D");
	
	return self;

}

- (void) viewDidLoad {

	[super viewDidLoad];
	
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.tableView.backgroundColor = nil;
	
	[self.tableView reloadData];

}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	return 1;

}

- (CGFloat) tableView:(UITableView *)aTV heightForRowAtIndexPath:(NSIndexPath *)indexPath {

	if ((indexPath.section == 0) && (indexPath.row == 0)) {
	
		return 160;
	
	}
	
	return aTV.rowHeight;

}

- (UITableViewCell *) tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	static NSString * const identifier = @"Cell";
	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:identifier];
	
	if (!cell) {
		
		cell = [WAArticleTextStackCell cellFromNib];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
		if ([indexPath isEqual:[NSIndexPath indexPathForRow:0 inSection:0]]) {
		
			WAArticleTextEmphasisLabel *emphasisLabel = [[[WAArticleTextEmphasisLabel alloc] initWithFrame:UIEdgeInsetsInsetRect(cell.bounds, (UIEdgeInsets){
				40, 40, 40, 40
			})] autorelease];
			emphasisLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
			[cell.contentView addSubview:emphasisLabel];
			
			emphasisLabel.text = self.article.text;
			
		}
	
	}
	
	return cell;

}

- (BOOL) tableView:(UITableView *)aTV canStretchRowAtIndexPath:(NSIndexPath *)anIndexPath {

	return NO;

}

@end
