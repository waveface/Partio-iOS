//
//  WAEventPeopleListViewController.m
//  wammer
//
//  Created by Shen Steven on 12/10/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAEventPeopleListViewController.h"
#import "WAEventPeopleCell.h"
#import "NINetworkImageView.h"
#import "WAPeople.h"

@interface WAEventPeopleListViewController () 

@end

@implementation WAEventPeopleListViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	[self.tableView registerNib:[UINib nibWithNibName:@"WAEventPeopleCell" bundle:nil] forCellReuseIdentifier:@"PersonInfoCell"];
	self.clearsSelectionOnViewWillAppear = NO;
	self.tableView.allowsMultipleSelection = NO;
	self.tableView.allowsSelection = NO;
	self.tableView.backgroundColor = [UIColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:1];
	
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) shouldAutorotate {

	return NO;
	
}

- (NSUInteger) supportedInterfaceOrientations {
	
	return UIInterfaceOrientationMaskPortrait;
	
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	
	return 1;
	
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	
	return self.peopleList.count;

}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	return 66;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	static NSString *CellIdentifier = @"PersonInfoCell";
	WAEventPeopleCell *cell = (WAEventPeopleCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
  	
	WAPeople *aPerson = (WAPeople*)self.peopleList[indexPath.row];

	cell.imageView.image = [UIImage imageNamed:@"TempAvatar"];
	[cell.imageView setPathToNetworkImage:aPerson.avatarURL forDisplaySize:CGSizeMake(56, 56)];
	cell.nameLabel.text = aPerson.name;
	
	return cell;
	
}



@end
