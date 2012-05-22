//
//  WARegisterRequestViewController+SubclassEyesOnly.h
//  wammer
//
//  Created by Evadne Wu on 5/8/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WARegisterRequestViewController.h"

@interface WARegisterRequestViewController (SubclassEyesOnly)

@property (nonatomic, readwrite, copy) NSString *username;
@property (nonatomic, readwrite, copy) NSString *nickname;
@property (nonatomic, readwrite, copy) NSString *password;
@property (nonatomic, readwrite, copy) NSString *token;
@property (nonatomic, readwrite, copy) NSString *userID;

@end
