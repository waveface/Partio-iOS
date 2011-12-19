//
//  WAArticleViewController_Plaintext.h
//  wammer
//
//  Created by Evadne Wu on 12/19/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAArticleViewController.h"

@interface WAArticleViewController_Plaintext : WAArticleViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, readwrite, retain) IBOutlet UITableView *tableView;

@end
