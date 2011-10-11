//
//  WAAuthRequestWindowController.m
//  wammer-OSX
//
//  Created by Evadne Wu on 10/10/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import <objc/runtime.h>
#import "WAAuthRequestWindowController.h"

@implementation WAAuthRequestWindowController
@synthesize signInButton;
@synthesize registerButton;
@synthesize usernameField;
@synthesize passwordField;
@synthesize activityIndicator;
@synthesize delegate;

+ (id) sharedController {
	
	static id instance = nil;
	static dispatch_once_t onceToken = 0;
	
	dispatch_once(&onceToken, ^ {
    instance = [[self alloc] init];
	});

	return instance;

}

- (id) init {

	self = [self initWithWindowNibName:@"WAAuthRequestWindow"];
	if (!self)
		return nil;
	
	return self;

}

- (void) windowDidLoad {

	[super windowDidLoad];
	
	[self.usernameField.cell setAllowedInputSourceLocales:[NSArray arrayWithObject:@"en_US"]];
	[self.passwordField.cell setAllowedInputSourceLocales:[NSArray arrayWithObject:@"en_US"]];
	
}

- (BOOL) control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {

	if (sel_isEqual(commandSelector, @selector(insertNewline:))) {
		
		if (control == self.usernameField) {
			[self.window makeFirstResponder:self.passwordField];
			return NO;
		}
		
		if (control == self.passwordField) {
			[self.passwordField stringValue];
			[self.signInButton performClick:nil];
			return YES;
		}
		
	}
	
	return NO;

}

- (IBAction) handleSignIn:(NSButton *)sender {

	[sender setEnabled:NO];
	
	[self.usernameField setEnabled:NO];
	[self.passwordField setEnabled:NO];
	[self.activityIndicator startAnimation:self];
	
	[self.delegate authRequestController:self didRequestAuthenticationForUserName:[self.usernameField stringValue] password:[self.passwordField stringValue] withCallback:^(BOOL wasSuccessful) {
	
		if (wasSuccessful) {
		
			[self.window setAnimationBehavior:NSWindowAnimationBehaviorAlertPanel];
			[self.window orderOut:self];
		
		} else {
		
			[self.usernameField setEnabled:YES];
			[self.passwordField setEnabled:YES];
			[self.activityIndicator stopAnimation:self];
			[sender setEnabled:YES];
		
		}
		
	}];

}

- (IBAction) handleRegister:(NSButton *)sender {

	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://google.com"]];

}

@end
