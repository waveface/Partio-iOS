//
//  WAAuthenticationRequestViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/30/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WAAuthenticationRequestViewController.h"
#import "WARemoteInterface.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"

#import "WAOverlayBezel.h"

#import "WADefines.h"

#import "IRAction.h"

#import "UIView+IRAdditions.h"


@interface WAAuthenticationRequestViewController () <UITextFieldDelegate>

@property (nonatomic, readwrite, retain) UITextField *usernameField;
@property (nonatomic, readwrite, retain) UITextField *passwordField;

@property (nonatomic, readwrite, copy) WAAuthenticationRequestViewControllerCallback completionBlock;
@property (nonatomic, readwrite, assign) BOOL validForAuthentication;

- (void) update;

@end


@implementation WAAuthenticationRequestViewController
@synthesize labelWidth;
@synthesize usernameField, passwordField;
@synthesize username, password, completionBlock;
@synthesize performsAuthenticationOnViewDidAppear;
@synthesize actions;
@synthesize validForAuthentication;

+ (WAAuthenticationRequestViewController *) controllerWithCompletion:(WAAuthenticationRequestViewControllerCallback)aBlock {

	WAAuthenticationRequestViewController *returnedVC = [[[self alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
	returnedVC.completionBlock = aBlock;
	return returnedVC;

}

- (id) initWithStyle:(UITableViewStyle)style {

	self = [super initWithStyle:style];
	if (!self)
		return nil;
	
	self.labelWidth = 128.0f;
	self.title = NSLocalizedString(@"WAAuthRequestTitle", @"Title for the auth request controller");
  self.navigationItem.hidesBackButton = YES;
	
	switch (UI_USER_INTERFACE_IDIOM()) {
		
		case UIUserInterfaceIdiomPhone: {
			self.labelWidth = 128.0f;
			break;
		}
		case UIUserInterfaceIdiomPad: {
			self.labelWidth = 192.0f;
			break;
		}
	}
	
	return self;

}

- (void) dealloc {

	[username release];
	[usernameField release];
	
	[password release];
	[passwordField release];
  
  [actions release];

	[super dealloc];

}

- (void) viewDidLoad {

	[super viewDidLoad];
  
  self.tableView.sectionHeaderHeight = 32;
  
	self.usernameField = [[[UITextField alloc] initWithFrame:(CGRect){ 0, 0, 256, 44 }] autorelease];
	self.usernameField.delegate = self;
	self.usernameField.placeholder = NSLocalizedString(@"WANounUsername", @"Noun for Username");
	self.usernameField.text = self.username;
	self.usernameField.font = [UIFont systemFontOfSize:17.0f];
	self.usernameField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	self.usernameField.returnKeyType = UIReturnKeyNext;
	self.usernameField.autocorrectionType = UITextAutocorrectionTypeNo;
	self.usernameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.usernameField.keyboardType = UIKeyboardTypeEmailAddress;
  self.usernameField.clearButtonMode = UITextFieldViewModeWhileEditing;
	
	self.passwordField = [[[UITextField alloc] initWithFrame:(CGRect){ 0, 0, 256, 44 }] autorelease];
	self.passwordField.delegate = self;
	self.passwordField.placeholder = NSLocalizedString(@"WANounPassword", @"Noun for Password");
	self.passwordField.text = self.password;
	self.passwordField.font = [UIFont systemFontOfSize:17.0f];
	self.passwordField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	self.passwordField.returnKeyType = UIReturnKeyGo;
	self.passwordField.autocorrectionType = UITextAutocorrectionTypeNo;
	self.passwordField.secureTextEntry = YES;
	self.passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.passwordField.keyboardType = UIKeyboardTypeASCIICapable;
  self.passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
		
}

- (void) viewDidUnload {

	self.usernameField = nil;
	self.passwordField = nil;
	
	[super viewDidUnload];
	
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {

	if (textField == self.usernameField) {
		BOOL shouldReturn = ![self.usernameField.text isEqualToString:@""];
		if (shouldReturn) {
			dispatch_async(dispatch_get_current_queue(), ^ {
				[self.passwordField becomeFirstResponder];
			});
		}
		return shouldReturn;
	}
		
	if (textField == self.passwordField) {
		BOOL shouldReturn = ![self.passwordField.text isEqualToString:@""];
		if (shouldReturn) {
			dispatch_async(dispatch_get_current_queue(), ^ {
				[self.passwordField resignFirstResponder];
				[self authenticate];
			});
		}
		return shouldReturn; 
		
	}
	
	return NO;

}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

  self.validForAuthentication = ((textField == self.usernameField) ? YES : (BOOL)!![self.usernameField.text length])
    && ((textField == self.passwordField) ? YES : (BOOL)!![self.passwordField.text length])
    && (BOOL)!![[textField.text stringByReplacingCharactersInRange:range withString:string] length];
  
  return YES;
  
}

- (void) textFieldDidEndEditing:(UITextField *)textField {

	[self update];

}

- (void) viewWillAppear:(BOOL)animated {
	
	[super viewWillAppear:animated];
	[self.tableView reloadData];
  	
}

- (void) assignFirstResponderStatusToBestMatchingField {

	if (![self.usernameField.text length]) {
		[self.usernameField becomeFirstResponder];
	} else if (![self.passwordField.text length]) {
		[self.passwordField becomeFirstResponder];
  }

}

- (void) viewDidAppear:(BOOL)animated {

  [super viewDidAppear:animated];
  
  if (self.performsAuthenticationOnViewDidAppear) {
    self.performsAuthenticationOnViewDidAppear = NO;
    [self authenticate];
  }

}

- (void) viewWillDisappear:(BOOL)animated {

  [super viewWillDisappear:animated];
  
  [self.usernameField resignFirstResponder];
  [self.passwordField resignFirstResponder];

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

  switch ([UIDevice currentDevice].userInterfaceIdiom) {
    case UIUserInterfaceIdiomPad:
      return YES;
    default:
      return UIInterfaceOrientationIsPortrait(interfaceOrientation);
  }
  
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {

  return [self.actions count] ? 2 : 1;
  
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	return (section == 0) ? 2 : [self.actions count];
  
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"Cell";

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}
  
  cell.textLabel.textColor = [UIColor blackColor];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;

  if (indexPath.section == 0) {
    
    if (indexPath.row == 0) {
    
      cell.textLabel.text = NSLocalizedString(@"WANounUsername", @"Noun for Username");
      
      if ([self.usernameField isFirstResponder])
      if (![self.usernameField isDescendantOfView:cell]) {
        [self.usernameField resignFirstResponder];
      }
      
      cell.accessoryView = self.usernameField;
      
    } else if (indexPath.row == 1) {
    
      cell.textLabel.text = NSLocalizedString(@"WANounPassword", @"Noun for Password");
      
      if ([self.passwordField isFirstResponder])
      if (![self.passwordField isDescendantOfView:cell]) {
        [self.passwordField resignFirstResponder];        
      }
      
      cell.accessoryView = self.passwordField;
      
    } else {
    
      cell.accessoryView = nil;
    }
  
    cell.textLabel.textAlignment = UITextAlignmentLeft;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
  } else {
  
    IRAction *representedAction = (IRAction *)[self.actions objectAtIndex:indexPath.row];
    cell.textLabel.text = representedAction.title;
    cell.textLabel.textAlignment = UITextAlignmentCenter;
    //  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.accessoryView = nil;
    
    if (representedAction.enabled) {

      cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    
    } else {

      cell.textLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1];
    
    }
  
  }
  
	cell.accessoryView.frame = (CGRect){
		CGPointZero,
		(CGSize){
			CGRectGetWidth(tableView.bounds) - self.labelWidth - ((self.tableView.style == UITableViewStyleGrouped) ? 10.0f : 0.0f),
			45.0f
		}
	};

	return cell;
	
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {

  if (section == 0)
    return tableView.sectionHeaderHeight;
  
  return 12;

}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {

  if (!WAAdvancedFeaturesEnabled())
    return nil;
  
  if (section == 0)
    return [NSString stringWithFormat:@"Using Endpoint %@", [[NSUserDefaults standardUserDefaults] stringForKey:kWARemoteEndpointURL]];
  
  return nil;

}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {

  if (indexPath.section != 1)
    return indexPath;
  
  IRAction *representedAction = (IRAction *)[self.actions objectAtIndex:indexPath.row];
  if (!representedAction.enabled)
    return nil;
  
  return indexPath;

}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

  if (indexPath.section != 1)
    return;

  IRAction *representedAction = (IRAction *)[self.actions objectAtIndex:indexPath.row];
  [representedAction invoke];
  
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

}





- (void) setUsername:(NSString *)newUsername {

  if (username == newUsername)
    return;
  
  [username release];
  username = [newUsername retain];
  
  self.usernameField.text = username;

}

- (void) setPassword:(NSString *)newPassword {

  if (password == newPassword)
    return;
  
  [password release];
  password = [newPassword retain];
  
  self.passwordField.text = password;

}

- (void) update {

	self.username = self.usernameField.text;
	self.password = self.passwordField.text;
  
  self.validForAuthentication = [self.username length] && [self.password length];

}

- (void) authenticate {

  [self update];
  
  if (!self.validForAuthentication)
    return;

	WAOverlayBezel *busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
	busyBezel.caption = NSLocalizedString(@"WAActionProcessing", @"Action title for processing stuff");
	
	[busyBezel showWithAnimation:WAOverlayBezelAnimationFade];
	self.view.userInteractionEnabled = NO;

	[[WARemoteInterface sharedInterface] retrieveTokenForUser:self.username password:self.password onSuccess:^(NSDictionary *userRep, NSString *token) {
		
		[WARemoteInterface sharedInterface].userIdentifier = [userRep objectForKey:@"user_id"];
		[WARemoteInterface sharedInterface].userToken = token;
		
		NSArray *allGroups = [userRep objectForKey:@"groups"];
		if ([allGroups count])
			[WARemoteInterface sharedInterface].primaryGroupIdentifier = [[allGroups objectAtIndex:0] valueForKeyPath:@"group_id"];
		
		dispatch_async(dispatch_get_main_queue(), ^ {
			
			if (self.completionBlock)
				self.completionBlock(self, nil);
			
			self.view.userInteractionEnabled = YES;
			[busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
			
		});

	} onFailure: ^ (NSError *error) {
		
		dispatch_async(dispatch_get_main_queue(), ^ {
		
			if (self.completionBlock)
				self.completionBlock(self, error);
			
			self.view.userInteractionEnabled = YES;
			[busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
			
		});
			
	}];		

}






- (void) setActions:(NSArray *)newActions {

  if (actions == newActions)
    return;
  
  for (IRAction *anAction in actions)
    [anAction removeObserver:self forKeyPath:@"enabled"];
  
  for (IRAction *anAction in newActions)
    [anAction addObserver:self forKeyPath:@"enabled" options:NSKeyValueObservingOptionNew context:nil];
  
  [actions release];
  actions = [newActions retain];

}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

  if ([object isKindOfClass:[IRAction class]])
  if ([self.actions containsObject:object]) {
  
    IRAction *anAction = (IRAction *)object;
    
    if ([self isViewLoaded]) {
      [self.tableView beginUpdates];
      [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:[self.actions indexOfObject:anAction] inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
      [self.tableView endUpdates];
    }
  
  }

}

@end
